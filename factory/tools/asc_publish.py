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
from asc_client import ASCError, builds, log, make_token, mask_in_ci, resolve_app, version_state  # noqa: E402
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
            # Error -19232: this exact build number already reached Apple on an
            # earlier, since-failed run of this same tool (attaching or
            # submitting failed after a successful upload). The binary is
            # already there and processing; re-running --wait/--attach against
            # it is correct, re-raising here would force a pointless registry
            # version bump for a retry that has nothing wrong with the upload.
            if "-19232" in out or "must be higher than the previously uploaded version" in out:
                log("build already present at Apple (error -19232); continuing "
                   "as if the upload had just succeeded")
                return
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
    try:
        api_call("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}",
                  {"data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                           "attributes": {"whatsNew": notes}}}, token)
    except ASCError as exc:
        # A 1.0.0 has no previous release for anything to be new relative to,
        # and Apple refuses the field outright. Not an error worth aborting a
        # submission over: there is simply nothing for What's New to say yet.
        if "Attribute 'whatsNew' cannot be edited" not in str(exc):
            raise
        log("this version does not take release notes yet (first version); continuing")
        return
    log(f"release notes set on locale {rows[0].get('attributes', {}).get('locale', loc_id)}")


# Each probe answers one console-only requirement. They are best effort by
# design: these endpoints are not exercised by any earlier step, so a probe
# that fails tells us nothing about the app and must never replace Apple's own
# error. A failed probe reports "could not check" and the diagnosis continues.
def _probe(label: str, fn) -> str:
    try:
        ok, note = fn()
    except ASCError as exc:
        return f"  ?  {label}: could not check ({exc})"
    except Exception as exc:  # noqa: BLE001 - a probe must never break the report
        return f"  ?  {label}: could not check ({type(exc).__name__}: {exc})"
    mark = "ok " if ok else "!! "
    return f"  {mark} {label}" + (f": {note}" if note else "")


def diagnose_submission_blockers(asc_app_id: str, version_id: str, token: str) -> list[str]:
    """Report which console-only requirements look unmet.

    Apple refuses the submission without saying which requirement is missing,
    so these probes turn a static checklist into an actual answer wherever the
    API exposes one. Lines marked !! are the ones to go fix.
    """
    def pricing():
        data = api_call("GET", f"/v1/apps/{asc_app_id}/appPriceSchedule", token=token)
        return bool(data.get("data")), "" if data.get("data") else "no price schedule set"

    def age_rating():
        # On appInfos, not appStoreVersions: the version relationship does not
        # exist and answered 404, which the report then had to call "could not
        # check". The age rating belongs to the app's information, not to one
        # version of it.
        infos = api_call("GET", f"/v1/apps/{asc_app_id}/appInfos?limit=1", token=token).get("data") or []
        if not infos:
            return False, "the app has no appInfo yet"
        data = api_call("GET", f"/v1/appInfos/{infos[0]['id']}/ageRatingDeclaration", token=token)
        return bool(data.get("data")), "" if data.get("data") else "questionnaire not completed"

    def privacy():
        # Not exposed by the App Store Connect API at all -- verified against
        # Apple's OpenAPI specification, which has no path for it. Two probes at
        # guessed URLs 404'd before that was checked. Reported as console-only
        # rather than as a failed lookup.
        raise ASCError("not in the API; check App Store Connect > App Privacy (needs Admin)")

    def review_detail():
        data = api_call("GET", f"/v1/appStoreVersions/{version_id}/appStoreReviewDetail", token=token)
        attrs = (data.get("data") or {}).get("attributes") or {}
        missing = [k for k in ("contactFirstName", "contactLastName", "contactEmail", "contactPhone")
                   if not attrs.get(k)]
        return not missing, f"missing {', '.join(missing)}" if missing else ""

    def export_compliance():
        rows = api_call("GET", f"/v1/apps/{asc_app_id}/builds?limit=1", token=token).get("data") or []
        if not rows:
            return False, "no build to check"
        attrs = rows[0].get("attributes") or {}
        if "usesNonExemptEncryption" not in attrs:
            return False, "build does not report usesNonExemptEncryption"
        answered = attrs["usesNonExemptEncryption"] is not None
        return answered, "" if answered else "unanswered on the newest build"

    return [
        _probe("Pricing and Availability", pricing),
        _probe("Age rating (App Information)", age_rating),
        _probe("App Privacy questionnaire", privacy),
        _probe("App Review contact details", review_detail),
        _probe("Export compliance", export_compliance),
    ]


def clear_open_review_submission(asc_app_id: str, token: str) -> None:
    """Delete any review submission still sitting unsubmitted on the app.

    Apple allows one open submission per app and platform, so a run that
    created a submission and then failed to add the version leaves the next
    run unable to create one at all. That is exactly what a failed submit
    used to do here.
    """
    data = api_call("GET", f"/v1/apps/{asc_app_id}/reviewSubmissions?limit=50", token=token)
    for row in data.get("data", []):
        attrs = row.get("attributes") or {}
        if attrs.get("submitted"):
            continue
        # Not DELETE: Apple answers 403 "does not allow 'DELETE'". Cancelling is
        # an update, and leaving these open is how four of them piled up on
        # PriceJar over a day of failed attempts.
        try:
            api_call("PATCH", f"/v1/reviewSubmissions/{row['id']}",
                     {"data": {"type": "reviewSubmissions", "id": row["id"],
                               "attributes": {"canceled": True}}}, token)
            log(f"cancelled the open, unsubmitted reviewSubmission {row['id']}")
        except ASCError as exc:
            log(f"warning: could not cancel open reviewSubmission {row['id']}: {exc}")


# An in-app purchase does not travel with a version by being "Ready to Submit".
# That state means configured and waiting; it has to be added to the review
# submission as its own item. PriceJar 1.0.0 (4) was rejected for exactly this:
# "the app includes references to paid content but the associated In-App
# Purchase products have not been submitted for review."
IAP_SUBMITTABLE_STATES = ("READY_TO_SUBMIT", "DEVELOPER_ACTION_NEEDED", "REJECTED")

# From Apple's OpenAPI spec: ReviewSubmissionItemCreateRequest relates to an
# inAppPurchaseVersion -- the purchase's version, not the purchase. Two names
# were guessed before the spec was consulted; both cost a live submission.
IAP_ITEM_RELATIONSHIP = "inAppPurchaseVersion"


def in_app_purchases(asc_app_id: str, token: str) -> list[dict]:
    """The app's in-app purchases, or [] when Apple answers and there are none.

    Raises when it cannot ask at all, rather than reporting an empty list: the
    caller refuses to submit an app whose registry declares a purchase and whose
    purchases it could not enumerate, and a silent [] would turn that guard off.
    """
    data = api_call("GET", f"/v1/apps/{asc_app_id}/inAppPurchasesV2?limit=200", token=token)
    return data.get("data", []) or []


def submittable_in_app_purchases(asc_app_id: str, product_id: str, token: str) -> list[dict]:
    """The purchases ready to go in, or an explanation of why none are.

    Called BEFORE the review submission is created. Failing afterwards would
    leave an open submission behind, and Apple does not allow deleting one.
    """
    rows = in_app_purchases(asc_app_id, token)
    by_state: dict[str, list[str]] = {}
    for row in rows:
        attrs = row.get("attributes") or {}
        by_state.setdefault(str(attrs.get("state")), []).append(str(attrs.get("productId")))

    submittable = [r for r in rows
                   if str((r.get("attributes") or {}).get("state")) in IAP_SUBMITTABLE_STATES]
    if not submittable:
        raise ASCError(
            f"{product_id} is declared in the registry but no in-app purchase of this app is in "
            f"a submittable state {IAP_SUBMITTABLE_STATES}. Apple has: "
            + (", ".join(f"{pid} ({state})" for state, pids in sorted(by_state.items())
                         for pid in pids) or "no in-app purchases at all")
            + ". Submitting now would repeat the rejection that says the paid content was never "
              "submitted for review -- complete the product in App Store Connect first.")
    return submittable


def add_iap_submission_items(submission_id: str, submittable: list[dict], token: str) -> list[str]:
    """Attach already-validated in-app purchases to the review submission."""
    added = []
    for row in submittable:
        attrs = row.get("attributes") or {}
        product = str(attrs.get("productId") or row["id"])
        versions = api_call("GET", f"/v2/inAppPurchases/{row['id']}/versions", token=token).get("data") or []
        if not versions:
            raise ASCError(f"{product} has no inAppPurchaseVersion to submit; finish it in App Store Connect")
        api_call("POST", "/v1/reviewSubmissionItems", {
            "data": {"type": "reviewSubmissionItems",
                     "relationships": {
                         "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                         "inAppPurchaseVersion": {"data": {"type": "inAppPurchaseVersions", "id": versions[0]["id"]}}}}}, token)
        added.append(product)
        log(f"added in-app purchase {product} to the submission")
    return added


def submit_for_review(asc_app_id: str, token: str, iap_product_id: str = "") -> None:
    # Everything that can be checked is checked before anything is created: a
    # failure after the POST leaves an open submission behind, and Apple refuses
    # to delete one.
    submittable_iaps = (submittable_in_app_purchases(asc_app_id, iap_product_id, token)
                        if iap_product_id else [])

    submission = api_call("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": asc_app_id}}}}}, token)
    submission_id = submission.get("data", {}).get("id")
    if not submission_id:
        raise ASCError("reviewSubmissions POST did not return an id")
    log(f"created reviewSubmission {submission_id}")

    # Filtered client-side, not server-side: an unverified attribute name in
    # filter[] gets the whole request rejected with 400 the same way a bad
    # fields[] name does, which is exactly what happened here on the first
    # real upload. Fetching everything and checking version_state() ourselves
    # costs one extra round trip but never depends on guessing Apple's field
    # name correctly in a query string.
    all_versions = api_call("GET", f"/v1/apps/{asc_app_id}/appStoreVersions?limit=50", token=token)
    editable = [r for r in all_versions.get("data", [])
                if version_state(r.get("attributes", {})) in EDITABLE_VERSION_STATES]
    if not editable:
        raise ASCError("no editable appStoreVersion found to attach to the review submission")
    version_id = editable[0]["id"]

    try:
        api_call("POST", "/v1/reviewSubmissionItems", {
            "data": {"type": "reviewSubmissionItems",
                     "relationships": {
                         "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": submission_id}},
                         "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}}, token)
    except ASCError as exc:
        if "not in valid state" not in str(exc):
            raise
        # Apple says the version cannot be reviewed but will not say which
        # requirement is unmet. Ask the API what it will answer, then leave the
        # app as we found it -- an abandoned submission would block the retry.
        findings = diagnose_submission_blockers(asc_app_id, version_id, token)
        clear_open_review_submission(asc_app_id, token)
        raise ASCError(
            f"Apple will not accept version {version_id} for review yet, and does not report "
            "which requirement is missing. Probing the ones the factory cannot fill in:\n"
            + "\n".join(findings) + "\n"
            "  (!! = looks unmet, ? = the API would not answer; the version page marks them in red)\n"
            f"Open https://appstoreconnect.apple.com/apps/{asc_app_id}/distribution and fix "
            "whatever it flags, then re-run this workflow.") from exc
    log(f"added appStoreVersion {version_id} to the submission")

    # The version alone is not the submission when the app sells something.
    if submittable_iaps:
        add_iap_submission_items(submission_id, submittable_iaps, token)

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
    # Notes are optional: a first version cannot carry What's New at all, so
    # requiring them would make the very first submission impossible. When they
    # are given they still have to fit Apple's limits.
    if a.notes and not (RELEASE_NOTES_MIN <= len(a.notes) <= RELEASE_NOTES_MAX):
        sys.exit(f"--notes must be {RELEASE_NOTES_MIN}-{RELEASE_NOTES_MAX} characters when given")
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
            # Before anything that edits the version. Adding a version to a
            # review submission moves it to READY_FOR_REVIEW, and App Store
            # Connect then refuses every metadata edit -- so a run that died
            # after adding the version item left the version locked, the
            # submission open and unsubmitted, and the next run unable to do
            # anything at all. Cancelling first puts it back in reach.
            if a.submit:
                clear_open_review_submission(asc_app_id, token)
            version_id = find_editable_version(asc_app_id, marketing_version, token)
            if build_id:
                attach_build(version_id, build_id, token)
            if a.submit:
                if a.notes:
                    set_release_notes(version_id, a.notes, token)
                submit_for_review(asc_app_id, token,
                                  str((app.get("iap") or {}).get("remove_ads_product_id") or ""))
        return 0
    except TimeoutError as exc:
        log(f"error: {exc}")
        return 3
    except ASCError as exc:
        log(f"error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
