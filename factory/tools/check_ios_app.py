#!/usr/bin/env python3
"""
App Factory - iOS quality gate. Checks an App Store app against the factory
rules before it is allowed to build, upload, or submit.

  python factory/tools/check_ios_app.py plant-cue-ios
  python factory/tools/check_ios_app.py plant-cue-ios --strict   # known_gaps no longer excuse failures

Exit codes: 0 all good (or only excused gaps), 1 failures.

Rules (from factory/apps.json defaults.ios.rules plus store-readiness basics):
  ads_sdk              GoogleMobileAds really declared as an SPM dependency
  admob_app_id         GADApplicationIdentifier comes from the xcconfig, not a literal
  att_and_skadnetwork  NSUserTrackingUsageDescription + SKAdNetworkItems + a real ATT call
  privacy_manifest     PrivacyInfo.xcprivacy present and non-empty
  admob_unit_ids       real AdMob unit IDs in the registry (Google's test IDs fail --strict)
  iap_configured       remove-ads product ID present in the registry and referenced in Swift
  no_stubs             no unimplemented placeholders left behind
  forbidden_deps       no analytics/tracking SDKs
  identity             bundle ID and versions in the project match the registry
  usage_descriptions   every NS*UsageDescription has a real, specific reason string
  tests                a unit-test target exists and has test files
  icon                 1024x1024 PNG with no alpha channel in the asset catalog
  screenshots          3-10 store screenshots at a size Apple accepts for a required set
  listing              every registry language present, within Apple's character limits
  privacy_page         privacy_path/index.html exists
  support_page         support_path/index.html exists   (Apple requires a support URL)
  spec                 spec file exists

A failure listed in the app's "known_gaps" is reported as EXCUSED (not fatal)
unless --strict is given, so the registry documents the gap honestly instead
of the check being silently skipped.

Standard library only: project.yml is read as text (same approach check_app.py
takes with Gradle files) because the factory does not install PyYAML.
"""

from __future__ import annotations

import json
import os
import plistlib
import re
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from registry import ROOT, find, load, platform_of, ad_id as registry_ad_id  # noqa: E402

# Apple's own boilerplate; not a factory stub.
ALLOWED_FATAL_ERRORS = ("init(coder:)", "has not been implemented")

STUB_PATTERNS = [
    (r'fatalError\(\s*"[^"]*unimplemented', "fatalError(\"unimplemented\")"),
    (r'fatalError\(\s*"[^"]*not implemented', "fatalError(\"not implemented\")"),
    (r"#if\s+false", "#if false"),
    (r"//\s*(?:TODO|FIXME)\b", "TODO/FIXME comment"),
    (r'Text\(\s*"(?:Placeholder|Coming soon|TBD)', "placeholder screen text"),
]

# Permission strings Apple rejects for being vague (guideline 5.1.1).
GENERIC_USAGE_TEXT = [
    r"^\s*$",
    r"^(?:we\s+)?need(?:s|ed)?\s+access",
    r"^this app (?:needs|requires|uses)\s+(?:access\s+)?(?:to\s+)?(?:your\s+)?\w+\.?$",
    r"^required$",
    r"^for (?:the )?app to work",
    r"^\w+ access$",
]
MIN_USAGE_TEXT = 25


def read(path: str) -> str:
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def walk_files(base: str, suffixes: tuple[str, ...], skip: tuple[str, ...] = ()) -> list[str]:
    out = []
    for dirpath, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if d not in ("build", ".build", "DerivedData", "Pods", ".git")]
        norm = dirpath.replace("\\", "/")
        if any(s in norm for s in skip):
            continue
        for f in files:
            if f.endswith(suffixes):
                out.append(os.path.join(dirpath, f))
    return out


def swift_files(app_path: str) -> list[str]:
    base = os.path.join(ROOT, app_path)
    return walk_files(base, (".swift",)) if os.path.isdir(base) else []


def project_text(app_path: str) -> str:
    """project.yml plus any xcconfig and Package.resolved, as one searchable blob.

    Deliberately excludes .pbxproj: it is XcodeGen's generated output, not
    committed source, and in a fresh CI checkout it does not exist yet (xcodegen
    generate runs during the build step). Scanning it also pulls in bundle IDs
    XcodeGen auto-assigns to test/UI-test targets, which are not the app's own
    identity and would contaminate this search.
    """
    base = os.path.join(ROOT, app_path)
    if not os.path.isdir(base):
        return ""
    paths = walk_files(base, ("project.yml", ".xcconfig", "Package.resolved"))
    return "\n".join(read(p) for p in paths)


def parse_xcconfig_assignments(text: str) -> dict[str, str]:
    """KEY = VALUE lines from xcconfig text, last assignment wins (xcconfig semantics)."""
    out: dict[str, str] = {}
    for line in text.splitlines():
        line = line.split("//", 1)[0].strip()
        m = re.match(r"^([\w]+)\s*=\s*(.+)$", line)
        if m:
            out[m.group(1)] = m.group(2).strip()
    return out


def resolve_setting(raw: str, assignments: dict[str, str], depth: int = 0) -> str | None:
    """Resolve an Xcode build setting through $(VAR) / $(VAR:default=X) indirection.

    The factory's own convention (see AdMob.xcconfig) is CI overriding a value
    through one level of $(FOO_OVERRIDE:default=...) indirection so a real ID
    from the registry can replace a safe default without editing tracked
    source. The identity check has to follow that chain to see the real value,
    the same way admob_app_id already does for GADApplicationIdentifier.
    """
    if depth > 8:
        return None
    raw = raw.strip().strip('"')
    m = re.fullmatch(r"\$\((\w+)(?::default=(.*))?\)", raw)
    if not m:
        return raw or None
    var, default = m.group(1), m.group(2)
    if var in assignments:
        resolved = resolve_setting(assignments[var], assignments, depth + 1)
        if resolved is not None:
            return resolved
    return default


def load_plist(path: str) -> dict | None:
    try:
        with open(path, "rb") as fh:
            data = plistlib.load(fh)
        return data if isinstance(data, dict) else None
    except (OSError, plistlib.InvalidFileException, ValueError):
        return None


def find_info_plist(app_path: str) -> tuple[dict | None, str]:
    """Parsed Info.plist plus the raw text of every plist-ish source.

    XcodeGen can either point at a real Info.plist or synthesise one from
    project.yml, so both are searched before a key is called missing.
    """
    base = os.path.join(ROOT, app_path)
    if not os.path.isdir(base):
        return None, ""
    plists = [p for p in walk_files(base, ("Info.plist",))]
    parsed = next((d for d in (load_plist(p) for p in plists) if d), None)
    text = "\n".join(read(p) for p in plists) + "\n" + project_text(app_path)
    return parsed, text


def png_info(path: str) -> tuple[int, int, bool] | None:
    """(width, height, has_alpha) for a PNG, or None if it is not a PNG."""
    with open(path, "rb") as fh:
        head = fh.read(26)
        rest = fh.read()
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w, h = struct.unpack(">II", head[16:24])
    color_type = head[25]
    # 4 = gray+alpha, 6 = RGB+alpha; a tRNS chunk adds transparency to 0/2/3.
    return w, h, color_type in (4, 6) or b"tRNS" in rest


def jpeg_size(path: str) -> tuple[int, int] | None:
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:2] != b"\xff\xd8":
        return None
    i = 2
    while i + 9 < len(data):
        if data[i] != 0xFF:
            i += 1
            continue
        marker, length = data[i + 1], struct.unpack(">H", data[i + 2:i + 4])[0]
        if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
            h, w = struct.unpack(">HH", data[i + 5:i + 9])
            return w, h
        i += 2 + length
    return None


def image_size(path: str) -> tuple[int, int] | None:
    if path.lower().endswith(".png"):
        info = png_info(path)
        return (info[0], info[1]) if info else None
    if path.lower().endswith((".jpg", ".jpeg")):
        return jpeg_size(path)
    return None


def main(argv: list[str]) -> int:
    if not argv:
        sys.exit(__doc__)
    slug = argv[0]
    strict = "--strict" in argv
    app = find(slug)
    if platform_of(app) != "ios":
        sys.exit(f"check_ios_app: '{slug}' is a {platform_of(app)} app; use check_app.py instead")

    reg = load()
    ios = reg["defaults"]["ios"]
    rules = ios["rules"]
    languages = ios["languages"]
    limits = ios["listing_limits"]
    known_gaps = app.get("known_gaps") or {}

    results: list[tuple[str, str, str]] = []

    def report(rule: str, ok: bool, detail: str, gap_key: str | None = None) -> None:
        if ok:
            results.append((rule, "PASS", detail))
        elif gap_key and gap_key in known_gaps and not strict:
            results.append((rule, "EXCUSED", f"{detail} - known gap: {known_gaps[gap_key]}"))
        else:
            results.append((rule, "FAIL", detail))

    app_path = app["path"]
    proj = project_text(app_path)
    swift = "\n".join(read(f) for f in swift_files(app_path))
    info, info_text = find_info_plist(app_path)

    # --- monetisation -------------------------------------------------------
    if rules.get("admob_required"):
        report("ads_sdk", "GoogleMobileAds" in proj,
               f"GoogleMobileAds SPM dependency declared: {'GoogleMobileAds' in proj}", gap_key="admob")

        # The ad app ID must be injected from the xcconfig so CI can swap test
        # IDs for real ones without editing tracked source.
        gad_literal = re.search(r"<key>GADApplicationIdentifier</key>\s*<string>\s*(ca-app-pub-[^<\s]+)", info_text)
        gad_var = "GADApplicationIdentifier" in info_text and (
            "$(ADMOB_APP_ID)" in info_text or "${ADMOB_APP_ID}" in info_text)
        report("admob_app_id", gad_var and not gad_literal,
               f"GADApplicationIdentifier from xcconfig: {gad_var}"
               + (f"; hardcoded literal found: {gad_literal.group(1)}" if gad_literal else ""),
               gap_key="admob")

        admob = app.get("admob") or {}
        # Resolve exactly the way registry.py does for the build, or the gate
        # judges different IDs from the ones that get compiled in. Real values
        # come from repo variables; the registry entry is a fallback.
        FIELD_ENV = {"app_id": "APP_ID", "banner_unit_id": "BANNER_UNIT_ID",
                     "interstitial_unit_id": "INTERSTITIAL_UNIT_ID"}
        slug_upper = slug.upper().replace("-", "_")
        ids = {k: registry_ad_id(slug_upper, env_field, admob.get(k))
               for k, env_field in FIELD_ENV.items()}
        missing = [k for k, v in ids.items() if not v]
        test_prefix = ios["admob_test_id_prefix"]
        using_test = [k for k, v in ids.items() if v.startswith(test_prefix)]
        report("admob_unit_ids", not missing and not using_test,
               f"missing: {missing or 'none'}; Google test IDs: {using_test or 'none'}",
               gap_key="admob_unit_ids")

        # Factory rule 5: ad unit IDs never live in git. PriceJar's were
        # committed to a public repo for a whole release before anyone noticed,
        # because nothing checked -- the rule was written down and unenforced,
        # the same failure shape as the ATT guard and the iPad screenshot set.
        committed = [k for k in FIELD_ENV
                     if str(admob.get(k) or "") and not str(admob.get(k)).startswith(test_prefix)]
        report("ad_ids_not_in_git", not committed,
               f"production AdMob IDs committed in factory/apps.json: {committed or 'none'}"
               + ("; move them to repo variables ADMOB_%s_<FIELD>" % slug_upper if committed else ""))

    if rules.get("att_required"):
        has_att_string = "NSUserTrackingUsageDescription" in info_text
        has_skad = "SKAdNetworkItems" in info_text
        has_att_call = "ATTrackingManager.requestTrackingAuthorization" in swift
        report("att_and_skadnetwork", has_att_string and has_skad and has_att_call,
               f"NSUserTrackingUsageDescription: {has_att_string}, SKAdNetworkItems: {has_skad}, "
               f"requestTrackingAuthorization call: {has_att_call}", gap_key="att")

    if rules.get("remove_ads_iap_required"):
        product_id = str((app.get("iap") or {}).get("remove_ads_product_id") or "")
        referenced = bool(product_id) and (product_id in swift or "IAP_REMOVE_ADS_PRODUCT_ID" in proj)
        report("iap_configured", bool(product_id) and referenced,
               f"product_id={product_id or 'MISSING'}, referenced in project: {referenced}",
               gap_key="iap")

    # --- privacy ------------------------------------------------------------
    if rules.get("privacy_manifest_required"):
        base = os.path.join(ROOT, app_path)
        manifests = walk_files(base, ("PrivacyInfo.xcprivacy",)) if os.path.isdir(base) else []
        parsed = next((d for d in (load_plist(p) for p in manifests) if d), None)
        report("privacy_manifest", bool(parsed) and bool(
            parsed.get("NSPrivacyCollectedDataTypes") or parsed.get("NSPrivacyAccessedAPITypes")),
            f"PrivacyInfo.xcprivacy files: {len(manifests)}"
            + ("; declares data types / accessed APIs" if parsed else "; missing or empty"),
            gap_key="privacy_manifest")

    # --- honesty ------------------------------------------------------------
    if rules.get("no_stubs"):
        found = []
        for pattern, label in STUB_PATTERNS:
            for m in re.finditer(pattern, swift, re.IGNORECASE):
                line = swift[max(0, m.start() - 120):m.end() + 120]
                if any(a in line for a in ALLOWED_FATAL_ERRORS):
                    continue
                found.append(label)
                break
        report("no_stubs", not found, f"placeholders: {sorted(set(found)) or 'none'}", gap_key="no_stubs")

    bad = [d for d in rules.get("forbidden_dependencies", []) if d in proj]
    report("forbidden_deps", not bad, f"forbidden dependencies present: {bad or 'none'}")

    # --- identity -----------------------------------------------------------
    # Values are read as raw text (a literal, or an Xcode $(VAR:default=X)
    # reference) and then resolved through the xcconfig assignments, since the
    # factory's own convention is CI overriding one level of indirection to
    # inject the real value without touching tracked source.
    assignments = parse_xcconfig_assignments(proj)

    def resolved_settings(key: str) -> set[str]:
        raw_values = re.findall(key + r"\s*[:=]\s*(\"[^\"]*\"|\$\([^)]*\)|\S+)", proj)
        out = set()
        for raw in raw_values:
            resolved = resolve_setting(raw, assignments)
            if resolved:
                out.add(resolved)
        return out

    version = app.get("current_version") or {}
    bundle_ids = resolved_settings("PRODUCT_BUNDLE_IDENTIFIER")
    proj_marketing = resolved_settings("MARKETING_VERSION")
    proj_build = resolved_settings("CURRENT_PROJECT_VERSION")
    want_marketing, want_build = str(version.get("marketing_version") or ""), str(version.get("build") or "")
    identity_ok = (
        app["bundle_id"] in bundle_ids
        and (not proj_marketing or want_marketing in proj_marketing)
        and (not proj_build or want_build in proj_build)
    )
    report("identity", identity_ok,
           f"bundle IDs resolved: {sorted(bundle_ids) or 'MISSING'} registry={app['bundle_id']}; "
           f"MARKETING_VERSION {sorted(proj_marketing) or 'unset'} vs {want_marketing or 'unset'}; "
           f"CURRENT_PROJECT_VERSION {sorted(proj_build) or 'unset'} vs {want_build or 'unset'}")

    # --- device family ------------------------------------------------------
    # Xcode builds universal when TARGETED_DEVICE_FAMILY is unset, so an app
    # specced as iPhone-only silently ships an iPad build: Apple then demands
    # 13-inch iPad screenshots and reviews a layout nobody designed. Caught
    # here rather than by Apple, which is where PriceJar 1.0.0 found it.
    FAMILY_BY_DEVICE = {"iPhone": "1", "iPad": "2"}
    spec_devices = []
    spec_data: dict = {}
    spec_path = os.path.join(ROOT, app["spec"])
    if os.path.isfile(spec_path):
        spec_data = json.loads(read(spec_path))
        spec_devices = (spec_data.get("technical") or {}).get("devices") or []
    if spec_devices:
        want_family = ",".join(FAMILY_BY_DEVICE[d] for d in spec_devices if d in FAMILY_BY_DEVICE)
        got = resolved_settings("TARGETED_DEVICE_FAMILY")
        report("device_family", bool(want_family) and want_family in got,
               f"spec devices {spec_devices} need TARGETED_DEVICE_FAMILY={want_family or '?'}; "
               f"project has {sorted(got) or 'UNSET (Xcode defaults to universal)'}")

    # --- permission strings -------------------------------------------------
    if info:
        vague = []
        for key, value in info.items():
            if not key.startswith("NS") or not key.endswith("UsageDescription"):
                continue
            text = value if isinstance(value, str) else ""
            if len(text.strip()) < MIN_USAGE_TEXT or any(
                    re.match(p, text.strip(), re.IGNORECASE) for p in GENERIC_USAGE_TEXT):
                vague.append(key)
        report("usage_descriptions", not vague,
               f"vague or missing reason strings: {vague or 'none'}", gap_key="usage_descriptions")
    else:
        report("usage_descriptions", False, "no parseable Info.plist found", gap_key="usage_descriptions")

    # --- tests --------------------------------------------------------------
    has_test_target = "bundle.unit-test" in proj
    test_files = [f for f in swift_files(app_path) if "Tests/" in f.replace("\\", "/")]
    report("tests", has_test_target and len(test_files) > 0,
           f"unit-test target declared: {has_test_target}; test files: {len(test_files)}", gap_key="tests")

    # --- store assets -------------------------------------------------------
    store_dir = os.path.join(ROOT, app["store_dir"])
    icons = walk_files(os.path.join(ROOT, app_path), ("1024.png", "icon-1024.png")) if os.path.isdir(
        os.path.join(ROOT, app_path)) else []
    icon_detail, icon_ok = "no 1024 icon found in the project", False
    for icon in icons:
        got = png_info(icon)
        if not got:
            continue
        w, h, alpha = got
        icon_ok = (w, h) == (1024, 1024) and not alpha
        icon_detail = f"{os.path.relpath(icon, ROOT)} size=({w}, {h}) alpha={alpha}"
        if icon_ok:
            break
    report("icon", icon_ok, icon_detail + (" - App Store icons must have no alpha channel" if not icon_ok else ""),
           gap_key="icon")

    # Screenshots follow the fastlane deliver layout (one folder per language);
    # the device set is inferred from the pixel size, as Apple does on upload.
    # A set is required only for a device the spec ships. The registry has always
    # said the iPad set is "required whenever the app declares iPad support", but
    # `required: true` was read unconditionally, so an iPhone-only app was asked
    # for 13-inch iPad screenshots that Apple does not want and the capture step
    # cannot produce. The intent lived in a note; this is the check.
    required_sets = {
        name: cfg for name, cfg in ios["screenshot_sets"].items()
        if cfg.get("required") and (
            not spec_devices or cfg.get("device") is None or cfg["device"] in spec_devices)
    }
    default_folder = next((k for k, v in ios["screenshot_dir_to_asc_lang"].items() if v == languages[0]), "en")
    shots_dir = os.path.join(store_dir, "screenshots", default_folder)
    shots = sorted(f for f in os.listdir(shots_dir)) if os.path.isdir(shots_dir) else []
    shots = [f for f in shots if f.lower().endswith((".png", ".jpg", ".jpeg"))]
    lo, hi = ios["screenshot_count"]["min"], ios["screenshot_count"]["max"]
    # Sizes claimed by any required set: an image matching one of those belongs
    # to another device's set, not to this one, and calling it "wrong size" here
    # would send someone hunting for a problem that does not exist.
    all_accepted = {tuple(size) for cfg in required_sets.values() for size in cfg["sizes"]}
    for set_name, cfg in required_sets.items():
        accepted = {tuple(s) for s in cfg["sizes"]}
        matching, other_set, unusable = [], [], []
        for f in shots:
            size = image_size(os.path.join(shots_dir, f))
            if size in accepted:
                matching.append(f)
            elif size in all_accepted:
                other_set.append(f)
            else:
                unusable.append((f, size))
        transparent = [f for f in matching if f.lower().endswith(".png")
                       and (png_info(os.path.join(shots_dir, f)) or (0, 0, False))[2]]
        ok = lo <= len(matching) <= hi and not transparent and not unusable
        report("screenshots", ok,
               f"{set_name}: {len(matching)} images match {sorted(accepted)} (need {lo}-{hi}); "
               f"{len(other_set)} belong to another required set; "
               f"no set accepts: {[f for f, _ in unusable] or 'none'}; "
               f"with alpha: {transparent or 'none'}", gap_key="screenshots")

    # --- listing ------------------------------------------------------------
    listing_path = os.path.join(store_dir, "listing.json")
    if os.path.isfile(listing_path):
        entries = json.loads(read(listing_path)).get("languages", [])
        have = {e.get("lang") for e in entries}
        missing = [l for l in languages if l not in have]
        # A locale row that exists with an empty description is not a listing.
        # "missing languages: none" used to pass on exactly that, which is how
        # eight of nine ShiftSlip locales read as complete while holding null.
        REQUIRED_FIELDS = ("name", "subtitle", "description", "keywords")
        blank = [f"{e.get('lang')}.{f}" for e in entries for f in REQUIRED_FIELDS
                 if not str(e.get(f) or "").strip()]
        over = []
        for e in entries:
            for field, limit in limits.items():
                value = e.get(field)
                if isinstance(value, str) and len(value) > limit:
                    over.append(f"{e.get('lang')}.{field}={len(value)}>{limit}")
        report("listing", not (missing or over or blank),
               f"missing languages: {missing or 'none'}; over limit: {over or 'none'}; "
               f"empty required fields: {blank or 'none'}")

        # The purchase has store copy of its own, and Apple reviews it separately
        # with a screenshot of the screen that offers it. asc_setup.py creates
        # all of that from these inputs, so they are checked here first -- an
        # incomplete purchase is what two of PriceJar's three rejections were.
        if (app.get("iap") or {}).get("remove_ads_product_id"):
            IAP_LIMITS = {"name": 30, "description": 45}
            iap_problems = []
            for e in entries:
                iap = e.get("iap") or {}
                for field, limit in IAP_LIMITS.items():
                    value = str(iap.get(field) or "").strip()
                    if not value:
                        iap_problems.append(f"{e.get('lang')}.iap.{field} empty")
                    elif len(value) > limit:
                        iap_problems.append(f"{e.get('lang')}.iap.{field}={len(value)}>{limit}")
            shot = os.path.join(store_dir, "iap-review-screenshot.png")
            shot_info = png_info(shot) if os.path.isfile(shot) else None
            if not shot_info:
                iap_problems.append("store/iap-review-screenshot.png missing or not a PNG")
            elif shot_info[2]:
                iap_problems.append("store/iap-review-screenshot.png has an alpha channel")
            report("iap_store_copy", not iap_problems,
                   f"purchase copy and review screenshot: {iap_problems or 'complete'}")

        # The in-app strings have a unit test scanning them for phrases the app
        # must never use; the store listing had nothing. That is backwards --
        # the listing is the copy App Review actually reads, and it is where a
        # promise about taxes or wages is most tempting to write. Both now check
        # the same list, which lives in the spec so there is no second copy.
        banned = (spec_data.get("qa") or {}).get("banned_phrases") or {}
        phrases = [p for key, values in banned.items()
                   if not key.startswith("_") for p in values]
        if phrases:
            hits = []
            for e in entries:
                for field, value in e.items():
                    if field == "lang" or not isinstance(value, str):
                        continue
                    lowered = value.lower()
                    hits += [f"{e.get('lang')}/{field}: '{ph}'" for ph in phrases if ph in lowered]
            report("listing_copy", not hits,
                   f"banned phrases in the store listing: {hits or 'none'} "
                   f"({len(phrases)} from the spec, {len(entries)} locale(s))")
    else:
        report("listing", False, f"{os.path.relpath(listing_path, ROOT)} missing")

    # --- pages and spec -----------------------------------------------------
    privacy = os.path.join(ROOT, app["privacy_path"], "index.html")
    report("privacy_page", os.path.isfile(privacy), os.path.relpath(privacy, ROOT))
    support_path = app.get("support_path", "")
    support = os.path.join(ROOT, support_path, "index.html") if support_path else ""
    report("support_page", bool(support) and os.path.isfile(support),
           os.path.relpath(support, ROOT) if support else "no support_path in the registry "
           "(Apple requires a support URL)")
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
