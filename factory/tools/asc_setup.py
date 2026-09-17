#!/usr/bin/env python3
"""
App Factory - create the App Store Connect pieces a human used to click through.

  python factory/tools/asc_setup.py <slug> --what version|iap|all [--dry-run]

Two of PriceJar's three rejections, and most of the back-and-forth on ShiftSlip,
were coordination over the in-app purchase: it existed but was incomplete, or
complete but not submitted, or the review screenshot was missing. Creating the
version was another click that blocked the metadata push until it was done.
Every one of those is in the API. This tool does them, idempotently: it looks
up before it creates, so running it twice changes nothing.

Every path, verb, filter and relationship here was read from Apple's OpenAPI
specification (factory/tools/spec/) before it was written, and
test_asc_api_shapes.py re-checks them. Two lessons carried over from the
earlier tools: never rely on a `filter[...]` parameter to filter -- fetch and
match client-side -- and never report an upload as done until Apple's
assetDeliveryState says COMPLETE.

What this does NOT do, because the API cannot: the App Privacy questionnaire,
the age rating, the Paid Apps Agreement. Those stay in the console.

Inputs, all from the repo:
  factory/apps.json   iap.remove_ads_product_id, iap.price_usd, asc_app_id,
                      current_version.marketing_version
  store/listing.json  languages[].iap.name / .description  (30 / 45 chars)
  store/iap-review-screenshot.png
"""

from __future__ import annotations

import argparse
import os
import sys
import time
import urllib.request
from decimal import Decimal, InvalidOperation

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_client import ASCError, log, make_token, mask_in_ci, resolve_app, version_state  # noqa: E402
from asc_metadata import (  # noqa: E402
    ASSET_PENDING, EDITABLE_VERSION_STATES, api_call, asset_delivery_state, load_listing, md5_of)
from registry import ROOT  # noqa: E402

PLATFORM = "IOS"
BASE_TERRITORY = "USA"
IAP_REVIEW_SCREENSHOT = "iap-review-screenshot.png"


# --- version ------------------------------------------------------------------

def find_version(asc_app_id: str, marketing_version: str, token: str) -> str | None:
    # Client-side match. filter[versionString] exists in the spec, but the
    # screenshot-set filter also exists in the spec and Apple ignores it.
    rows = api_call("GET", f"/v1/apps/{asc_app_id}/appStoreVersions?limit=200", token=token).get("data") or []
    for row in rows:
        attrs = row.get("attributes") or {}
        if attrs.get("versionString") == marketing_version and attrs.get("platform", PLATFORM) == PLATFORM:
            return row["id"]
    return None


def find_editable_version(asc_app_id: str, token: str) -> tuple[str, str] | None:
    """(id, versionString) of the one version Apple lets us edit, if any."""
    rows = api_call("GET", f"/v1/apps/{asc_app_id}/appStoreVersions?limit=200", token=token).get("data") or []
    for row in rows:
        attrs = row.get("attributes") or {}
        if attrs.get("platform", PLATFORM) == PLATFORM and version_state(attrs) in EDITABLE_VERSION_STATES:
            return row["id"], str(attrs.get("versionString") or "")
    return None


def ensure_version(asc_app_id: str, marketing_version: str, token: str, dry_run: bool = False) -> str:
    """The appStoreVersion for the registry's marketing version, created if absent.

    Apple keeps at most one editable version per platform. When one exists under
    another version string -- PriceJar 1.0.0, pulled back out of a submission it
    was never sent in, with the registry already at 1.0.1 -- POST answers 409
    "You cannot create a new version of the App in the current state" and says
    nothing about why. versionString is a PATCHable attribute of an editable
    version (AppStoreVersionUpdateRequest in the spec), so that version is
    renamed rather than fought with: same id, same attached build, same listing.
    """
    existing = None if dry_run else find_version(asc_app_id, marketing_version, token)
    if existing:
        log(f"version {marketing_version} exists ({existing})")
        return existing
    editable = None if dry_run else find_editable_version(asc_app_id, token)
    if editable:
        version_id, current = editable
        api_call("PATCH", f"/v1/appStoreVersions/{version_id}", {
            "data": {"type": "appStoreVersions", "id": version_id,
                     "attributes": {"versionString": marketing_version}}}, token)
        log(f"renamed the editable appStoreVersion {current} -> {marketing_version} ({version_id}); "
            "Apple allows one editable version and refuses to create a second")
        return version_id
    if dry_run:
        log(f"[dry-run] would create appStoreVersion {marketing_version} ({PLATFORM}), or rename the "
            "editable one if Apple already holds one under another version string")
        return "dry-run"
    created = api_call("POST", "/v1/appStoreVersions", {
        "data": {"type": "appStoreVersions",
                 "attributes": {"versionString": marketing_version, "platform": PLATFORM},
                 "relationships": {"app": {"data": {"type": "apps", "id": asc_app_id}}}}}, token)
    version_id = (created.get("data") or {}).get("id")
    if not version_id:
        raise ASCError("appStoreVersions POST returned no id")
    log(f"created appStoreVersion {marketing_version} ({version_id})")
    return version_id


# --- in-app purchase ----------------------------------------------------------

def find_iap(asc_app_id: str, product_id: str, token: str) -> dict | None:
    rows = api_call("GET", f"/v1/apps/{asc_app_id}/inAppPurchasesV2?limit=200", token=token).get("data") or []
    for row in rows:
        if (row.get("attributes") or {}).get("productId") == product_id:
            return row
    return None


def ensure_iap(asc_app_id: str, product_id: str, reference_name: str, token: str) -> str:
    row = find_iap(asc_app_id, product_id, token)
    if row:
        log(f"in-app purchase {product_id} exists ({row['id']}, state {(row.get('attributes') or {}).get('state')})")
        return row["id"]
    created = api_call("POST", "/v2/inAppPurchases", {
        "data": {"type": "inAppPurchases",
                 "attributes": {"name": reference_name, "productId": product_id,
                                "inAppPurchaseType": "NON_CONSUMABLE"},
                 "relationships": {"app": {"data": {"type": "apps", "id": asc_app_id}}}}}, token)
    iap_id = (created.get("data") or {}).get("id")
    if not iap_id:
        raise ASCError("inAppPurchases POST returned no id")
    log(f"created in-app purchase {product_id} ({iap_id})")
    return iap_id


def ensure_iap_localizations(iap_id: str, listing: list[dict], token: str) -> None:
    """One localization per listing language, from listing.json's `iap` block."""
    existing = api_call("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations?limit=50", token=token).get("data") or []
    by_locale = {(r.get("attributes") or {}).get("locale"): r for r in existing}
    for entry in listing:
        locale, iap = entry.get("lang"), entry.get("iap") or {}
        name, description = (iap.get("name") or "").strip(), (iap.get("description") or "").strip()
        if not name:
            raise ASCError(f"listing.json has no iap.name for {locale}; the gate should have caught this")
        attrs = {"name": name, "description": description}
        row = by_locale.get(locale)
        if row:
            have = row.get("attributes") or {}
            if have.get("name") == name and (have.get("description") or "") == description:
                continue
            api_call("PATCH", f"/v1/inAppPurchaseLocalizations/{row['id']}", {
                "data": {"type": "inAppPurchaseLocalizations", "id": row["id"], "attributes": attrs}}, token)
            log(f"  updated localization {locale}")
        else:
            api_call("POST", "/v1/inAppPurchaseLocalizations", {
                "data": {"type": "inAppPurchaseLocalizations",
                         "attributes": {**attrs, "locale": locale},
                         "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}}}}, token)
            log(f"  created localization {locale}")


def _to_one(path: str, token: str) -> dict | None:
    """A to-one relationship, or None when Apple has nothing there (404)."""
    try:
        return (api_call("GET", path, token=token).get("data")) or None
    except ASCError as exc:
        if "HTTP 404" in str(exc):
            return None
        raise


def territory_ids(token: str) -> list[str]:
    rows = api_call("GET", "/v1/territories?limit=200", token=token).get("data") or []
    ids = [r["id"] for r in rows]
    if BASE_TERRITORY not in ids:
        raise ASCError(f"Apple's territory list has no {BASE_TERRITORY}; got {len(ids)} territories")
    return ids


def ensure_iap_availability(iap_id: str, token: str) -> None:
    if _to_one(f"/v2/inAppPurchases/{iap_id}/inAppPurchaseAvailability", token):
        return
    ids = territory_ids(token)
    api_call("POST", "/v1/inAppPurchaseAvailabilities", {
        "data": {"type": "inAppPurchaseAvailabilities",
                 "attributes": {"availableInNewTerritories": True},
                 "relationships": {
                     "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                     "availableTerritories": {"data": [{"type": "territories", "id": t} for t in ids]}}}}, token)
    log(f"  availability set: {len(ids)} territories, new ones included")


def price_point_for(iap_id: str, price_usd: str, token: str) -> str:
    """The USA price point whose customer price is the registry's price."""
    try:
        want = Decimal(price_usd)
    except InvalidOperation:
        raise ASCError(f"iap.price_usd must be a decimal like '2.99', got {price_usd!r}")
    rows = api_call("GET", f"/v2/inAppPurchases/{iap_id}/pricePoints?filter[territory]={BASE_TERRITORY}&limit=200",
                    token=token).get("data") or []
    candidates = []
    for row in rows:
        price = (row.get("attributes") or {}).get("customerPrice")
        try:
            if price is not None and Decimal(str(price)) == want:
                return row["id"]
            candidates.append(str(price))
        except InvalidOperation:
            continue
    raise ASCError(f"no {BASE_TERRITORY} price point at {want}; Apple offers e.g. "
                   f"{sorted(set(candidates), key=lambda s: Decimal(s))[:12]} ...")


def current_price(schedule_id: str, token: str) -> str | None:
    """What the existing schedule actually charges in the base territory."""
    rows = api_call("GET", f"/v1/inAppPurchasePriceSchedules/{schedule_id}/manualPrices"
                            f"?include=inAppPurchasePricePoint&limit=200", token=token)
    points = {row["id"]: (row.get("attributes") or {}).get("customerPrice")
              for row in (rows.get("included") or [])
              if row.get("type") == "inAppPurchasePricePoints"}
    for row in rows.get("data") or []:
        point = (((row.get("relationships") or {}).get("inAppPurchasePricePoint") or {})
                 .get("data") or {}).get("id")
        if point and points.get(point) is not None:
            return str(points[point])
    return None


def ensure_iap_price(iap_id: str, price_usd: str, token: str) -> None:
    existing = _to_one(f"/v2/inAppPurchases/{iap_id}/iapPriceSchedule", token)
    if existing:
        # Returning silently here was the bug: Apple attaches a schedule to a
        # new purchase on its own, so this branch is the normal one, and the
        # step reported nothing while the price was whatever Apple had picked.
        # A price is the one thing about a purchase the owner actually decided.
        schedule_id = existing.get("id")
        charged = current_price(schedule_id, token) if schedule_id else None
        if charged is None:
            log(f"  price schedule {schedule_id} exists but reports no price; check it in App Store Connect")
            return
        if Decimal(charged) == Decimal(price_usd):
            log(f"  price schedule already set: {charged} USD base, as the registry says")
            return
        raise ASCError(
            f"the price schedule charges {charged} USD in {BASE_TERRITORY} and the registry says "
            f"{price_usd}. Apple does not allow replacing a schedule from the API -- change the "
            f"price in App Store Connect, or change iap.price_usd to match what is there.")
    point = price_point_for(iap_id, price_usd, token)
    api_call("POST", "/v1/inAppPurchasePriceSchedules", {
        "data": {"type": "inAppPurchasePriceSchedules",
                 "relationships": {
                     "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                     "baseTerritory": {"data": {"type": "territories", "id": BASE_TERRITORY}},
                     "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${price}"}]}}},
        "included": [{"type": "inAppPurchasePrices", "id": "${price}",
                      "attributes": {"startDate": None},
                      "relationships": {
                          "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}},
                          "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": point}}}}]},
        token)
    log(f"  price schedule set: {price_usd} USD base, other territories equalised by Apple")


def ensure_iap_review_screenshot(iap_id: str, path: str, token: str, timeout: int = 120) -> None:
    if _to_one(f"/v2/inAppPurchases/{iap_id}/appStoreReviewScreenshot", token):
        return
    if not os.path.isfile(path):
        raise ASCError(f"{os.path.relpath(path, ROOT)} is missing; the screenshot test produces it as "
                       f"06-settings-iap, commit it there")
    filename, size = os.path.basename(path), os.path.getsize(path)
    reserved = api_call("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", {
        "data": {"type": "inAppPurchaseAppStoreReviewScreenshots",
                 "attributes": {"fileName": filename, "fileSize": size},
                 "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}}}}, token)
    shot = reserved.get("data") or {}
    shot_id, ops = shot.get("id"), (shot.get("attributes") or {}).get("uploadOperations") or []
    if not shot_id or not ops:
        raise ASCError("review screenshot reservation returned no uploadOperations")
    with open(path, "rb") as fh:
        raw = fh.read()
    for op in ops:
        offset, length = op.get("offset", 0), op.get("length", len(raw))
        req = urllib.request.Request(op["url"], data=raw[offset:offset + length], method=op.get("method", "PUT"))
        for header in op.get("requestHeaders", []):
            req.add_header(header["name"], header["value"])
        with urllib.request.urlopen(req, timeout=300) as resp:
            if resp.status not in (200, 201, 204):
                raise ASCError(f"review screenshot chunk upload returned HTTP {resp.status}")
    api_call("PATCH", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{shot_id}", {
        "data": {"type": "inAppPurchaseAppStoreReviewScreenshots", "id": shot_id,
                 "attributes": {"uploaded": True, "sourceFileChecksum": md5_of(path)}}}, token)
    # Same rule as the store screenshots: Apple validates afterwards, and a
    # 200 here said nothing about whether the image was accepted.
    deadline, state = time.time() + timeout, "unknown"
    while time.time() < deadline:
        data = api_call("GET", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{shot_id}", token=token)
        delivery = asset_delivery_state((data.get("data") or {}).get("attributes") or {})
        state, errors = delivery.get("state", "unknown"), delivery.get("errors") or []
        if errors:
            raise ASCError(f"{filename}: Apple rejected the review screenshot ({state}): {errors}")
        if state == "COMPLETE":
            log(f"  review screenshot uploaded and accepted ({filename})")
            return
        if state not in ASSET_PENDING:
            raise ASCError(f"{filename}: review screenshot left in state {state}")
        time.sleep(2)
    raise ASCError(f"{filename}: still {state} after {timeout}s")


def setup_iap(app: dict, asc_app_id: str, token: str, dry_run: bool) -> None:
    iap_cfg = app.get("iap") or {}
    product_id = str(iap_cfg.get("remove_ads_product_id") or "")
    price_usd = str(iap_cfg.get("price_usd") or "")
    if not product_id:
        log("no iap.remove_ads_product_id in the registry; nothing to set up")
        return
    if not price_usd:
        raise ASCError("registry has iap.remove_ads_product_id but no iap.price_usd (e.g. \"2.99\")")
    listing = load_listing(app)
    screenshot = os.path.join(ROOT, app["store_dir"], IAP_REVIEW_SCREENSHOT)
    if dry_run:
        log(f"[dry-run] would ensure {product_id} (NON_CONSUMABLE, {price_usd} USD) with "
            f"{len(listing)} localization(s), availability in all territories, and "
            f"{os.path.relpath(screenshot, ROOT)} as the review screenshot")
        return
    iap_id = ensure_iap(asc_app_id, product_id, "Remove Ads", token)
    ensure_iap_localizations(iap_id, listing, token)
    ensure_iap_availability(iap_id, token)
    ensure_iap_price(iap_id, price_usd, token)
    ensure_iap_review_screenshot(iap_id, screenshot, token)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Create the App Store Connect version and in-app purchase", add_help=True)
    p.add_argument("slug")
    p.add_argument("--what", choices=["version", "iap", "all"], default="all")
    p.add_argument("--dry-run", action="store_true")
    a = p.parse_args(argv)
    try:
        asc_app_id, app = resolve_app(a.slug)
        marketing_version = str((app.get("current_version") or {}).get("marketing_version") or "")
        if not marketing_version:
            raise ASCError(f"registry entry for {a.slug} has no current_version.marketing_version")
        token = None if a.dry_run else make_token()
        if not a.dry_run:
            mask_in_ci(os.environ.get("ASC_ISSUER_ID", ""))
        if a.what in ("version", "all"):
            ensure_version(asc_app_id, marketing_version, token, a.dry_run)
        if a.what in ("iap", "all"):
            setup_iap(app, asc_app_id, token, a.dry_run)
        return 0
    except ASCError as exc:
        log(f"error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
