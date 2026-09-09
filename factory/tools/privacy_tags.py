#!/usr/bin/env python3
"""
Huawei App Factory - AppGallery privacy tags (personal-data declaration).

AppGallery rejects a release when the app (or an SDK inside it) collects personal
data and the "Privacy tags" area of Version information says otherwise. ReceiptLens
1.0.0 was rejected for exactly this on 2026-09-07. Every factory app ships Huawei
Petal Ads, so every factory app collects personal data and must declare it.

The Publishing API has no endpoint for privacy tags (checked against the official
reference and two maintained clients), so the declaration is written once here,
validated by the quality gate, and rendered as a click-by-click checklist that a
human copies into AppGallery Connect > the app > Version information > Privacy tags.

  python factory/tools/privacy_tags.py init <slug>      # write store/privacy-tags.json (baseline, no overwrite)
  python factory/tools/privacy_tags.py check <slug>     # validate against manifest + taxonomy; exit 1 on problems
  python factory/tools/privacy_tags.py render <slug>    # print the console checklist (Markdown)
  python factory/tools/privacy_tags.py render <slug> --write   # also save store/privacy-tags.md
  python factory/tools/privacy_tags.py taxonomy         # print the official categories and items

Taxonomy source: "AppGallery Privacy Tag Service Description"
https://developer.huawei.com/consumer/en/doc/app/privacy-label (12 categories, 91 items,
7 service scenarios). Item names below must match the console labels exactly.
Petal Ads data items come from the "Statement About Petal Ads and Privacy".
"""

from __future__ import annotations

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from registry import find, load  # noqa: E402

SCENARIOS = [
    "App functionality",
    "Product personalization",
    "Analytics",
    "Advertising and marketing",
    "Disclosure to third parties",
    "Cross-border transfer",
    "Others",
]

TAXONOMY: dict[str, list[str]] = {
    "Contact information": ["Contact list", "Social media accounts", "Other contact information"],
    "Fitness and health information": ["Fitness information", "Heart rate", "Blood pressure", "Other health information"],
    "Financial information": ["Bank account information", "Other financial account information", "Asset information",
                              "Other financial information"],
    "Transaction information": ["Transaction records", "Order information", "Package delivery information",
                                "Other transaction information"],
    "Location information": ["GPS location", "Network location", "Other precise location information",
                             "Other approximate location information"],
    "Special category data": ["Fingerprint information", "Voiceprint information", "Facial recognition features",
                              "Other biometric features", "Other special category data"],
    "Identifiers": ["User identifiers", "ID card", "OAID", "ODID", "SSID", "BSSID", "ICCID", "SN", "IMEI", "IMSI", "MAC",
                    "MEID", "Chip ID", "Other identity information", "Other device identifiers"],
    "Basic information": ["Name", "Gender", "Age", "Date of birth", "Account information", "Education information",
                          "Work information", "Home information", "Address", "Phone number", "Email address",
                          "Calendar and schedule", "Other personal information"],
    "User information": ["Image or video", "Audio", "Text information", "Search keywords", "Social interactions",
                         "Game statistics", "Customer service records", "Pasteboard", "Audio recording", "SMS messages",
                         "Call logs", "Other communication content", "Software installation list", "Other user content"],
    "App information": ["Browsing history", "Favorites", "Basic app information", "App run logs", "App settings",
                        "App running status", "App usage information"],
    "Device information": ["Magnetometer", "Screen orientation sensor", "Gravity sensor", "OS information", "Device status",
                           "Gyroscope", "Acceleration sensor", "Wi-Fi parameters", "Wi-Fi status", "Network type", "Carrier",
                           "IP address", "Light sensor", "Barometer", "Rotation vector sensor",
                           "Other hardware and software parameters/System settings", "Other device information"],
    "Other data": ["Other personal data"],
}

# What the Petal Ads SDK collects in an app that grants it no extra permissions
# (no location, no Wi-Fi state, no phone state). Source: Petal Ads privacy statement:
# advertising identifier (OAID), device brand/model/OS/settings/battery/storage,
# IP address (used for city/country-level location), network type, carrier,
# app package/version, ad events (impressions, clicks, positions), sensor data for
# fraud detection. Advertisers receive OAID, device/network info and ad events.
PETAL_ADS_ITEMS: dict[str, dict[str, list[str]]] = {
    "Advertising and marketing": {
        "Identifiers": ["OAID"],
        "Location information": ["Other approximate location information"],
        "App information": ["Basic app information", "App usage information"],
        "Device information": ["OS information", "Device status", "Network type", "Carrier", "IP address",
                               "Acceleration sensor", "Gyroscope",
                               "Other hardware and software parameters/System settings"],
    },
    "Disclosure to third parties": {
        "Identifiers": ["OAID"],
        "App information": ["App usage information"],
        "Device information": ["OS information", "Network type", "Carrier", "IP address",
                               "Other hardware and software parameters/System settings"],
    },
}

# Android permission -> (category, item) the app must declare (usually under "App functionality").
PERMISSION_ITEMS: dict[str, list[tuple[str, str]]] = {
    "android.permission.CAMERA": [("User information", "Image or video")],
    "android.permission.READ_MEDIA_IMAGES": [("User information", "Image or video")],
    "android.permission.READ_MEDIA_VIDEO": [("User information", "Image or video")],
    "android.permission.READ_EXTERNAL_STORAGE": [("User information", "Other user content")],
    "android.permission.RECORD_AUDIO": [("User information", "Audio recording")],
    "android.permission.READ_MEDIA_AUDIO": [("User information", "Audio")],
    "android.permission.ACCESS_FINE_LOCATION": [("Location information", "GPS location")],
    "android.permission.ACCESS_COARSE_LOCATION": [("Location information", "Other approximate location information")],
    "android.permission.READ_CONTACTS": [("Contact information", "Contact list")],
    "android.permission.READ_CALENDAR": [("Basic information", "Calendar and schedule")],
    "android.permission.READ_SMS": [("User information", "SMS messages")],
    "android.permission.READ_CALL_LOG": [("User information", "Call logs")],
    "android.permission.BODY_SENSORS": [("Fitness and health information", "Heart rate")],
    "android.permission.ACTIVITY_RECOGNITION": [("Fitness and health information", "Fitness information")],
    "android.permission.QUERY_ALL_PACKAGES": [("User information", "Software installation list")],
    "android.permission.ACCESS_WIFI_STATE": [("Identifiers", "SSID"), ("Identifiers", "BSSID")],
    "android.permission.READ_PHONE_STATE": [("Identifiers", "IMEI"), ("Identifiers", "IMSI")],
}

ITEM_TO_CATEGORY = {item: cat for cat, items in TAXONOMY.items() for item in items}

# Default "why" text for the checklist. Apps override or extend these in item_notes.
DEFAULT_NOTES: dict[str, str] = {
    "Image or video": "Photos are stored in app-private storage on the device only.",
    "OAID": "Read by the Huawei Petal Ads SDK for ad delivery and measurement.",
    "Other approximate location information": "Petal Ads derives city/country from the IP address.",
    "Basic app information": "Package name and version sent by the Petal Ads SDK with ad requests.",
    "App usage information": "Ad events (impressions, clicks) reported by the Petal Ads SDK.",
    "OS information": "Petal Ads SDK: Android/EMUI version for ad delivery.",
    "Device status": "Petal Ads SDK: battery and storage status.",
    "Network type": "Petal Ads SDK: Wi-Fi or mobile network type.",
    "Carrier": "Petal Ads SDK: carrier information.",
    "IP address": "Petal Ads SDK: network address of each ad request.",
    "Acceleration sensor": "Petal Ads SDK: motion data used for ad-fraud detection.",
    "Gyroscope": "Petal Ads SDK: motion data used for ad-fraud detection.",
    "Other hardware and software parameters/System settings":
        "Petal Ads SDK: device brand/model, screen resolution, language, region.",
}


def tags_path(app: dict) -> str:
    return os.path.join(ROOT, app["store_dir"], "privacy-tags.json")


def manifest_permissions(app: dict) -> list[str]:
    path = os.path.join(ROOT, app["path"], "app", "src", "main", "AndroidManifest.xml")
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8") as fh:
        return re.findall(r'<uses-permission[^>]*android:name="([^"]+)"', fh.read())


def baseline(app: dict, rules: dict) -> dict:
    scenarios: dict[str, dict[str, list[str]]] = {"App functionality": {}}
    for perm in manifest_permissions(app):
        for cat, item in PERMISSION_ITEMS.get(perm, []):
            scenarios["App functionality"].setdefault(cat, [])
            if item not in scenarios["App functionality"][cat]:
                scenarios["App functionality"][cat].append(item)
    if rules.get("petal_ads_required"):
        for scen, cats in PETAL_ADS_ITEMS.items():
            scenarios[scen] = {c: list(items) for c, items in cats.items()}
    return {
        "_doc": "AppGallery privacy tags for this app. Labels are the exact console names from "
                "https://developer.huawei.com/consumer/en/doc/app/privacy-label . Baseline generated from the "
                "manifest permissions plus the mandatory Petal Ads block; add the app-specific items the code really "
                "stores or processes (e.g. Transaction records for receipts). Validate with: "
                "python factory/tools/privacy_tags.py check <slug>",
        "collect_personal_data": True,
        "scenarios": scenarios,
        "not_applicable": {
            "Product personalization": "No user profiling; ad personalisation belongs to the Petal Ads scenario.",
            "Analytics": "No analytics or crash-reporting SDK.",
            "Cross-border transfer": "Scenario means data sent outside the Chinese mainland; the app is not "
                                     "distributed in the Chinese mainland.",
            "Others": "",
        },
        "item_notes": {item: note for item, note in DEFAULT_NOTES.items()
                       if any(item in items for cats in scenarios.values() for items in cats.values())},
    }


def validate(app: dict, rules: dict) -> tuple[bool, list[str]]:
    """Return (ok, problems)."""
    problems: list[str] = []
    path = tags_path(app)
    if not os.path.isfile(path):
        return False, [f"{os.path.relpath(path, ROOT)} missing (run: python factory/tools/privacy_tags.py init {app['slug']})"]
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    scenarios = data.get("scenarios") or {}
    if data.get("collect_personal_data") is not True:
        if rules.get("petal_ads_required") or scenarios:
            problems.append("collect_personal_data must be true (Petal Ads collects OAID/device data)")
    for scen, cats in scenarios.items():
        if scen not in SCENARIOS:
            problems.append(f"unknown scenario '{scen}'")
            continue
        for cat, items in cats.items():
            if cat not in TAXONOMY:
                problems.append(f"{scen}: unknown category '{cat}'")
                continue
            for item in items:
                if item not in TAXONOMY[cat]:
                    hint = ITEM_TO_CATEGORY.get(item)
                    problems.append(f"{scen} > {cat}: unknown item '{item}'" + (f" (belongs to '{hint}')" if hint else ""))
    declared = {(cat, item) for cats in scenarios.values() for cat, items in cats.items() for item in items}
    if rules.get("petal_ads_required"):
        for scen, cats in PETAL_ADS_ITEMS.items():
            have = scenarios.get(scen) or {}
            for cat, items in cats.items():
                missing = [i for i in items if i not in (have.get(cat) or [])]
                if missing:
                    problems.append(f"{scen} > {cat}: Petal Ads items missing: {missing}")
    for perm in manifest_permissions(app):
        for cat, item in PERMISSION_ITEMS.get(perm, []):
            if (cat, item) not in declared:
                problems.append(f"manifest declares {perm} but '{item}' ({cat}) is not declared in any scenario")
    return not problems, problems


def render(app: dict) -> str:
    path = tags_path(app)
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    scenarios = data.get("scenarios") or {}
    notes = {**DEFAULT_NOTES, **(data.get("item_notes") or {})}
    rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
    # A scenario with zero items (e.g. "App functionality" for an app with no data
    # items of its own beyond Petal Ads) must not be selected in the console --
    # selecting it with nothing ticked is meaningless and confusing.
    populated = [s for s in SCENARIOS if s in scenarios and any(scenarios[s].values())]
    empty_selected = [s for s in SCENARIOS if s in scenarios and s not in populated]
    lines = [
        f"# AppGallery privacy tags checklist: {app['name']} ({app['slug']})",
        "",
        "Console path: **AppGallery Connect > Apps and atomic services > "
        f"{app['name']} > Version information > Privacy tags**",
        "",
        f"Generated from `{rel}`. Labels are the official English console names; a localized console "
        "translates them but keeps the same order and grouping.",
        "",
        f"1. **Collect personal data** -> **{'Yes' if data.get('collect_personal_data') else 'No'}**",
        "2. Select these service scenarios: " + ", ".join(f"**{s}**" for s in populated),
        "3. On each scenario tab, tick exactly these data items:",
        "",
    ]
    for scen in SCENARIOS:
        if scen not in populated:
            continue
        lines.append(f"## {scen}")
        lines.append("")
        lines.append("| Data category | Data item | Why |")
        lines.append("|---|---|---|")
        for cat in TAXONOMY:
            for item in scenarios[scen].get(cat, []):
                lines.append(f"| {cat} | {item} | {notes.get(item, '')} |")
        lines.append("")
    na = {k: v for k, v in (data.get("not_applicable") or {}).items() if k not in populated}
    for scen in empty_selected:
        na.setdefault(scen, "This app has no data items of its own for this scenario beyond the mandatory Petal Ads block, which is declared under Advertising and marketing / Disclosure to third parties instead.")
    if na:
        lines.append("## Scenarios left unselected")
        lines.append("")
        for scen in SCENARIOS:
            if scen in na:
                lines.append(f"- **{scen}**: {na[scen] or 'not applicable'}")
        lines.append("")
    lines.append("4. Open the **Summary** tab and compare it with the tables above, then save.")
    lines.append(f"5. Record the date in `factory/apps.json` -> `{app['slug']}.privacy_tags_configured` "
                 "(the publish workflow refuses `submit_for_review` while it is empty).")
    lines.append("")
    lines.append("Keep this file, the privacy policy page and the manifest in sync: a new permission or SDK "
                 "means a new item here and in the policy. Reference: "
                 "https://developer.huawei.com/consumer/en/doc/app/privacy-label")
    return "\n".join(lines) + "\n"


def main(argv: list[str]) -> int:
    if not argv:
        sys.exit(__doc__)
    cmd = argv[0]
    if cmd == "taxonomy":
        print(f"Scenarios ({len(SCENARIOS)}): " + "; ".join(SCENARIOS))
        total = 0
        for cat, items in TAXONOMY.items():
            total += len(items)
            print(f"\n{cat} ({len(items)})")
            for i in items:
                print(f"  - {i}")
        print(f"\n{len(TAXONOMY)} categories, {total} items")
        return 0
    if len(argv) < 2:
        sys.exit(__doc__)
    app = find(argv[1])
    rules = load()["defaults"]["rules"]
    if cmd == "init":
        path = tags_path(app)
        if os.path.isfile(path) and "--force" not in argv:
            print(f"{os.path.relpath(path, ROOT)} exists; use --force to overwrite")
            return 1
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(baseline(app, rules), fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        print(f"wrote {os.path.relpath(path, ROOT)} (baseline: manifest permissions + Petal Ads). "
              "Add the app-specific items, then run: check")
        return 0
    if cmd == "check":
        ok, problems = validate(app, rules)
        for p in problems:
            print(f"  - {p}")
        print(f"privacy tags {app['slug']}: {'OK' if ok else str(len(problems)) + ' problem(s)'}")
        return 0 if ok else 1
    if cmd == "render":
        ok, problems = validate(app, rules)
        if not ok:
            for p in problems:
                print(f"  - {p}", file=sys.stderr)
            return 1
        text = render(app)
        if "--write" in argv:
            out = os.path.join(ROOT, app["store_dir"], "privacy-tags.md")
            with open(out, "w", encoding="utf-8") as fh:
                fh.write(text)
            print(f"wrote {os.path.relpath(out, ROOT)}")
        else:
            print(text)
        return 0
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
