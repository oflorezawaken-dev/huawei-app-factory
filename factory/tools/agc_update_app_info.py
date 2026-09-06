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
    p.add_argument("--set", action="append", required=True, dest="fields", metavar="KEY=VALUE",
                    help="Field to set, e.g. privacyPolicy=https://...")
    p.add_argument("--dry-run", action="store_true")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    body = {}
    for item in args.fields:
        if "=" not in item:
            log(f"ERROR: --set expects KEY=VALUE, got: {item}")
            return 2
        key, value = item.split("=", 1)
        body[key] = coerce(value)

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
