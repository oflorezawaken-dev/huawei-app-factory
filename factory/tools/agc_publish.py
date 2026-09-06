#!/usr/bin/env python3
"""
Huawei App Factory - AppGallery Connect Publishing API client.

Uploads a signed APK/AAB to AppGallery Connect and (optionally) submits the
app for review. Standard library only, so it runs on any GitHub Actions
runner without installing dependencies.

Credentials are read ONLY from environment variables and are never printed:
  AGC_CLIENT_ID      API client ID     (AppGallery Connect > Users and permissions > API client)
  AGC_CLIENT_SECRET  API client secret

Typical use (CI):
  python factory/tools/agc_publish.py \
      --package-name com.huaweiappfactory.receiptlens \
      --file app/build/outputs/apk/release/app-release.apk \
      --release-notes "Initial release" \
      --submit

Flow (AppGallery Connect Publishing API v2):
  1. POST /api/oauth2/v1/token                     -> access_token
  2. GET  /api/publish/v2/appid-list?packageName=  -> appId   (unless --app-id given)
  3. GET  /api/publish/v2/upload-url/for-obs       -> pre-signed OBS PUT url + headers + objectId
  4. PUT  <pre-signed url>                          -> raw file body
  5. PUT  /api/publish/v2/app-file-info?appId=     -> fileType 5 (APK/AAB), fileDestUrl = objectId
  6. (AAB only) GET /api/publish/v2/aab/complile/status  -> poll until compiled
  7. POST /api/publish/v2/app-submit?appId=        -> submit for review (only with --submit)

Limitations imposed by Huawei: the app must already exist in AppGallery
Connect and its content rating must be completed manually in the console.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

# AGC_API_BASE override exists only for local testing against a mock server.
API_BASE = os.environ.get("AGC_API_BASE", "https://connect-api.cloud.huawei.com/api")
TOKEN_URL = f"{API_BASE}/oauth2/v1/token"
PUBLISH_V2 = f"{API_BASE}/publish/v2"

FILE_TYPE_APK_OR_AAB = 5

# aabCompileStatus values observed in the Publishing API
AAB_COMPILING = 1
AAB_COMPILED = 2

RELEASE_NOTES_MIN = 10
RELEASE_NOTES_MAX = 300


class PublishError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(f"[agc-publish] {msg}", flush=True)


def mask_in_ci(value: str) -> None:
    """Ask GitHub Actions to mask a runtime secret (no-op elsewhere)."""
    if os.environ.get("GITHUB_ACTIONS") == "true" and value:
        print(f"::add-mask::{value}", flush=True)


def http_json(method: str, url: str, headers: dict, body: dict | None = None, timeout: int = 120) -> dict:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    for k, v in headers.items():
        req.add_header(k, v)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")[:500]
        raise PublishError(f"{method} {strip_query(url)} -> HTTP {e.code}: {detail}") from None
    except urllib.error.URLError as e:
        raise PublishError(f"{method} {strip_query(url)} -> network error: {e.reason}") from None
    try:
        parsed = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        raise PublishError(f"{method} {strip_query(url)} -> non-JSON response: {raw[:200]}") from None
    ret = parsed.get("ret") or {}
    if ret and ret.get("code", 0) != 0:
        raise PublishError(f"{method} {strip_query(url)} -> API error {ret.get('code')}: {ret.get('msg')}")
    return parsed


def strip_query(url: str) -> str:
    """Log URLs without query strings so appId/remark never leak into logs."""
    return url.split("?", 1)[0]


class AgcClient:
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self._client_secret = client_secret
        self._token: str | None = None

    # 1. token ------------------------------------------------------------
    def authenticate(self) -> None:
        log("Requesting access token")
        resp = http_json(
            "POST",
            TOKEN_URL,
            headers={},
            body={
                "grant_type": "client_credentials",
                "client_id": self.client_id,
                "client_secret": self._client_secret,
            },
        )
        token = resp.get("access_token")
        if not token:
            raise PublishError("Token response did not contain access_token")
        mask_in_ci(token)
        self._token = token
        log(f"Token obtained (expires_in={resp.get('expires_in')}s)")

    def _auth_headers(self) -> dict:
        if not self._token:
            raise PublishError("authenticate() must be called first")
        return {"client_id": self.client_id, "Authorization": f"Bearer {self._token}"}

    # 2. appId from package name -------------------------------------------
    def resolve_app_id(self, package_name: str) -> str:
        log(f"Resolving appId for package {package_name}")
        url = f"{PUBLISH_V2}/appid-list?{urllib.parse.urlencode({'packageName': package_name})}"
        resp = http_json("GET", url, self._auth_headers())
        appids = resp.get("appids") or []
        if not appids:
            raise PublishError(
                f"No AppGallery app found for package {package_name}. "
                "Create the app in AppGallery Connect first (this cannot be done via API)."
            )
        app_id = str(appids[0]["value"])
        log("appId resolved")
        return app_id

    # 3+4. upload -------------------------------------------------------------
    def upload_package(self, app_id: str, file_path: str) -> tuple[str, str, int]:
        size = os.path.getsize(file_path)
        suffix = os.path.splitext(file_path)[1].lstrip(".").lower()
        if suffix not in ("apk", "aab"):
            raise PublishError(f"Unsupported package extension: .{suffix}")
        upload_name = f"release.{suffix}"

        log(f"Requesting upload URL ({upload_name}, {size} bytes)")
        query = urllib.parse.urlencode(
            {"appId": app_id, "fileName": upload_name, "contentLength": size, "suffix": suffix}
        )
        resp = http_json("GET", f"{PUBLISH_V2}/upload-url/for-obs?{query}", self._auth_headers())
        url_info = resp.get("urlInfo") or {}
        put_url = url_info.get("url")
        object_id = url_info.get("objectId")
        put_headers = url_info.get("headers") or {}
        if not put_url or not object_id:
            raise PublishError("upload-url/for-obs did not return urlInfo.url/objectId")

        log("Uploading package to Huawei OBS")
        with open(file_path, "rb") as fh:
            body = fh.read()
        req = urllib.request.Request(put_url, data=body, method=str(url_info.get("method") or "PUT"))
        for k, v in put_headers.items():
            req.add_header(k, v)
        if "Content-Type" not in put_headers:
            req.add_header("Content-Type", "application/octet-stream")
        try:
            with urllib.request.urlopen(req, timeout=900) as resp_put:
                if resp_put.status not in (200, 201, 204):
                    raise PublishError(f"OBS upload returned HTTP {resp_put.status}")
        except urllib.error.HTTPError as e:
            raise PublishError(f"OBS upload failed: HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:300]}") from None
        log("Upload complete")
        return upload_name, object_id, size

    # 5. attach file to app --------------------------------------------------
    def update_app_file_info(self, app_id: str, upload_name: str, object_id: str, size: int) -> list:
        log("Registering package with the app (app-file-info)")
        url = f"{PUBLISH_V2}/app-file-info?{urllib.parse.urlencode({'appId': app_id})}"
        body = {
            "fileType": FILE_TYPE_APK_OR_AAB,
            "files": [{"fileName": upload_name, "fileDestUrl": object_id, "size": str(size)}],
        }
        resp = http_json("PUT", url, self._auth_headers(), body)
        pkg_versions = resp.get("pkgVersion") or []
        log(f"Package registered (pkgVersion count={len(pkg_versions)})")
        return pkg_versions

    # 6. AAB compile status ---------------------------------------------------
    def wait_for_aab_compile(self, app_id: str, pkg_versions: list, timeout_s: int = 1800, interval_s: int = 60) -> None:
        if not pkg_versions:
            log("No pkgVersion returned; skipping AAB compile wait")
            return
        pkg_ids = ",".join(str(p) for p in pkg_versions)
        deadline = time.time() + timeout_s
        while True:
            url = f"{PUBLISH_V2}/aab/complile/status?{urllib.parse.urlencode({'appId': app_id, 'pkgIds': pkg_ids})}"
            resp = http_json("GET", url, self._auth_headers())
            states = resp.get("pkgStateList") or []
            statuses = [s.get("aabCompileStatus") for s in states]
            log(f"AAB compile status: {statuses}")
            if statuses and all(s == AAB_COMPILED for s in statuses):
                return
            if any(s not in (AAB_COMPILING, AAB_COMPILED) for s in statuses):
                raise PublishError(f"AAB compilation failed on Huawei side: {states}")
            if time.time() > deadline:
                raise PublishError("Timed out waiting for AAB compilation")
            time.sleep(interval_s)

    # 7. submit ---------------------------------------------------------------
    def submit_for_review(self, app_id: str, release_notes: str | None) -> None:
        log("Submitting app for review")
        params = {"appId": app_id}
        if release_notes:
            params["remark"] = release_notes
        url = f"{PUBLISH_V2}/app-submit?{urllib.parse.urlencode(params)}"
        http_json("POST", url, self._auth_headers(), body={})
        log("Submitted. Review result will appear in AppGallery Connect.")


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Upload a signed APK/AAB to Huawei AppGallery Connect.")
    target = p.add_mutually_exclusive_group(required=True)
    target.add_argument("--app-id", help="AppGallery Connect app ID")
    target.add_argument("--package-name", help="Android applicationId; appId is resolved via appid-list")
    p.add_argument("--file", required=True, help="Path to the signed .apk or .aab")
    p.add_argument("--submit", action="store_true", help="Submit for review after upload (default: upload only)")
    p.add_argument("--release-notes", help=f"Release notes / remark ({RELEASE_NOTES_MIN}-{RELEASE_NOTES_MAX} chars), used with --submit")
    p.add_argument("--dry-run", action="store_true", help="Validate inputs and print the plan without calling Huawei")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    if not os.path.isfile(args.file):
        log(f"ERROR: file not found: {args.file}")
        return 2
    if args.release_notes is not None and not (RELEASE_NOTES_MIN <= len(args.release_notes) <= RELEASE_NOTES_MAX):
        log(f"ERROR: --release-notes must be {RELEASE_NOTES_MIN}-{RELEASE_NOTES_MAX} characters (got {len(args.release_notes)})")
        return 2
    if args.submit and not args.release_notes:
        log("ERROR: --submit requires --release-notes")
        return 2

    is_aab = args.file.lower().endswith(".aab")
    log(f"Package: {os.path.basename(args.file)} ({os.path.getsize(args.file)} bytes, sha256={sha256_of(args.file)})")
    log(f"Target: {'appId ' + args.app_id if args.app_id else 'package ' + args.package_name}")
    log(f"Mode: {'upload + submit for review' if args.submit else 'upload only (no submission)'}")

    if args.dry_run:
        log("Dry run: no API calls made.")
        return 0

    client_id = os.environ.get("AGC_CLIENT_ID", "")
    client_secret = os.environ.get("AGC_CLIENT_SECRET", "")
    if not client_id or not client_secret:
        log("ERROR: AGC_CLIENT_ID and AGC_CLIENT_SECRET environment variables are required")
        return 2

    try:
        client = AgcClient(client_id, client_secret)
        client.authenticate()
        app_id = args.app_id or client.resolve_app_id(args.package_name)
        upload_name, object_id, size = client.upload_package(app_id, args.file)
        pkg_versions = client.update_app_file_info(app_id, upload_name, object_id, size)
        if is_aab:
            client.wait_for_aab_compile(app_id, pkg_versions)
        if args.submit:
            client.submit_for_review(app_id, args.release_notes)
        else:
            log("Upload registered. Submit manually in AppGallery Connect or re-run with --submit.")
        return 0
    except PublishError as e:
        log(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
