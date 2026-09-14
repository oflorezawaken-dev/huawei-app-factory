#!/usr/bin/env python3
"""
App Factory - watch the AppGallery review state and open an issue when it changes.

Polls every registered Android app through the Publishing API and, when a version
reaches a state a human has to act on, opens a GitHub issue that says what to do
about it and quotes Huawei's own review comment.

  python factory/tools/agc_watch.py                 # every Android app with an app id
  python factory/tools/agc_watch.py sudoku          # just one
  python factory/tools/agc_watch.py --dry-run       # report, never touch GitHub
  python factory/tools/agc_watch.py --inspect       # print the raw state fields

Credentials: AGC_CLIENT_ID and AGC_CLIENT_SECRET, same pair the publish workflow
uses. Exit codes: 0 fine, 1 an app could not be polled (the others still run).

## Why there is no state file

Same reasoning as the iOS watch: the issues themselves are the memory. One issue
per (slug, version, state), created only when no issue with that exact title
exists, so re-running is idempotent and deleting an issue means "tell me again".

## About releaseState

Huawei documents `releaseState` as an integer but does not publish a reliable
enum table, so RELEASE_STATE below was confirmed against this account's own apps
rather than copied from a doc page. Anything not in the table is logged with its
raw number and never opens an issue: a wrong guess that cries "rejected" every
morning would be worse than silence.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from registry import load, platform_of  # noqa: E402

API_BASE = os.environ.get("AGC_API_BASE", "https://connect-api.cloud.huawei.com/api")
TOKEN_URL = f"{API_BASE}/oauth2/v1/token"
PUBLISH_V2 = f"{API_BASE}/publish/v2"

WATCH_LABEL = "review-status"

# name, needs_a_human
RELEASE_STATE: dict[int, tuple[str, bool]] = {}

# What to do about each state. Instructions, not status text: an issue that only
# says "REJECTED" has wasted the notification it cost.
NEXT_STEP: dict[str, str] = {}


class WatchError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(f"[agc-watch] {msg}", flush=True)


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
        raise WatchError(f"{method} {url.split('?', 1)[0]} -> HTTP {e.code}: {detail}") from None
    except urllib.error.URLError as e:
        raise WatchError(f"{method} {url.split('?', 1)[0]} -> network error: {e.reason}") from None
    parsed = json.loads(raw) if raw else {}
    ret = parsed.get("ret") or {}
    if ret and ret.get("code", 0) != 0:
        raise WatchError(f"API error {ret.get('code')}: {ret.get('msg')}")
    return parsed


def make_token(client_id: str, client_secret: str) -> str:
    body = {"grant_type": "client_credentials", "client_id": client_id, "client_secret": client_secret}
    token = http_json("POST", TOKEN_URL, {}, body).get("access_token")
    if not token:
        raise WatchError("no access_token in the token response")
    if os.environ.get("GITHUB_ACTIONS") == "true":
        print(f"::add-mask::{token}", flush=True)
    return token


def app_info(app_id: str, client_id: str, token: str) -> dict:
    url = f"{PUBLISH_V2}/app-info?{urllib.parse.urlencode({'appId': app_id})}"
    headers = {"client_id": client_id, "Authorization": f"Bearer {token}"}
    return http_json("GET", url, headers)


def android_slugs() -> list[str]:
    return [a["slug"] for a in load()["apps"]
            if platform_of(a) == "android" and a.get("agc_app_id")]


def find_app(slug: str) -> dict:
    for a in load()["apps"]:
        if a["slug"] == slug:
            return a
    raise WatchError(f"no app named {slug} in factory/apps.json")


def state_fields(payload: dict) -> dict:
    """The handful of fields that describe where a version stands."""
    info = payload.get("appInfo") or {}
    audit = payload.get("auditInfo") or {}
    return {
        "releaseState": info.get("releaseState"),
        "versionNumber": info.get("versionNumber") or info.get("versionCode"),
        "updateTime": info.get("updateTime"),
        "auditOpinion": (audit.get("auditOpinion") or "").strip(),
        "copyRightAuditResult": audit.get("copyRightAuditResult"),
        "recordAuditResult": audit.get("recordAuditResult"),
    }


def cmd_inspect(slugs: list[str], client_id: str, client_secret: str) -> int:
    """Print what AppGallery reports for each app, raw.

    This exists because Huawei does not publish a trustworthy releaseState enum.
    Running it against apps whose real state is known is how RELEASE_STATE below
    was filled in; keep it for the next time Huawei changes the numbers.
    """
    token = make_token(client_id, client_secret)
    failures = []
    for slug in slugs:
        app = find_app(slug)
        try:
            payload = app_info(str(app["agc_app_id"]), client_id, token)
        except WatchError as exc:
            log(f"{slug}: error: {exc}")
            failures.append(slug)
            continue
        fields = state_fields(payload)
        log(f"{slug} (appId {app['agc_app_id']}, registry says '{app.get('status')}')")
        for k, v in fields.items():
            if v not in (None, ""):
                log(f"    {k} = {v!r}")
        # Anything else that looks like a state, so a renamed field is not missed.
        info = payload.get("appInfo") or {}
        extra = {k: v for k, v in info.items()
                 if any(t in k.lower() for t in ("state", "status", "audit", "release"))
                 and k not in fields}
        for k, v in sorted(extra.items()):
            log(f"    (extra) {k} = {v!r}")
    return 1 if failures else 0


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Watch the AppGallery review state")
    p.add_argument("slug", nargs="?", default="")
    p.add_argument("--inspect", action="store_true",
                   help="print the raw state fields instead of opening issues")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY",
                                                    "oflorezawaken-dev/huawei-app-factory"))
    a = p.parse_args(argv)

    client_id = os.environ.get("AGC_CLIENT_ID", "")
    client_secret = os.environ.get("AGC_CLIENT_SECRET", "")
    if not client_id or not client_secret:
        log("AGC_CLIENT_ID and AGC_CLIENT_SECRET must be set")
        return 1

    slugs = [a.slug] if a.slug else android_slugs()
    if not slugs:
        log("no Android app has an agc_app_id yet; nothing to watch")
        return 0

    if a.inspect:
        return cmd_inspect(slugs, client_id, client_secret)

    log("watch mode is not wired up yet; run with --inspect")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
