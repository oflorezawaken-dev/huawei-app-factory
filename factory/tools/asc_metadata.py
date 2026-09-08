#!/usr/bin/env python3
"""
App Factory - push store metadata and screenshots to App Store Connect.

Converts apps-ios/<slug>/store/listing.json (same shape as Android's
listing.json, but with Apple's locale codes) into the two localized App Store
Connect resources Apple splits this data across:

  appInfoLocalizations        name, subtitle, privacy policy URL
                              (attached to an appInfo, not a version - these
                              can be edited even while a version is in review)
  appStoreVersionLocalizations   description, keywords, promotional text,
                              support URL, what's new
                              (attached to one specific, editable version)

Screenshots go through Apple's three-step Media API: reserve an
appScreenshot, PUT the bytes to the URL Apple returns, then PATCH it
uploaded=true with an MD5 checksum.

Standard library only, reusing asc_client's JWT signing and HTTP helpers.

  python factory/tools/asc_metadata.py plant-cue-ios --what text
  python factory/tools/asc_metadata.py plant-cue-ios --what screenshots
  python factory/tools/asc_metadata.py plant-cue-ios --what all --dry-run

Exit codes: 0 fine, 1 API or configuration error, 2 bad arguments.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_client import API_BASE, ASCError, log, make_token, resolve_app, version_state  # noqa: E402
from registry import ROOT, load  # noqa: E402

# App info fields live on the app record, editable regardless of version state.
APP_INFO_FIELDS = {"name": "name", "subtitle": "subtitle", "privacy_policy_url": "privacyPolicyUrl"}
# Version fields are tied to one specific, still-editable appStoreVersion.
VERSION_FIELDS = {
    "description": "description", "keywords": "keywords",
    "promotional_text": "promotionalText", "release_notes": "whatsNew",
    "support_url": "supportUrl",
    # Optional in App Store Connect and deliberately unset: pointing it at the
    # support page would just duplicate a link Apple already shows separately.
    "marketing_url": "marketingUrl",
}
EDITABLE_VERSION_STATES = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED"}


def api_call(method: str, path: str, body: dict | None = None, token: str | None = None) -> dict:
    url = path if path.startswith("http") else f"{API_BASE}{path}"
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {token or make_token()}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        body_text = exc.read().decode("utf-8", "replace")
        try:
            errors = json.loads(body_text).get("errors", [])
            detail = "; ".join(f"{e.get('title')}: {e.get('detail')}" for e in errors) or body_text
        except json.JSONDecodeError:
            detail = body_text
        raise ASCError(f"{method} {path} -> HTTP {exc.code}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise ASCError(f"{method} {path} failed: {exc.reason}") from exc


def load_listing(app: dict) -> list[dict]:
    path = os.path.join(ROOT, app["store_dir"], "listing.json")
    if not os.path.isfile(path):
        raise ASCError(f"{os.path.relpath(path, ROOT)} is missing; run the listing step first")
    with open(path, encoding="utf-8") as fh:
        return json.load(fh).get("languages", [])


def find_app_info_id(asc_app_id: str, token: str) -> str:
    data = api_call("GET", f"/v1/apps/{asc_app_id}/appInfos", token=token)
    rows = data.get("data", [])
    if not rows:
        raise ASCError(f"app {asc_app_id} has no appInfos yet; it must be created in App Store Connect first")
    return rows[0]["id"]


def find_editable_version(asc_app_id: str, marketing_version: str, token: str) -> str:
    # No fields[] restriction: naming the wrong field there gets the whole
    # request rejected with 400, which is exactly what cost the first real
    # PriceJar upload a step. version_state() reads whichever key Apple
    # actually sent back instead of a field name guessed in advance.
    data = api_call("GET", f"/v1/apps/{asc_app_id}/appStoreVersions"
                    f"?filter[versionString]={marketing_version}", token=token)
    rows = data.get("data", [])
    if not rows:
        raise ASCError(
            f"no appStoreVersion {marketing_version} found. Create it in App Store Connect "
            "(App Store tab > + Version) before pushing metadata.")
    row = rows[0]
    state = version_state(row.get("attributes", {}))
    if state not in EDITABLE_VERSION_STATES:
        raise ASCError(
            f"appStoreVersion {marketing_version} is in state {state}, which App Store Connect will "
            f"not let you edit metadata on (editable states: {', '.join(sorted(EDITABLE_VERSION_STATES))}).")
    return row["id"]


def existing_localization(resource: str, parent_field: str, parent_id: str, locale: str, token: str) -> str | None:
    data = api_call("GET", f"/v1/{parent_field}/{parent_id}/{resource}"
                    f"?filter[locale]={locale}&fields[{resource}]=locale", token=token)
    rows = data.get("data", [])
    return rows[0]["id"] if rows else None


def upsert_localization(resource: str, parent_type: str, parent_field: str, parent_id: str,
                        locale: str, attributes: dict, token: str, dry_run: bool) -> None:
    if not attributes:
        return
    existing_id = None if dry_run else existing_localization(resource, parent_field, parent_id, locale, token)
    if dry_run:
        log(f"  [dry-run] {resource} {locale}: {attributes}")
        return
    if existing_id:
        try:
            api_call("PATCH", f"/v1/{resource}/{existing_id}",
                     {"data": {"type": resource, "id": existing_id, "attributes": attributes}}, token)
        except ASCError as exc:
            # A first version has no "What's New": there is no previous release
            # for anything to be new relative to, and Apple rejects the whole
            # PATCH with 409 rather than ignoring the field. Drop it and retry
            # so one inapplicable attribute does not block the entire listing.
            blocked = [k for k in attributes if f"Attribute '{k}' cannot be edited" in str(exc)]
            if not blocked:
                raise
            remaining = {k: v for k, v in attributes.items() if k not in blocked}
            log(f"  {resource} {locale}: Apple will not accept {blocked} on this version yet; "
               f"sending the rest")
            if not remaining:
                return
            api_call("PATCH", f"/v1/{resource}/{existing_id}",
                     {"data": {"type": resource, "id": existing_id, "attributes": remaining}}, token)
            attributes = remaining
    else:
        body = {"data": {"type": resource, "attributes": {**attributes, "locale": locale},
                         "relationships": {parent_type: {"data": {"type": parent_type + "s", "id": parent_id}}}}}
        api_call("POST", f"/v1/{resource}", body, token)
    log(f"  {resource} {locale}: {sorted(attributes)}")


def page_urls(app: dict) -> dict[str, str]:
    """The published privacy and support page URLs, derived from the registry.

    Not read from listing.json: the registry already knows privacy_path and
    support_path and the Pages base URL, and Apple requires the privacy URL to
    publish at all. Asking a human to retype them into nine locale entries is
    how PriceJar's first metadata push reached Apple with neither.
    """
    base = load()["defaults"]["privacy_base_url"].rstrip("/")
    out = {}
    for key, field in (("privacy_path", "privacy_policy_url"), ("support_path", "support_url")):
        path = app.get(key, "")
        if path:
            out[field] = f"{base}/{path.removeprefix('docs/').strip('/')}/"
    return out


def push_version_attributes(version_id: str, token: str, dry_run: bool) -> None:
    """Attributes on the version itself rather than on a localization.

    Copyright is the one that matters here: it is shown publicly on the store
    listing and Apple will not let a version be submitted without it.
    """
    holder = load()["defaults"]["ios"].get("copyright_holder", "")
    if not holder:
        return
    # Apple renders the (c) symbol itself; the value is "<year> <holder>".
    value = f"{time.gmtime().tm_year} {holder}"
    if dry_run:
        log(f"  [dry-run] appStoreVersions copyright: {value}")
        return
    api_call("PATCH", f"/v1/appStoreVersions/{version_id}",
             {"data": {"type": "appStoreVersions", "id": version_id,
                       "attributes": {"copyright": value}}}, token)
    log(f"  appStoreVersions copyright: {value}")


def push_text(app: dict, asc_app_id: str, listing: list[dict], token: str, dry_run: bool) -> None:
    app_info_id = "dry-run" if dry_run else find_app_info_id(asc_app_id, token)
    version = app.get("current_version") or {}
    marketing_version = str(version.get("marketing_version") or "")
    version_id = "dry-run" if dry_run else find_editable_version(asc_app_id, marketing_version, token)
    urls = page_urls(app)

    for entry in listing:
        locale = entry.get("lang")
        if not locale:
            continue
        # The registry's URLs win over anything in listing.json: they are
        # derived from the paths that actually got published to Pages.
        merged = {**entry, **urls}
        info_attrs = {v: merged[k] for k, v in APP_INFO_FIELDS.items() if merged.get(k)}
        upsert_localization("appInfoLocalizations", "appInfo", "appInfos", app_info_id,
                            locale, info_attrs, token, dry_run)
        version_attrs = {v: merged[k] for k, v in VERSION_FIELDS.items() if merged.get(k)}
        upsert_localization("appStoreVersionLocalizations", "appStoreVersion", "appStoreVersions", version_id,
                            locale, version_attrs, token, dry_run)

    push_version_attributes(version_id, token, dry_run)


def md5_of(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def find_version_localization_id(version_id: str, locale: str, token: str) -> str:
    existing = existing_localization("appStoreVersionLocalizations", "appStoreVersions", version_id, locale, token)
    if not existing:
        raise ASCError(
            f"no appStoreVersionLocalization for locale {locale} yet; run --what text first "
            "so Apple has a localization row to attach screenshots to")
    return existing


def find_or_create_screenshot_set(localization_id: str, display_type: str, token: str) -> str:
    """The set for this locale and device, reused if it exists.

    Look-up comes first deliberately. Creating one per screenshot and treating
    the failure as the signal does not work: Apple answers a duplicate create
    with 409 "Screenshot Set Already Exists!", which is an exception, not an
    empty id -- so the second screenshot of every locale aborted the run. It is
    also one API call per locale instead of one per image.
    """
    existing = api_call("GET", f"/v1/appStoreVersionLocalizations/{localization_id}/appScreenshotSets"
                        f"?filter[screenshotDisplayType]={display_type}", token)
    rows = existing.get("data", [])
    if rows:
        return rows[0]["id"]

    created = api_call("POST", "/v1/appScreenshotSets", {
        "data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": display_type},
                 "relationships": {"appStoreVersionLocalization":
                                   {"data": {"type": "appStoreVersionLocalizations", "id": localization_id}}}}},
        token)
    set_id = created.get("data", {}).get("id")
    if not set_id:
        raise ASCError(f"could not create or find an appScreenshotSet for {display_type}")
    return set_id


def upload_screenshot(set_id: str, path: str, token: str) -> None:
    filename, size = os.path.basename(path), os.path.getsize(path)
    reservation = api_call("POST", "/v1/appScreenshots", {
        "data": {"type": "appScreenshots",
                 "attributes": {"fileName": filename, "fileSize": size},
                 "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}},
        token)
    shot = reservation.get("data", {})
    shot_id = shot.get("id")
    upload_ops = shot.get("attributes", {}).get("uploadOperations", [])
    if not shot_id or not upload_ops:
        raise ASCError(f"appScreenshots reservation for {filename} returned no uploadOperations")

    with open(path, "rb") as fh:
        raw = fh.read()
    for op in upload_ops:
        offset, length = op.get("offset", 0), op.get("length", len(raw))
        req = urllib.request.Request(op["url"], data=raw[offset:offset + length], method=op.get("method", "PUT"))
        for header in op.get("requestHeaders", []):
            req.add_header(header["name"], header["value"])
        with urllib.request.urlopen(req, timeout=300) as resp:
            if resp.status not in (200, 201, 204):
                raise ASCError(f"screenshot chunk upload for {filename} returned HTTP {resp.status}")

    api_call("PATCH", f"/v1/appScreenshots/{shot_id}", {
        "data": {"type": "appScreenshots", "id": shot_id,
                 "attributes": {"uploaded": True, "sourceFileChecksum": md5_of(path)}}}, token)
    log(f"  uploaded {filename}")


def push_screenshots(app: dict, asc_app_id: str, token: str, dry_run: bool) -> None:
    ios = load()["defaults"]["ios"]
    version_id = "dry-run" if dry_run else find_editable_version(
        asc_app_id, str((app.get("current_version") or {}).get("marketing_version") or ""), token)
    # Read the display type from the registry rather than hardcoding it here:
    # the registry already declares the required sets and their accepted pixel
    # sizes, and check_ios_app.py validates the images against exactly that.
    # A second, hardcoded copy is how this shipped APP_IPHONE_69 -- a value
    # that is not in Apple's enum at all -- past a passing quality gate.
    required = [cfg for cfg in ios["screenshot_sets"].values() if cfg.get("required")]
    if not required:
        raise ASCError("defaults.ios.screenshot_sets declares no required set")
    display_type = required[0]["display_type"]

    mapping = ios["screenshot_dir_to_asc_lang"]
    for folder, locale in mapping.items():
        shots_dir = os.path.join(ROOT, app["store_dir"], "screenshots", folder)
        if not os.path.isdir(shots_dir):
            continue
        files = sorted(f for f in os.listdir(shots_dir) if f.lower().endswith((".png", ".jpg", ".jpeg")))
        if not files:
            continue
        if dry_run:
            log(f"  [dry-run] {locale}: would upload {len(files)} screenshot(s)")
            continue
        loc_id = find_version_localization_id(version_id, locale, token)
        set_id = find_or_create_screenshot_set(loc_id, display_type, token)
        for name in files:
            upload_screenshot(set_id, os.path.join(shots_dir, name), token)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Push iOS store metadata and screenshots", add_help=True)
    p.add_argument("slug")
    p.add_argument("--what", choices=["text", "screenshots", "all"], default="all")
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args(argv)

    try:
        asc_app_id, app = resolve_app(a.slug)
        listing = load_listing(app) if a.what in ("text", "all") else []
        token = None if a.dry_run else make_token()

        if a.what in ("text", "all"):
            log(f"{a.slug}: pushing text metadata for {len(listing)} locale(s)"
               + (" (dry run)" if a.dry_run else ""))
            push_text(app, asc_app_id, listing, token, a.dry_run)
        if a.what in ("screenshots", "all"):
            log(f"{a.slug}: pushing screenshots" + (" (dry run)" if a.dry_run else ""))
            push_screenshots(app, asc_app_id, token, a.dry_run)
        return 0
    except ASCError as exc:
        log(f"error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
