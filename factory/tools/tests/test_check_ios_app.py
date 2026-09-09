#!/usr/bin/env python3
"""
Exercise factory/tools/check_ios_app.py against a throwaway fixture tree.

  python factory/tools/tests/test_check_ios_app.py

Builds a complete, passing iOS app under a temp FACTORY_ROOT, asserts the gate
reports zero failures, then breaks one rule at a time and asserts that exactly
that rule flips to FAIL. Standard library only; no Xcode and no network.
"""

from __future__ import annotations

import json
import os
import plistlib
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
REAL_ROOT = os.path.dirname(os.path.dirname(TOOLS))
CHECKER = os.path.join(TOOLS, "check_ios_app.py")

SLUG = "fixture-app"
BUNDLE_ID = "com.example.fixture"
PRODUCT_ID = "com.example.fixture.removeads"


def write(path: str, text: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


def write_plist(path: str, data: dict) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as fh:
        plistlib.dump(data, fh)


def write_png(path: str, width: int, height: int, alpha: bool = False) -> None:
    """A real, valid PNG of solid black - enough for header and alpha checks."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    color_type, channels = (6, 4) if alpha else (2, 3)
    raw = (b"\x00" + b"\x00" * (width * channels)) * height

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + tag + payload
                + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, color_type, 0, 0, 0)
    with open(path, "wb") as fh:
        fh.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                 + chunk(b"IDAT", zlib.compress(raw, 1)) + chunk(b"IEND", b""))


def registry(**app_overrides) -> dict:
    with open(os.path.join(REAL_ROOT, "factory", "apps.json"), encoding="utf-8") as fh:
        real = json.load(fh)
    app = {
        "slug": SLUG,
        "platform": "ios",
        "name": "Fixture",
        "path": f"apps-ios/{SLUG}",
        "bundle_id": BUNDLE_ID,
        "asc_app_id": "1234567890",
        "sku": SLUG,
        "team_id": "ABCDE12345",
        "min_ios": "17.0",
        "spec": f"specifications/{SLUG}.json",
        "store_dir": f"apps-ios/{SLUG}/store",
        "privacy_path": f"docs/{SLUG}/privacy",
        "support_path": f"docs/{SLUG}/support",
        "status": "planned",
        "current_version": {"marketing_version": "1.0.0", "build": 1},
        "admob": {
            "app_id": "ca-app-pub-1111111111111111~2222222222",
            "banner_unit_id": "ca-app-pub-1111111111111111/3333333333",
            "interstitial_unit_id": "ca-app-pub-1111111111111111/4444444444",
        },
        "iap": {"remove_ads_product_id": PRODUCT_ID},
        "known_gaps": {},
    }
    app.update(app_overrides)
    # Only the iOS defaults matter here; keep the real ones so the test tracks them.
    return {"defaults": real["defaults"], "apps": [app]}


def build_fixture(root: str, **app_overrides) -> None:
    reg = registry(**app_overrides)
    ios = reg["defaults"]["ios"]
    write(os.path.join(root, "factory", "apps.json"), json.dumps(reg, indent=2))
    app_dir = os.path.join(root, "apps-ios", SLUG)

    write(os.path.join(app_dir, "project.yml"), f"""
name: Fixture
options:
  bundleIdPrefix: com.example
packages:
  GoogleMobileAds:
    url: https://github.com/googleads/swift-package-manager-google-mobile-ads
    from: 12.0.0
targets:
  Fixture:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: {BUNDLE_ID}
        MARKETING_VERSION: 1.0.0
        CURRENT_PROJECT_VERSION: 1
    dependencies:
      - package: GoogleMobileAds
  FixtureTests:
    type: bundle.unit-test
    platform: iOS
    sources: [Tests]
""".lstrip())

    write(os.path.join(app_dir, "Config", "AdMob.xcconfig"),
          "ADMOB_APP_ID = ca-app-pub-1111111111111111~2222222222\n"
          "IAP_REMOVE_ADS_PRODUCT_ID = " + PRODUCT_ID + "\n")

    write_plist(os.path.join(app_dir, "Sources", "Info.plist"), {
        "GADApplicationIdentifier": "$(ADMOB_APP_ID)",
        "SKAdNetworkItems": [{"SKAdNetworkIdentifier": "cstr6suwn9.skadnetwork"}],
        "ITSAppUsesNonExemptEncryption": False,
        "NSUserTrackingUsageDescription":
            "PlantCue uses your device identifier to show ads relevant to gardening "
            "instead of repeating the same generic ones.",
        "NSCameraUsageDescription":
            "PlantCue opens the camera so you can attach a photo of a plant to its care reminder.",
    })

    write_plist(os.path.join(app_dir, "Sources", "PrivacyInfo.xcprivacy"), {
        "NSPrivacyTracking": True,
        "NSPrivacyCollectedDataTypes": [{
            "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeDeviceID",
            "NSPrivacyCollectedDataTypeLinked": False,
            "NSPrivacyCollectedDataTypeTracking": True,
            "NSPrivacyCollectedDataTypePurposes": ["NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising"],
        }],
        "NSPrivacyAccessedAPITypes": [{
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
        }],
    })

    write(os.path.join(app_dir, "Sources", "AdsManager.swift"), f"""
import AppTrackingTransparency
import GoogleMobileAds
import StoreKit

enum Monetisation {{
    static let removeAdsProductID = "{PRODUCT_ID}"

    static func requestTracking() async {{
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }}
}}
""".lstrip())

    write(os.path.join(app_dir, "Tests", "MonetisationTests.swift"), """
import XCTest
@testable import Fixture

final class MonetisationTests: XCTestCase {
    func testProductIDIsSet() {
        XCTAssertFalse(Monetisation.removeAdsProductID.isEmpty)
    }
}
""".lstrip())

    write_png(os.path.join(app_dir, "Sources", "Assets.xcassets", "AppIcon.appiconset", "icon-1024.png"),
              1024, 1024, alpha=False)

    # One image per required set, in the same folder: the gate routes by pixel
    # size, so iPhone and iPad screenshots live side by side per locale.
    shots = os.path.join(app_dir, "store", "screenshots", "en")
    for i in range(1, 4):
        write_png(os.path.join(shots, f"{i:02d}.png"), 1320, 2868, alpha=False)
        write_png(os.path.join(shots, f"ipad-{i:02d}.png"), 2048, 2732, alpha=False)

    write(os.path.join(app_dir, "store", "listing.json"), json.dumps({
        "languages": [{
            "lang": lang, "name": "Fixture", "subtitle": "Plant care reminders",
            "promotional_text": "Now with seasonal watering hints.",
            "description": "Fixture keeps offline plant care reminders.",
            "keywords": "plants,care,reminder,watering,garden",
            "release_notes": "First release.",
        } for lang in ios["languages"]]
    }, indent=2))

    write(os.path.join(root, "docs", SLUG, "privacy", "index.html"), "<h1>Privacy</h1>")
    write(os.path.join(root, "docs", SLUG, "support", "index.html"), "<h1>Support</h1>")
    write(os.path.join(root, "specifications", f"{SLUG}.json"), json.dumps({"slug": SLUG}))


def run_gate(root: str, strict: bool = True) -> tuple[int, dict[str, str], str]:
    env = dict(os.environ, FACTORY_ROOT=root)
    cmd = [sys.executable, CHECKER, SLUG] + (["--strict"] if strict else [])
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env)
    statuses = dict((rule, status) for status, rule in
                    re.findall(r"^\[(\w+)\s*\]\s+(\S+)", proc.stdout, re.MULTILINE))
    return proc.returncode, statuses, proc.stdout + proc.stderr


def main() -> int:
    failures = []

    def check(label: str, condition: bool, detail: str = "") -> None:
        print(f"  {'ok  ' if condition else 'FAIL'}  {label}" + (f"  ({detail})" if detail and not condition else ""))
        if not condition:
            failures.append(label)

    # --- a complete app passes ---------------------------------------------
    print("clean fixture, --strict:")
    root = tempfile.mkdtemp(prefix="factory-ios-")
    try:
        build_fixture(root)
        code, statuses, out = run_gate(root)
        check("exit code 0", code == 0, out)
        check("no FAILs", "FAIL" not in statuses.values(),
              ", ".join(f"{r}={s}" for r, s in statuses.items() if s == "FAIL"))
        check("every rule ran", len(statuses) >= 15, f"{len(statuses)} rules")
    finally:
        shutil.rmtree(root, ignore_errors=True)

    # --- each break trips exactly its own rule ------------------------------
    def broken(label: str, expect_rule: str, mutate) -> None:
        print(f"\n{label}:")
        root = tempfile.mkdtemp(prefix="factory-ios-")
        try:
            mutate(root)
            code, statuses, out = run_gate(root)
            check(f"{expect_rule} is FAIL", statuses.get(expect_rule) == "FAIL",
                  f"got {statuses.get(expect_rule)}\n{out}")
            check("exit code 1", code == 1)
            others = [r for r, s in statuses.items() if s == "FAIL" and r != expect_rule]
            check("no collateral failures", not others, f"also failed: {others}")
        finally:
            shutil.rmtree(root, ignore_errors=True)

    def with_test_admob_ids(root: str) -> None:
        build_fixture(root, admob={
            "app_id": "ca-app-pub-3940256099942544~1458002511",
            "banner_unit_id": "ca-app-pub-3940256099942544/2934735716",
            "interstitial_unit_id": "ca-app-pub-3940256099942544/4411468910",
        })

    def with_alpha_icon(root: str) -> None:
        build_fixture(root)
        write_png(os.path.join(root, "apps-ios", SLUG, "Sources", "Assets.xcassets",
                               "AppIcon.appiconset", "icon-1024.png"), 1024, 1024, alpha=True)

    def with_vague_permission(root: str) -> None:
        build_fixture(root)
        path = os.path.join(root, "apps-ios", SLUG, "Sources", "Info.plist")
        with open(path, "rb") as fh:
            data = plistlib.load(fh)
        data["NSCameraUsageDescription"] = "This app needs access to your camera."
        write_plist(path, data)

    def with_stub(root: str) -> None:
        build_fixture(root)
        with open(os.path.join(root, "apps-ios", SLUG, "Sources", "AdsManager.swift"), "a") as fh:
            fh.write('\nfunc exportData() { fatalError("unimplemented") }\n')

    def with_wrong_bundle_id(root: str) -> None:
        build_fixture(root, bundle_id="com.example.somethingelse")

    def with_hardcoded_ad_id(root: str) -> None:
        build_fixture(root)
        path = os.path.join(root, "apps-ios", SLUG, "Sources", "Info.plist")
        with open(path, "rb") as fh:
            data = plistlib.load(fh)
        data["GADApplicationIdentifier"] = "ca-app-pub-1111111111111111~2222222222"
        write_plist(path, data)

    def with_small_screenshots(root: str) -> None:
        build_fixture(root)
        shots = os.path.join(root, "apps-ios", SLUG, "store", "screenshots", "en")
        for name in os.listdir(shots):
            write_png(os.path.join(shots, name), 828, 1792)  # accepted by no set

    def with_long_subtitle(root: str) -> None:
        build_fixture(root)
        path = os.path.join(root, "apps-ios", SLUG, "store", "listing.json")
        data = json.loads(open(path, encoding="utf-8").read())
        data["languages"][0]["subtitle"] = "x" * 31
        write(path, json.dumps(data, indent=2))

    def with_firebase(root: str) -> None:
        build_fixture(root)
        path = os.path.join(root, "apps-ios", SLUG, "project.yml")
        write(path, open(path, encoding="utf-8").read() + "\n  # FirebaseAnalytics\n")

    broken("Google's test ad unit IDs", "admob_unit_ids", with_test_admob_ids)
    broken("icon with an alpha channel", "icon", with_alpha_icon)
    broken("vague permission string", "usage_descriptions", with_vague_permission)
    broken("fatalError stub", "no_stubs", with_stub)
    broken("bundle ID does not match the registry", "identity", with_wrong_bundle_id)
    broken("ad app ID hardcoded in Info.plist", "admob_app_id", with_hardcoded_ad_id)
    broken("screenshots at a size Apple rejects", "screenshots", with_small_screenshots)
    broken("subtitle over 30 characters", "listing", with_long_subtitle)
    broken("analytics SDK in the project", "forbidden_deps", with_firebase)

    # --- known_gaps excuse a failure unless --strict ------------------------
    print("\nknown_gaps excuses the gap without --strict:")
    root = tempfile.mkdtemp(prefix="factory-ios-")
    try:
        build_fixture(root, admob={"app_id": "", "banner_unit_id": "", "interstitial_unit_id": ""},
                      known_gaps={"admob_unit_ids": "AdMob console pending; step 6 of the flow."})
        code, statuses, out = run_gate(root, strict=False)
        check("admob_unit_ids is EXCUSED", statuses.get("admob_unit_ids") == "EXCUSED", out)
        check("exit code 0", code == 0)
        code, statuses, _ = run_gate(root, strict=True)
        check("--strict turns it into FAIL", statuses.get("admob_unit_ids") == "FAIL")
        check("exit code 1 under --strict", code == 1)
    finally:
        shutil.rmtree(root, ignore_errors=True)

    print(f"\n{len(failures)} assertion(s) failed" if failures else "\nall assertions passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
