#!/usr/bin/env python3
"""
Huawei App Factory - update top-level app info fields (privacy policy URL,
category, pricing, ...) via the Publishing API's app-info endpoint.

Standard library only. Credentials via environment variables:
  AGC_CLIENT_ID
  AGC_CLIENT_SECRET

Usage:
  python factory/tools/agc_update_app_info.py --app-id 118896647 \
      --set privacyPolicy=https://oflorezawaken-dev.github.io/huawei-app-factory/privacy/

  # multiple fields in one call:
  python factory/tools/agc_update_app_info.py --app-id 118896647 \
      --set privacyPolicy=https://example.com/privacy --set isFree=true

  --dry-run prints the payload without calling Huawei.

Field names and value types must match what AppGallery Connect's app-info
PUT expects (e.g. privacyPolicy is a URL string). Sending an unsupported
field name returns a Huawei API error naming the problem field, not a
guess-based fix.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

API_BASE = os.environ.get("AGC_API_BASE", "https://connect-api.cloud.huawei.com/api")
TOKEN_URL = f"{API_BASE}/oauth2/v1/token"
PUBLISH_V2 = f"{API_BASE}/publish/v2"


class PublishError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(f"[agc-appinfo] {msg}", flush=True)


def mask_in_ci(value: str) -> None:
    if os.environ.get("GITHUB_ACTIONS") == "true" and value:
        print(f"::add-mask::{value}", flush=True)


def http_json(method: str, url: str, headers: dict, body: dict | None = None, timeout: int = 60) -> dict:
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


def coerce(value: str):
    if value.lower() in ("true", "false"):
        return value.lower() == "true"
    return value


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Update AppGallery Connect app-info fields.")
    p.add_argument("--app-id", required=True)
    p.add_argument("--set", action="append", default=[], dest="fields", metavar="KEY=VALUE",
                    help="Field to set, e.g. privacyPolicy=https://...")
    p.add_argument("--set-file", action="append", default=[], dest="field_files",
                    metavar="KEY=PATH",
                    help="Field whose value is read verbatim from a file. Use this for "
                         "values containing commas or quotes, such as privacyLabel.")
    p.add_argument("--from-registry", metavar="SLUG",
                    help="Also send the app-info fields the registry knows: the shared "
                         "distribution country list and this app's category IDs.")
    p.add_argument("--dry-run", action="store_true")
    return p.parse_args(argv)


def registry_fields(slug: str) -> dict:
    """The app-info fields kept in factory/apps.json.

    Countries are shared by every app and live in defaults; the category differs
    per app. Huawei publishes no table mapping category names to these IDs, so
    they were read back from apps configured by hand. parentType is recorded for
    humans but not sent: app-info infers it from childType.
    """
    import json as _json
    here = os.path.dirname(os.path.abspath(__file__))
    registry = _json.load(open(os.path.join(here, "..", "apps.json"), encoding="utf-8"))
    app = next((a for a in registry["apps"] if a["slug"] == slug), None)
    if app is None:
        raise PublishError(f"no app named {slug} in factory/apps.json")

    fields = {}
    countries = (registry["defaults"].get("agc") or {}).get("publish_country")
    if countries:
        fields["publishCountry"] = countries
    category = app.get("agc_category") or {}
    for key in ("childType", "grandChildType"):
        if category.get(key):
            fields[key] = category[key]
    if not category:
        log(f"WARNING: {slug} has no agc_category in the registry; sending countries only")

    # A new app arrives with deviceTypes=[{"deviceType": 4}] and no appAdapters,
    # and app-submit then refuses with 204144660 "The appAdapters is necessary !".
    # Nothing in the console names this field; the value below was read back from
    # the four apps of this account that have been through review, all of which
    # carry the same "4,5,15". Sent for every app so the next one does not
    # rediscover the error at submit time.
    device_types = (registry["defaults"].get("agc") or {}).get("device_types")
    if device_types:
        fields["deviceTypes"] = device_types
    return fields


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    body = {}
    if args.from_registry:
        try:
            body.update(registry_fields(args.from_registry))
        except PublishError as exc:
            log(f"ERROR: {exc}")
            return 2
    for item in args.fields:
        if "=" not in item:
            log(f"ERROR: --set expects KEY=VALUE, got: {item}")
            return 2
        key, value = item.split("=", 1)
        body[key] = coerce(value)

    for item in args.field_files:
        if "=" not in item:
            log(f"ERROR: --set-file expects KEY=PATH, got: {item}")
            return 2
        key, path = item.split("=", 1)
        try:
            body[key] = open(path, encoding="utf-8").read().strip()
        except OSError as exc:
            log(f"ERROR: cannot read {path}: {exc}")
            return 2

    log(f"appId={args.app_id} fields={body}")
    if args.dry_run:
        log("Dry run: no API calls made.")
        return 0

    client_id = os.environ.get("AGC_CLIENT_ID", "")
    client_secret = os.environ.get("AGC_CLIENT_SECRET", "")
    if not client_id or not client_secret:
        log("ERROR: AGC_CLIENT_ID and AGC_CLIENT_SECRET environment variables are required")
        return 2

    try:
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

        url = f"{PUBLISH_V2}/app-info?{urllib.parse.urlencode({'appId': args.app_id})}"
        headers = {"client_id": client_id, "Authorization": f"Bearer {token}"}
        http_json("PUT", url, headers, body)
        log("Saved.")
        return 0
    except PublishError as e:
        log(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
