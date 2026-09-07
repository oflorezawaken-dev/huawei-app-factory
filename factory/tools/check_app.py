#!/usr/bin/env python3
"""
Huawei App Factory - quality gate. Checks an app against the factory rules
before it is allowed to build, upload, or submit.

  python factory/tools/check_app.py receipt-lens
  python factory/tools/check_app.py receipt-lens --strict   # known_gaps no longer excuse failures

Exit codes: 0 all good (or only excused gaps), 1 failures.

Rules (from factory/apps.json defaults.rules plus store-readiness basics):
  petal_ads        Huawei Maven repo + com.huawei.hms:ads* dependency really present in Gradle
  no_stubs         no Class.forName("com.huawei...") reflection stand-ins for SDKs
  forbidden_deps   no Firebase / GMS / Google AI dependencies
  identity         applicationId in Gradle matches the registry package
  internet_perm    INTERNET permission declared when ads are required
  ad_unit_ids      real Petal Ads unit IDs present in the registry (else builds use test units)
  store_icon       store/icon/icon-512.png exists and is 512x512
  store_shots      at least 3 PNG screenshots for the default language
  store_listing    listing.json covers every registry language
  privacy_page     privacy_path/index.html exists
  privacy_tags     store/privacy-tags.json exists, uses official AppGallery labels, declares the
                   Petal Ads items and one item per data permission in the manifest
  spec             spec file exists

A failure listed in the app's "known_gaps" is reported as EXCUSED (not fatal)
unless --strict is given, so the registry documents the gap honestly instead
of the check being silently skipped.
"""

from __future__ import annotations

import json
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from registry import find, load  # noqa: E402
from privacy_tags import validate as validate_privacy_tags  # noqa: E402


def read(path: str) -> str:
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def gradle_files(app_path: str) -> list[str]:
    out = []
    for dirpath, _dirs, files in os.walk(os.path.join(ROOT, app_path)):
        if "/build/" in dirpath.replace("\\", "/") or "/.gradle" in dirpath.replace("\\", "/"):
            continue
        for f in files:
            if f.endswith((".gradle.kts", ".gradle", ".toml")):
                out.append(os.path.join(dirpath, f))
    return out


def kotlin_files(app_path: str) -> list[str]:
    out = []
    for dirpath, _dirs, files in os.walk(os.path.join(ROOT, app_path, "app", "src", "main")):
        for f in files:
            if f.endswith((".kt", ".java")):
                out.append(os.path.join(dirpath, f))
    return out


def png_size(path: str) -> tuple[int, int] | None:
    with open(path, "rb") as fh:
        head = fh.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w, h = struct.unpack(">II", head[16:24])
    return w, h


def main(argv: list[str]) -> int:
    if not argv:
        sys.exit(__doc__)
    slug = argv[0]
    strict = "--strict" in argv
    app = find(slug)
    reg = load()
    rules = reg["defaults"]["rules"]
    languages = reg["defaults"]["languages"]
    known_gaps = app.get("known_gaps") or {}

    results: list[tuple[str, str, str]] = []  # (rule, status, detail)

    def report(rule: str, ok: bool, detail: str, gap_key: str | None = None) -> None:
        if ok:
            results.append((rule, "PASS", detail))
        elif gap_key and gap_key in known_gaps and not strict:
            results.append((rule, "EXCUSED", f"{detail} - known gap: {known_gaps[gap_key]}"))
        else:
            results.append((rule, "FAIL", detail))

    gradle_text = "\n".join(read(f) for f in gradle_files(app["path"]))
    kotlin_text = "\n".join(read(f) for f in kotlin_files(app["path"]))
    manifest_path = os.path.join(ROOT, app["path"], "app", "src", "main", "AndroidManifest.xml")
    manifest = read(manifest_path) if os.path.isfile(manifest_path) else ""

    # petal_ads
    if rules.get("petal_ads_required"):
        has_repo = "developer.huawei.com/repo" in gradle_text
        has_dep = re.search(r"com\.huawei\.hms[:\"']\s*[:\"']?\s*ads", gradle_text) is not None or \
                  re.search(r'group\s*=\s*"com\.huawei\.hms"\s*,\s*name\s*=\s*"ads', gradle_text) is not None
        report("petal_ads", has_repo and has_dep,
               f"Huawei Maven repo: {has_repo}, Petal Ads dependency: {has_dep}", gap_key="petal_ads")
        report("internet_perm", "android.permission.INTERNET" in manifest,
               "INTERNET permission declared (required by the ads SDK)", gap_key="petal_ads")

        ads_cfg = app.get("ads") or {}
        have_ids = bool(ads_cfg.get("banner_ad_id")) and bool(ads_cfg.get("interstitial_ad_id"))
        report("ad_unit_ids", have_ids, "real Petal Ads unit IDs present in factory/apps.json", gap_key="ad_unit_ids")

    # no_stubs
    if rules.get("no_reflection_sdk_stubs"):
        stubs = re.findall(r'Class\.forName\("(com\.huawei[^"]*)"\)', kotlin_text)
        report("no_stubs", not stubs, f"reflection SDK stubs: {sorted(set(stubs)) or 'none'}",
               gap_key="petal_ads" if any("ads" in s for s in stubs) else "ml_kit_ocr")

    # forbidden_deps
    bad = [d for d in rules.get("forbidden_dependencies", []) if d in gradle_text]
    report("forbidden_deps", not bad, f"forbidden dependencies present: {bad or 'none'}")

    # identity
    m = re.search(r'applicationId\s*=\s*"([^"]+)"', gradle_text)
    report("identity", bool(m) and m.group(1) == app["package"],
           f"applicationId={m.group(1) if m else 'MISSING'} registry={app['package']}")

    # store_icon
    icon = os.path.join(ROOT, app["store_dir"], "icon", "icon-512.png")
    size = png_size(icon) if os.path.isfile(icon) else None
    report("store_icon", size == (512, 512), f"{os.path.relpath(icon, ROOT)} size={size}")

    # store_shots (default language folder = first key of mapping whose value is languages[0])
    mapping = reg["defaults"]["screenshot_dir_to_agc_lang"]
    default_folder = next((k for k, v in mapping.items() if v == languages[0]), "en")
    shots_dir = os.path.join(ROOT, app["store_dir"], "screenshots", default_folder)
    shots = [f for f in os.listdir(shots_dir)] if os.path.isdir(shots_dir) else []
    shots = [f for f in shots if f.lower().endswith(".png")]
    report("store_shots", len(shots) >= 3, f"{len(shots)} PNG screenshots in {os.path.relpath(shots_dir, ROOT)}")

    # store_listing
    listing_path = os.path.join(ROOT, app["store_dir"], "listing.json")
    if os.path.isfile(listing_path):
        entries = json.loads(read(listing_path)).get("languages", [])
        have = {e.get("lang") for e in entries}
        missing = [l for l in languages if l not in have]
        too_long = [e.get("lang") for e in entries if len(e.get("briefInfo", "")) > 80]
        bad_notes = [e.get("lang") for e in entries if e.get("newFeatures") is not None and not (10 <= len(e["newFeatures"]) <= 300)]
        report("store_listing", not (missing or too_long or bad_notes),
               f"missing: {missing or 'none'}; briefInfo>80: {too_long or 'none'}; newFeatures out of 10-300: {bad_notes or 'none'}")
    else:
        report("store_listing", False, "listing.json missing")

    # privacy_page
    privacy = os.path.join(ROOT, app["privacy_path"], "index.html")
    report("privacy_page", os.path.isfile(privacy), os.path.relpath(privacy, ROOT))

    # privacy_tags (AppGallery personal-data declaration; ReceiptLens 1.0 was rejected without it)
    tags_ok, tags_problems = validate_privacy_tags(app, rules)
    report("privacy_tags", tags_ok,
           "store/privacy-tags.json consistent with manifest + Petal Ads" if tags_ok else "; ".join(tags_problems),
           gap_key="privacy_tags")

    # spec
    report("spec", os.path.isfile(os.path.join(ROOT, app["spec"])), app["spec"])

    width = max(len(r[0]) for r in results)
    failures = 0
    for rule, status, detail in results:
        print(f"[{status:7}] {rule.ljust(width)}  {detail}")
        if status == "FAIL":
            failures += 1
    print(f"\n{slug}: {failures} failure(s)" + (" (strict)" if strict else ""))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
