#!/usr/bin/env python3
"""
Huawei App Factory - push store listing text (app name, short/full
description, release notes) to AppGallery Connect for one or more
languages, using the Publishing API's app-language-info endpoint.

Standard library only. Credentials via environment variables, same as
agc_publish.py:
  AGC_CLIENT_ID
  AGC_CLIENT_SECRET

Usage:
  python factory/tools/agc_update_listing.py --app-id 118896647 \
      --listing apps/receipt-lens/store/listing.json --lang en-US

  # push every language in the file:
  python factory/tools/agc_update_listing.py --app-id 118896647 \
      --listing apps/receipt-lens/store/listing.json --all

  # see what would be sent without calling Huawei:
  ... --dry-run

listing.json shape:
  {"languages": [{"lang": "en-US", "appName": "...", "briefInfo": "...",
                   "appDesc": "...", "newFeatures": "..."}, ...]}
Only lang is required; any of appName/briefInfo/appDesc/newFeatures may be
omitted to leave that field untouched in the console.
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

FIELD_MAP = {
    "appName": "appName",
    "briefInfo": "briefInfo",
    "appDesc": "appDesc",
    "newFeatures": "newFeatures",
}


class PublishError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(f"[agc-listing] {msg}", flush=True)


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


def push_language(app_id: str, client_id: str, token: str, entry: dict, dry_run: bool) -> None:
    lang = entry.get("lang")
    if not lang:
        raise PublishError(f"Listing entry missing 'lang': {entry}")
    body = {"lang": lang}
    for src_key, api_key in FIELD_MAP.items():
        if entry.get(src_key):
            body[api_key] = entry[src_key]

    log(f"{lang}: fields={sorted(k for k in body if k != 'lang')}")
    if dry_run:
        return

    url = f"{PUBLISH_V2}/app-language-info?{urllib.parse.urlencode({'appId': app_id})}"
    headers = {"client_id": client_id, "Authorization": f"Bearer {token}"}
    http_json("PUT", url, headers, body)
    log(f"{lang}: saved")


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Push ReceiptLens store listing text to AppGallery Connect.")
    p.add_argument("--app-id", required=True, help="AppGallery Connect App ID")
    p.add_argument("--listing", required=True, help="Path to listing.json")
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--lang", help="Push only this language code (e.g. en-US)")
    group.add_argument("--all", action="store_true", help="Push every language in the file")
    p.add_argument("--dry-run", action="store_true", help="Print what would be sent without calling Huawei")
    return p.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    if not os.path.isfile(args.listing):
        log(f"ERROR: listing file not found: {args.listing}")
        return 2

    with open(args.listing, encoding="utf-8") as fh:
        data = json.load(fh)
    languages = data.get("languages") or []
    if not languages:
        log("ERROR: listing file has no 'languages' entries")
        return 2

    if args.lang:
        languages = [e for e in languages if e.get("lang") == args.lang]
        if not languages:
            log(f"ERROR: no entry for lang {args.lang} in {args.listing}")
            return 2

    if args.dry_run:
        for entry in languages:
            push_language(args.app_id, "", "", entry, dry_run=True)
        log("Dry run: no API calls made.")
        return 0

    client_id = os.environ.get("AGC_CLIENT_ID", "")
    client_secret = os.environ.get("AGC_CLIENT_SECRET", "")
    if not client_id or not client_secret:
        log("ERROR: AGC_CLIENT_ID and AGC_CLIENT_SECRET environment variables are required")
        return 2

    try:
        token = authenticate(client_id, client_secret)
        failures = []
        for entry in languages:
            try:
                push_language(args.app_id, client_id, token, entry, dry_run=False)
            except PublishError as e:
                log(f"ERROR on {entry.get('lang')}: {e}")
                failures.append(entry.get("lang"))
        if failures:
            log(f"Completed with failures: {failures}")
            return 1
        log("All languages pushed successfully.")
        return 0
    except PublishError as e:
        log(f"ERROR: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
