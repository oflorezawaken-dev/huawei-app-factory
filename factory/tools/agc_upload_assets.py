#!/usr/bin/env python3
"""
Huawei App Factory - upload visual assets (app icon, screenshots) to
AppGallery Connect via the Publishing API. Same OBS upload flow as
agc_publish.py, different fileType and, for screenshots, a target language.

Standard library only. Credentials via environment variables:
  AGC_CLIENT_ID
  AGC_CLIENT_SECRET

fileType values (Huawei Publishing API):
  0 = app icon (one file, no language)
  2 = phone screenshot (one or more files, must specify --lang)

Usage:
  # app icon (once, no --lang)
  python factory/tools/agc_upload_assets.py --app-id 118896647 \
      --file-type icon --file apps/receipt-lens/store/icon/icon-512.png

  # screenshots for one language (all files in one call)
  python factory/tools/agc_upload_assets.py --app-id 118896647 \
      --file-type screenshot --lang en-US \
      --file apps/receipt-lens/store/screenshots/en/01_home.png \
      --file apps/receipt-lens/store/screenshots/en/02_receipt_detail.png \
      ...

  # see the plan without calling Huawei
  ... --dry-run
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

API_BASE = os.environ.get("AGC_API_BASE", "https://connect-api.cloud.huawei.com/api")
TOKEN_URL = f"{API_BASE}/oauth2/v1/token"
PUBLISH_V2 = f"{API_BASE}/publish/v2"

FILE_TYPES = {"icon": 0, "screenshot": 2}


class PublishError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(f"[agc-assets] {msg}", flush=True)


def mask_in_ci(value: str) -> None:
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
        raise PublishError(f"{method} {url.split('?')[0]} -> HTTP {e.code}: {detail}") from None
    except urllib.error.URLError as e:
        raise PublishError(f"{method} {url.split('?')[0]} -> network error: {e.reason}") from None
    parsed = json.loads(raw) if raw else {}
    ret = parsed.get("ret") or {}
    if ret and ret.get("code", 0) != 0:
        raise PublishError(f"{method} {url.split('?')[0]} -> API error {ret.get('code')}: {ret.get('msg')}")
    return parsed


def authenticate(client_id: str, client_secret: str) -> str:
    log("Requesting access token")
    resp = http_json("POST", TOKEN_URL, {}, {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
    })
    token = resp.get("access_token")
    if not token:
        raise PublishError("Token response did not contain access_token")
    mask_in_ci(token)
    return token


def upload_one(app_id: str, client_id: str, token: str, path: str) -> dict:
    size = os.path.getsize(path)
    suffix = os.path.splitext(path)[1].lstrip(".").lower()
    filename = os.path.basename(path)
    log(f"Requesting upload URL for {filename} ({size} bytes)")
    query = urllib.parse.urlencode({"appId": app_id, "fileName": filename, "contentLength": size, "suffix": suffix})
    resp = http_json("GET", f"{PUBLISH_V2}/upload-url/for-obs?{query}", {"client_id": client_id, "Authorization": f"Bearer {token}"})
    url_info = resp.get("urlInfo") or {}
    put_url = url_info.get("url")
    object_id = url_info.get("objectId")
    put_headers = url_info.get("headers") or {}
    if not put_url or not object_id:
        raise PublishError(f"upload-url/for-obs did not return urlInfo.url/objectId for {filename}")

    log(f"Uploading {filename} to Huawei OBS")
    with open(path, "rb") as fh:
        body = fh.read()
    req = urllib.request.Request(put_url, data=body, method=str(url_info.get("method") or "PUT"))
    for k, v in put_headers.items():
        req.add_header(k, v)
    if "Content-Type" not in put_headers:
        req.add_header("Content-Type", "application/octet-stream")
    try:
        with urllib.request.urlopen(req, timeout=300) as resp_put:
            if resp_put.status not in (200, 201, 204):
                raise PublishError(f"OBS upload returned HTTP {resp_put.status} for {filename}")
    except urllib.error.HTTPError as e:
        raise PublishError(f"OBS upload failed for {filename}: HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:300]}") from None

    return {"fileName": filename, "fileDestUrl": object_id, "size": str(size)}


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Upload an app icon or screenshots to AppGallery Connect.")
    p.add_argument("--app-id", required=True)
    p.add_argument("--file-type", required=True, choices=sorted(FILE_TYPES), help="icon or screenshot")
    p.add_argument("--lang", help="Required for --file-type screenshot (e.g. en-US)")
    p.add_argument("--file", action="append", required=True, dest="files", help="Path to a file; repeat for multiple screenshots")
    p.add_argument("--dry-run", action="store_true")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    if args.file_type == "screenshot" and not args.lang:
        log("ERROR: --lang is required with --file-type screenshot")
        return 2
    if args.file_type == "icon" and len(args.files) != 1:
        log("ERROR: --file-type icon takes exactly one --file")
        return 2

    for f in args.files:
        if not os.path.isfile(f):
            log(f"ERROR: file not found: {f}")
            return 2

    file_type_code = FILE_TYPES[args.file_type]
    log(f"Target: appId={args.app_id} fileType={args.file_type} ({file_type_code})" + (f" lang={args.lang}" if args.lang else ""))
    for f in args.files:
        log(f"  file: {f} ({os.path.getsize(f)} bytes, sha256={sha256_of(f)[:16]}...)")

    if args.dry_run:
        log("Dry run: no API calls made.")
        return 0

    client_id = os.environ.get("AGC_CLIENT_ID", "")
    client_secret = os.environ.get("AGC_CLIENT_SECRET", "")
    if not client_id or not client_secret:
        log("ERROR: AGC_CLIENT_ID and AGC_CLIENT_SECRET environment variables are required")
        return 2

    try:
        token = authenticate(client_id, client_secret)
        uploaded = [upload_one(args.app_id, client_id, token, f) for f in args.files]

        log("Registering files with the app (app-file-info)")
        payload = {"fileType": file_type_code, "files": uploaded}
        if args.lang:
            payload["lang"] = args.lang
        url = f"{PUBLISH_V2}/app-file-info?{urllib.parse.urlencode({'appId': args.app_id})}"
        http_json("PUT", url, {"client_id": client_id, "Authorization": f"Bearer {token}"}, payload)
        log(f"Done: {len(uploaded)} file(s) registered as {args.file_type}.")
        return 0
    except PublishError as e:
        log(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
