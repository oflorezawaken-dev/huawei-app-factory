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
NEWLINE = chr(10)

# Measured on 2026-09-14 against this account's own apps rather than copied from
# a doc page: receipt-lens / plant-cue / habit-cue were on the shelf and all read
# 0, sudoku was under review and read 4. Everything else is deliberately absent --
# see the module docstring.
RELEASE_STATE: dict[int, str] = {
    0: "LIVE",
    4: "IN_REVIEW",
    7: "DRAFT",
}

# A version is only interesting once Huawei has said something about it. These are
# the states worth an issue; IN_REVIEW is normal progress and stays silent.
ACTIONABLE = {"LIVE", "REJECTED"}

# What to do about each state. Instructions, not status text: an issue that only
# says "REJECTED" has wasted the notification it cost.
NEXT_STEP = {
    "LIVE":
        "The version is on the shelf and downloadable. Nothing is blocked. Worth doing "
        "now: check that the store listing reads the way you meant it to in every "
        "language, and that the ad units are actually serving (a package built before "
        "its unit IDs were set will show zero revenue while looking perfectly healthy).",
    "REJECTED":
        "Huawei rejected the version. The reviewer's own words are quoted below; fix the "
        "cause, bump versionCode, and publish again with "
        "`python factory/factory.py publish <slug> --submit --notes \"...\"`. Past "
        "rejections in this factory were a privacy-tag declaration that contradicted the "
        "app, and a camera crash from a FileProvider path that was never declared.",
}


def approved(opinion: str) -> bool:
    """True when Huawei's review comment is an approval.

    The wording is stable across every approval this account has received:
    'App review results：
    Your App has been approved.' Anything else that
    carries a comment is treated as a rejection, which is the safe direction to
    be wrong in -- a false rejection costs a glance, a missed one costs weeks.
    """
    return "has been approved" in opinion


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
        # Everything else too: a field that matters may not be named after a state,
        # and a filtered dump is how you convince yourself of a wrong conclusion.
        info = payload.get("appInfo") or {}
        for k, v in sorted(info.items()):
            if k in fields:
                continue
            text = repr(v)
            log(f"    (other) {k} = {text[:160]}{'...' if len(text) > 160 else ''}")
        for k, v in sorted((payload.get("auditInfo") or {}).items()):
            if k in fields:
                continue
            log(f"    (audit) {k} = {repr(v)[:160]}")
        # Printed whole and last: the two fields worth copying from a configured
        # app to a new one, and both long enough to be truncated by the dump above.
        for key in ("privacyLabel", "publishCountry"):
            value = (payload.get("appInfo") or {}).get(key)
            if value:
                log(f"    FULL {key} = {value}")
    return 1 if failures else 0


def gh(args: list[str], check: bool = True) -> str:
    proc = subprocess.run(["gh", *args], capture_output=True, text=True)
    if check and proc.returncode != 0:
        raise WatchError(f"gh {' '.join(args[:2])} failed: {proc.stderr.strip()}")
    return proc.stdout


def issue_exists(repo: str, title: str) -> bool:
    """True when an issue with this exact title already exists (open or closed)."""
    raw = gh(["issue", "list", "--repo", repo, "--state", "all", "--limit", "200",
              "--label", WATCH_LABEL, "--json", "title"])
    try:
        return any(row.get("title") == title for row in json.loads(raw or "[]"))
    except json.JSONDecodeError:
        return False


def ensure_label(repo: str) -> None:
    existing = gh(["label", "list", "--repo", repo, "--json", "name"], check=False)
    try:
        names = {row.get("name") for row in json.loads(existing or "[]")}
    except json.JSONDecodeError:
        names = set()
    if WATCH_LABEL not in names:
        gh(["label", "create", WATCH_LABEL, "--repo", repo, "--color", "5319E7",
            "--description", "Automatic AppGallery review-state report"], check=False)


def issue_body(app: dict, slug: str, version: str, state: str, fields: dict) -> str:
    opinion = fields.get("auditOpinion") or ""
    lines = [
        f"**{app['name']}** version `{version}` is now **{state}** on AppGallery.",
        "",
        "## What to do",
        "",
        NEXT_STEP.get(state, "Open AppGallery Connect and look at the version."),
    ]
    if opinion:
        lines += ["", "## What Huawei said", "", "```", opinion, "```"]
    lines += [
        "",
        "## Details",
        "",
        f"- App: `{slug}` (`{app.get('package', '')}`), AppGallery App ID `{app.get('agc_app_id')}`",
        f"- Released version on the shelf: `{fields.get('onShelfVersionNumber') or '-'}`",
        f"- Last change reported by Huawei: {fields.get('updateTime') or '-'}",
        "- See it yourself: `python factory/factory.py watch " + slug + " --inspect`",
        "",
        "---",
        "*Opened automatically by `factory-watch.yml`. One issue per app+version+state, "
        "so this will not repeat daily. Close it when handled.*",
    ]
    return NEWLINE.join(lines)


def poll_app(slug: str, client_id: str, token: str, repo: str, dry_run: bool) -> bool:
    """Polls one app; returns True when an issue was opened."""
    app = find_app(slug)
    fields = state_fields(app_info(str(app["agc_app_id"]), client_id, token))
    version = str(fields.get("versionNumber") or "?")
    raw_state = fields.get("releaseState")
    opinion = fields.get("auditOpinion") or ""

    # The comment says what Huawei decided, and beats an enum Huawei does not
    # document. But it describes the LAST decision, not necessarily this version:
    # an app that is live with a new version in flight still carries the old
    # approval, and reading it then would announce the new version as LIVE while
    # it sits in review. Only trust it while the version reported is the one on
    # the shelf.
    on_shelf = str(fields.get("onShelfVersionNumber") or "")
    verdict_is_current = bool(opinion) and (not on_shelf or on_shelf == version)
    if verdict_is_current:
        state = "LIVE" if approved(opinion) else "REJECTED"
    else:
        state = RELEASE_STATE.get(raw_state, "")

    if not state:
        log(f"{slug} {version}: releaseState={raw_state!r} is not in the measured table "
            f"and there is no review comment; reporting nothing")
        return False
    if state not in ACTIONABLE:
        log(f"{slug} {version}: {state} (in progress, nothing to report)")
        return False

    title = f"AppGallery review: {app['name']} {version} is now {state}"
    if dry_run:
        log(f"{slug} {version}: {state} -> [dry-run] would open issue {title!r}")
        return False
    if issue_exists(repo, title):
        log(f"{slug} {version}: {state} (already reported)")
        return False

    ensure_label(repo)
    gh(["issue", "create", "--repo", repo, "--title", title,
        "--label", WATCH_LABEL, "--body", issue_body(app, slug, version, state, fields)])
    log(f"{slug} {version}: {state} -> opened issue {title!r}")
    return True


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

    token = make_token(client_id, client_secret)
    failures, opened = [], 0
    for slug in slugs:
        try:
            opened += int(poll_app(slug, client_id, token, a.repo, a.dry_run))
        except WatchError as exc:
            log(f"{slug}: error: {exc}")
            failures.append(slug)

    log(f"polled {len(slugs)} app(s), opened {opened} issue(s)"
        + (f", {len(failures)} failed: {', '.join(failures)}" if failures else ""))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
