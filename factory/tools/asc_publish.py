#!/usr/bin/env python3
"""
App Factory - upload a build to App Store Connect and, optionally, submit it.

Mirrors agc_publish.py's shape for the Android lane: one tool, one pipeline
run, upload then (optionally) submit. Standard library only, except for the
upload step itself, which shells out to Apple's own `xcrun altool` -- there is
no supported way to upload an .ipa over plain HTTP, and reimplementing
Transporter's protocol is not worth it when the OS ships a client.

Steps (numbers match the flags that trigger them):
  1. altool --upload-package    upload the .ipa
  2. --wait                     poll until the build finishes processing
  3. --attach                   attach that build to the target appStoreVersion
  4. --submit --notes "..."     write What's New for the primary locale, then
                                 create + submit a reviewSubmission

  python factory/tools/asc_publish.py plant-cue-ios --ipa build/App.ipa --wait --attach
  python factory/tools/asc_publish.py plant-cue-ios --ipa build/App.ipa \
      --wait --attach --submit --notes "Fixes the watering reminder."
  python factory/tools/asc_publish.py plant-cue-ios --ipa build/App.ipa --dry-run

Exit codes: 0 fine, 1 API/altool/configuration error, 2 bad arguments,
3 build never finished processing within --timeout.

NOTE ON THIS FILE'S review-submission STEP: implemented against Apple's
currently documented reviewSubmissions -> reviewSubmissionItems -> PATCH
submitted:true schema (the appStoreVersionSubmissions endpoint it replaced is
retired). It has not been exercised against a live App Store Connect account.
Treat the first real --submit as a supervised run, not an unattended one.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_client import ASCError, builds, log, make_token, mask_in_ci, resolve_app  # noqa: E402
from asc_metadata import EDITABLE_VERSION_STATES, api_call, find_editable_version  # noqa: E402

RELEASE_NOTES_MIN = 10
RELEASE_NOTES_MAX = 300


def upload(ipa_path: str, key_id: str) -> None:
    """Shell out to altool. The API key must sit at a fixed path altool itself
    looks for; there is no flag to pass key bytes directly."""
    from asc_client import private_key_pem  # local import: only needed here

    keys_dir = os.path.expanduser("~/.appstoreconnect/private_keys")
    os.makedirs(keys_dir, exist_ok=True)
    key_path = os.path.join(keys_dir, f"AuthKey_{key_id}.p8")
    fd = os.open(key_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(fd, "wb") as fh:
            fh.write(private_key_pem())
        log(f"uploading {ipa_path} via altool --upload-package")
        proc = subprocess.run(
            ["xcrun", "altool", "--upload-package", ipa_path,
             "--api-key", key_id, "--api-issuer", os.environ.get("ASC_ISSUER_ID", "")],
            capture_output=True, text=True)
        # altool's own output can include tokens; scrub before printing.
        out = proc.stdout + proc.stderr
        print(out.replace(os.environ.get("ASC_ISSUER_ID", "\x00"), "***"))
        if proc.returncode != 0:
            raise ASCError(f"altool --upload-package exited {proc.returncode}")
    finally:
        if os.path.exists(key_path):
            os.remove(key_path)


def wait_for_build(asc_app_id: str, build_number: str, timeout: int) -> str:
    token, deadline, delay = make_token(), time.time() + timeout, 30
    while time.time() < deadline:
        for row in builds(asc_app_id, token):
            attrs = row.get("attributes", {})
            if str(attrs.get("version")) != str(build_number):
                continue
            state = attrs.get("processingState")
            log(f"build {build_number}: {state}")
            if state == "VALID":
                return row["id"]
            if state in ("INVALID", "FAILED"):
                raise ASCError(f"build {build_number} will not become usable ({state})")
            break
        else:
            log(f"build {build_number} has not appeared in App Store Connect yet")
        time.sleep(delay)
        delay = min(delay * 2, 120)
        if time.time() + 60 > deadline:
            token = make_token()
    raise TimeoutError(f"timed out after {timeout}s waiting for build {build_number}")


def attach_build(version_id: str, build_id: str, token: str) -> None:
    api_call("PATCH", f"/v1/appStoreVersions/{version_id}", {
        "data": {"type": "appStoreVersions", "id": version_id,
                 "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}}, token)
    log(f"attached build {build_id} to appStoreVersion {version_id}")


def set_release_notes(version_id: str, notes: str, token: str) -> None:
    data = api_call("GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations"
                    "?fields[appStoreVersionLocalizations]=locale&limit=1", token=token)
    rows = data.get("data", [])
    if not rows:
        raise ASCError(
            "no appStoreVersionLocalizations yet; run asc_metadata.py --what text "
            "before submitting so there is a locale row to carry the release notes")
    loc_id = rows[0]["id"]
    api_call("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}",
              {"data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                       "attributes": {"whatsNew": notes}}}, token)
    log(f"release notes set on locale {rows[0].get('attributes', {}).get('locale', loc_id)}")


def submit_for_review(asc_app_id: str, token: str) -> None:
    submission = api_call("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": asc_app_id}}}}}, token)
    submission_id = submission.get("data", {}).get("id")
    if not submission_id:
        raise ASCError("reviewSubmissions POST did not return an id")
    log(f"created reviewSubmission {submission_id}")

    versions = api_call("GET", f"/v1/apps/{asc_app_id}/appStoreVersions"
                        "?filter[appStoreVersionState]=" + ",".join(sorted(EDITABLE_VERSION_STATES))
                        + "&fields[appStoreVersions]=versionString&limit=1", token=token)
    rows = versions.get("data", [])
    if not rows:
        raise ASCError("no editable appStoreVersion found to attach to the review submission")
    version_id = rows[0]["id"]

    api_call("POST", "/v1/reviewSubmissionItems", {
        "data": {"type": "reviewSubmissionItems",
                 "relationships": {
                     "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                     "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}}, token)
    log(f"added appStoreVersion {version_id} to the submission")

    api_call("PATCH", f"/v1/reviewSubmissions/{submission_id}",
              {"data": {"type": "reviewSubmissions", "id": submission_id,
                       "attributes": {"submitted": True}}}, token)
    log(f"reviewSubmission {submission_id} submitted")


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Upload and optionally submit an iOS build", add_help=True)
    p.add_argument("slug")
    p.add_argument("--ipa", required=True)
    p.add_argument("--wait", action="store_true", help="poll until the build finishes processing")
    p.add_argument("--attach", action="store_true", help="attach the build to the target appStoreVersion")
    p.add_argument("--submit", action="store_true", help="submit for review (implies --attach and --wait)")
    p.add_argument("--notes", default="", help="What's New text; required with --submit")
    p.add_argument("--timeout", type=int, default=1800)
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args(argv)

    if a.submit:
        a.attach = a.wait = True
    if a.submit and not (RELEASE_NOTES_MIN <= len(a.notes) <= RELEASE_NOTES_MAX):
        sys.exit(f"--submit requires --notes with {RELEASE_NOTES_MIN}-{RELEASE_NOTES_MAX} characters")
    if not a.dry_run and not os.path.isfile(a.ipa):
        sys.exit(f"no such file: {a.ipa}")

    try:
        asc_app_id, app = resolve_app(a.slug)
        version = app.get("current_version") or {}
        build_number = str(version.get("build") or "")
        marketing_version = str(version.get("marketing_version") or "")
        if not build_number:
            sys.exit(f"registry entry for {a.slug} has no current_version.build")

        if a.dry_run:
            log(f"[dry-run] would upload {a.ipa} for {a.slug} "
               f"(build {build_number}, version {marketing_version})")
            if a.attach:
                log("[dry-run] would attach the uploaded build to the appStoreVersion")
            if a.submit:
                log(f"[dry-run] would submit for review with notes: {a.notes!r}")
            return 0

        key_id = os.environ.get("ASC_KEY_ID", "")
        if not key_id:
            sys.exit("ASC_KEY_ID is required")
        mask_in_ci(os.environ.get("ASC_ISSUER_ID", ""))
        upload(a.ipa, key_id)

        if a.wait:
            build_id = wait_for_build(asc_app_id, build_number, a.timeout)
        else:
            build_id = None

        if a.attach or a.submit:
            token = make_token()
            version_id = find_editable_version(asc_app_id, marketing_version, token)
            if build_id:
                attach_build(version_id, build_id, token)
            if a.submit:
                set_release_notes(version_id, a.notes, token)
                submit_for_review(asc_app_id, token)
        return 0
    except TimeoutError as exc:
        log(f"error: {exc}")
        return 3
    except ASCError as exc:
        log(f"error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
