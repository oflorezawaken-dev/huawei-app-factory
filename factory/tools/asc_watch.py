#!/usr/bin/env python3
"""
App Factory - watch App Store review state and open an issue when it changes.

Polls every registered iOS app's newest appStoreVersion and, when it reaches a
state a human has to act on, opens a GitHub issue describing what to do next.
Step 10.7 of the iOS handoff.

  python factory/tools/asc_watch.py                  # every iOS app in the registry
  python factory/tools/asc_watch.py plant-cue-ios    # just one
  python factory/tools/asc_watch.py --dry-run        # report, never touch GitHub

Exit codes: 0 fine (with or without new issues), 1 an app could not be polled.
A single app failing does not stop the others; the run reports at the end.

## Why there is no state file

Reporting "the state changed" needs memory of the last state seen. Rather than
commit a state file from CI every day -- which races with real commits and adds
noise to the history -- this uses the issues themselves as the memory: one
issue per (slug, version, state), created only if no issue with that exact
title exists yet. Re-running is therefore idempotent, and deleting an issue
legitimately means "tell me again".

## States

Only states a human must respond to are reported (asc_client.TERMINAL_STATES).
WAITING_FOR_REVIEW, IN_REVIEW and PREPARE_FOR_SUBMISSION are normal progress
and are logged but never open an issue -- an app sitting in review for two days
is not news.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_client import ASCError, TERMINAL_STATES, log, make_token, resolve_app, versions  # noqa: E402
from registry import load, platform_of  # noqa: E402

WATCH_LABEL = "review-status"

# What the human should do about each state. Written as instructions, not
# status text: an issue that only says "REJECTED" wastes the notification.
NEXT_STEP = {
    "READY_FOR_SALE":
        "The app is live on the App Store. Nothing is blocked. Consider scheduling "
        "the first update in 2-4 weeks -- Apple rewards active apps, and early "
        "reviews usually name one concrete fix worth making.",
    "PENDING_DEVELOPER_RELEASE":
        "Apple approved the version and is waiting for YOU to release it. Open App "
        "Store Connect and press Release, or set a release date. Nothing ships until "
        "you do.",
    "REJECTED":
        "Apple rejected the build. Open Resolution Center in App Store Connect and "
        "read the guideline number they cite, then run the fix step with it: "
        "`python factory/factory.py fix <slug> --run-id <n>`. Do not resubmit "
        "without addressing the specific guideline -- repeat rejections for the "
        "same reason escalate.",
    "METADATA_REJECTED":
        "Apple rejected the store listing, not the binary. Usually the description "
        "promises something the app does not do, the screenshots do not match the "
        "app, or a permission string is vague. Fix the listing and resubmit; no new "
        "build is needed.",
    "DEVELOPER_REJECTED":
        "The submission was withdrawn from review (by you or by a tool). Resubmit "
        "when ready.",
    "INVALID_BINARY":
        "App Store Connect rejected the binary itself, usually signing or a missing "
        "capability. Check the email Apple sent, fix the build, and upload a new one.",
}


def gh(args: list[str], check: bool = True) -> str:
    proc = subprocess.run(["gh"] + args, capture_output=True, text=True)
    if check and proc.returncode != 0:
        raise ASCError(f"gh {' '.join(args[:2])} failed: {proc.stderr.strip()}")
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
            "--description", "Automatic App Store review-state report"], check=False)


def issue_body(app: dict, slug: str, version: str, state: str) -> str:
    asc_app_id = str(app.get("asc_app_id") or "")
    return "\n".join([
        f"**{app['name']}** version `{version}` is now **{state}** on the App Store.",
        "",
        "## What to do",
        "",
        NEXT_STEP.get(state, "Check App Store Connect for details."),
        "",
        "## Details",
        "",
        f"- App: `{slug}` (`{app.get('bundle_id', '')}`)",
        f"- App Store Connect: https://appstoreconnect.apple.com/apps/{asc_app_id}/appstore",
        f"- Check the current state yourself: `python factory/factory.py asc {slug} --what state`",
        "",
        "---",
        "*Opened automatically by `factory-ios-watch.yml`. One issue is created per "
        "app+version+state, so this will not repeat daily. Close it when handled.*",
    ])


def poll_app(slug: str, repo: str, dry_run: bool, token: str | None) -> tuple[str, bool]:
    """(state, opened_issue) for one app."""
    asc_app_id, app = resolve_app(slug)
    rows = versions(asc_app_id, token)
    if not rows:
        log(f"{slug}: no version in App Store Connect yet")
        return "NO_VERSION", False

    attrs = rows[0].get("attributes", {})
    state = attrs.get("appStoreState", "UNKNOWN")
    version = attrs.get("versionString", "?")

    if state not in TERMINAL_STATES:
        log(f"{slug} {version}: {state} (in progress, nothing to report)")
        return state, False

    title = f"iOS review: {app['name']} {version} is now {state}"
    if dry_run:
        log(f"{slug} {version}: {state} -> [dry-run] would open issue {title!r}")
        return state, False
    if issue_exists(repo, title):
        log(f"{slug} {version}: {state} (already reported)")
        return state, False

    ensure_label(repo)
    gh(["issue", "create", "--repo", repo, "--title", title,
        "--label", WATCH_LABEL, "--body", issue_body(app, slug, version, state)])
    log(f"{slug} {version}: {state} -> opened issue {title!r}")
    return state, True


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Watch App Store review state", add_help=True)
    p.add_argument("slug", nargs="?", default="")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY",
                                                    "oflorezawaken-dev/huawei-app-factory"))
    a = p.parse_args(argv)

    if a.slug:
        slugs = [a.slug]
    else:
        slugs = [app["slug"] for app in load()["apps"]
                 if platform_of(app) == "ios" and app.get("asc_app_id")]
    if not slugs:
        log("no iOS app has an asc_app_id yet; nothing to watch")
        return 0

    # One token for the whole sweep: it outlives a handful of reads comfortably.
    token = None if a.dry_run else make_token()
    failures, opened = [], 0
    for slug in slugs:
        try:
            _, created = poll_app(slug, a.repo, a.dry_run, token)
            opened += int(created)
        except ASCError as exc:
            log(f"{slug}: error: {exc}")
            failures.append(slug)

    log(f"polled {len(slugs)} app(s), opened {opened} issue(s)"
        + (f", {len(failures)} failed: {', '.join(failures)}" if failures else ""))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
