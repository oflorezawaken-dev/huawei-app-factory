#!/usr/bin/env python3
"""
Huawei App Factory - read factory/apps.json (the app registry).

Single source of truth for workflows and the local CLI, so nobody parses the
JSON twice in bash. Standard library only.

  python factory/tools/registry.py list [--platform android|ios]
  python factory/tools/registry.py get receipt-lens package
  python factory/tools/registry.py env receipt-lens        # KEY=VALUE lines for $GITHUB_ENV
  python factory/tools/registry.py changed <base_sha> <head_sha>   # slugs whose path changed
  python factory/tools/registry.py agc-lang en             # screenshot folder -> AGC language code
  python factory/tools/registry.py asc-lang en             # screenshot folder -> App Store language code
  python factory/tools/registry.py plan-ios <event> <base_sha> <head_sha> <input_slug>

An app with no "platform" field is an Android/AppGallery app: the field was
added when the iOS lane arrived and the existing entries predate it.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

# FACTORY_ROOT override exists only for local testing against a fixture tree.
ROOT = os.environ.get("FACTORY_ROOT") or os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REGISTRY = os.path.join(ROOT, "factory", "apps.json")


def load() -> dict:
    with open(REGISTRY, encoding="utf-8") as fh:
        return json.load(fh)


def platform_of(app: dict) -> str:
    return app.get("platform", "android")


def find(slug: str) -> dict:
    for app in load()["apps"]:
        if app["slug"] == slug:
            return app
    sys.exit(f"registry: unknown app '{slug}'. Known: {', '.join(a['slug'] for a in load()['apps'])}")


def cmd_list(platform: str | None = None) -> None:
    for app in load()["apps"]:
        if platform is None or platform_of(app) == platform:
            print(app["slug"])


def cmd_get(slug: str, field: str) -> None:
    app = find(slug)
    value = app
    for part in field.split("."):
        if isinstance(value, dict) and part in value:
            value = value[part]
        else:
            sys.exit(f"registry: app '{slug}' has no field '{field}'")
    print(value if not isinstance(value, (dict, list)) else json.dumps(value))


def env_android(app: dict, defaults: dict, slug: str, slug_upper: str) -> dict:
    return {
        "APP_PACKAGE": app["package"],
        "AGC_APP_ID": str(app.get("agc_app_id") or ""),
        "PRIVACY_TAGS_CONFIGURED": str(app.get("privacy_tags_configured") or ""),
        "PETAL_BANNER_AD_ID": str((app.get("ads") or {}).get("banner_ad_id") or ""),
        "PETAL_INTERSTITIAL_AD_ID": str((app.get("ads") or {}).get("interstitial_ad_id") or ""),
        "FACTORY_JAVA_VERSION": defaults["java_version"],
        "FACTORY_GRADLE_VERSION": defaults["gradle_version"],
        "ARTIFACT_APK": f"{slug}-release-apk",
        "ARTIFACT_AAB": f"{slug}-release-aab",
    }


def ad_id(slug_upper: str, field: str, registry_value) -> str:
    """A production ad unit ID, from the repo's variables rather than from git.

    Factory rule 5 keeps ad unit IDs out of the repository. They are not secret
    -- anyone can read them out of a shipped IPA -- but a public repo hands them
    to click-fraud tooling without the effort, so they live in GitHub Actions
    *variables* and are looked up per app:

        ADMOB_<SLUG>_APP_ID, ADMOB_<SLUG>_BANNER_UNIT_ID,
        ADMOB_<SLUG>_INTERSTITIAL_UNIT_ID          (slug upper-cased, - to _)

    Workflows pass the whole variable set as FACTORY_VARS (`toJSON(vars)`), so a
    new app needs three variables and no workflow edit. Anything still in the
    registry is used as a fallback, which keeps the Google test IDs working for
    pull requests, where variables are not available.
    """
    name = f"ADMOB_{slug_upper}_{field}"
    if name in os.environ:
        return os.environ[name]
    raw = os.environ.get("FACTORY_VARS")
    if raw:
        try:
            value = json.loads(raw).get(name)
        except json.JSONDecodeError:
            value = None
        if value:
            return str(value)
    return str(registry_value or "")


def env_ios(app: dict, defaults: dict, slug: str, slug_upper: str) -> dict:
    ios_defaults = defaults["ios"]
    admob = app.get("admob") or {}
    iap = app.get("iap") or {}
    version = app.get("current_version") or {}
    # The scheme is what xcodebuild is invoked with; it defaults to the app name
    # because that is what XcodeGen produces from project.yml unless overridden.
    return {
        "APP_BUNDLE_ID": app["bundle_id"],
        "APP_SCHEME": app.get("scheme") or app["name"],
        "APP_SUPPORT_PATH": app.get("support_path", ""),
        "ASC_APP_ID": str(app.get("asc_app_id") or ""),
        "APP_SKU": str(app.get("sku") or slug),
        "APPLE_TEAM_ID": str(app.get("team_id") or ios_defaults.get("team_id") or ""),
        "ADMOB_APP_ID": ad_id(slug_upper, "APP_ID", admob.get("app_id")),
        "ADMOB_BANNER_UNIT_ID": ad_id(slug_upper, "BANNER_UNIT_ID", admob.get("banner_unit_id")),
        "ADMOB_INTERSTITIAL_UNIT_ID": ad_id(slug_upper, "INTERSTITIAL_UNIT_ID",
                                            admob.get("interstitial_unit_id")),
        "IAP_REMOVE_ADS_PRODUCT_ID": str(iap.get("remove_ads_product_id") or ""),
        "MARKETING_VERSION": str(version.get("marketing_version") or ""),
        "CURRENT_PROJECT_VERSION": str(version.get("build") or ""),
        "FACTORY_MIN_IOS": str(app.get("min_ios") or ios_defaults["min_ios"]),
        "ARTIFACT_IPA": f"{slug}-release-ipa",
        # What the spec says the app runs on, so CI can skip work for a device
        # the app does not ship: an iPhone-only app has no iPad layout to
        # capture and Apple wants no iPad screenshots for it.
        "APP_DEVICES": ",".join(spec_devices(app)),
    }


def spec_devices(app: dict) -> list[str]:
    """technical.devices from the app's spec, or [] when there is no spec yet."""
    path = os.path.join(ROOT, app.get("spec") or "")
    if not app.get("spec") or not os.path.isfile(path):
        return []
    try:
        with open(path, encoding="utf-8") as fh:
            return list((json.load(fh).get("technical") or {}).get("devices") or [])
    except (json.JSONDecodeError, OSError):
        return []


def cmd_env(slug: str) -> None:
    app = find(slug)
    defaults = load()["defaults"]
    slug_upper = slug.upper().replace("-", "_")
    platform = platform_of(app)
    lines = {
        "APP_SLUG": slug,
        "APP_SLUG_UPPER": slug_upper,
        "APP_NAME": app["name"],
        "APP_PATH": app["path"],
        "APP_PLATFORM": platform,
        "APP_STORE_DIR": app["store_dir"],
        "APP_PRIVACY_PATH": app["privacy_path"],
    }
    per_platform = env_ios if platform == "ios" else env_android
    lines.update(per_platform(app, defaults, slug, slug_upper))
    for k, v in lines.items():
        print(f"{k}={v}")


def git_diff_names(base: str, head: str) -> list[str] | None:
    """Changed paths between two commits, or None when the range is not resolvable."""
    try:
        out = subprocess.check_output(["git", "diff", "--name-only", base, head], cwd=ROOT, text=True)
    except subprocess.CalledProcessError:
        return None
    return out.split()


def git_show_json(ref: str, path: str) -> dict | None:
    try:
        out = subprocess.check_output(["git", "show", f"{ref}:{path}"], cwd=ROOT, text=True,
                                      stderr=subprocess.DEVNULL)
        return json.loads(out)
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return None


def registry_entries_changed(base: str, head: str) -> list[str] | None:
    """Slugs whose own registry entry differs between two commits.

    Without this, editing one app's ad unit IDs rebuilds every app in the
    registry, because apps.json is a shared file (lesson 11 in the iOS handoff).
    Returns None when either side cannot be read, so callers fall back to
    rebuilding everything rather than silently skipping an app.
    """
    before, after = git_show_json(base, "factory/apps.json"), git_show_json(head, "factory/apps.json")
    if before is None or after is None:
        return None
    old = {a["slug"]: a for a in before.get("apps", [])}
    new = {a["slug"]: a for a in after.get("apps", [])}
    if before.get("defaults") != after.get("defaults"):
        return sorted(new)  # a defaults change can affect every app
    return sorted(slug for slug in new if old.get(slug) != new[slug])


def changed_slugs(base: str, head: str) -> list[str] | None:
    """Slugs affected by a commit range, or None to mean 'cannot tell, do all'."""
    changed_files = git_diff_names(base, head)
    if changed_files is None:
        return None
    affected: set[str] = set()
    for app in load()["apps"]:
        prefix = app["path"].rstrip("/") + "/"
        if any(f.startswith(prefix) for f in changed_files):
            affected.add(app["slug"])
    if "factory/apps.json" in changed_files:
        entries = registry_entries_changed(base, head)
        if entries is None:
            return None
        affected.update(entries)
    # Tooling and workflow changes affect every app, so they are deliberately
    # not narrowed to whichever app folders happen to also be in the diff. A
    # push that only edits a build workflow would otherwise legitimately diff
    # to zero app-owned paths and rebuild nothing, silently skipping the
    # re-verification a workflow change usually calls for.
    if any(f.startswith("factory/tools/") or f.startswith(".github/workflows/") for f in changed_files):
        return None
    return sorted(affected)


def cmd_changed(base: str, head: str, platform: str | None = None) -> None:
    slugs = changed_slugs(base, head)
    if slugs is None:
        slugs = [app["slug"] for app in load()["apps"]]
    keep = {a["slug"] for a in load()["apps"] if platform is None or platform_of(a) == platform}
    for slug in slugs:
        if slug in keep:
            print(slug)


def cmd_plan(event: str, base: str, head: str, input_slug: str, platform: str) -> None:
    """JSON array of slugs for a build workflow's matrix."""
    apps = [a for a in load()["apps"] if platform_of(a) == platform]
    known = {a["slug"] for a in apps}
    if input_slug:
        if input_slug not in known:
            sys.exit(f"registry: '{input_slug}' is not a {platform} app. Known: {', '.join(sorted(known))}")
        selected = [input_slug]
    elif event == "workflow_dispatch" or not base or not head or base.strip("0") == "":
        selected = sorted(known)
    else:
        slugs = changed_slugs(base, head)
        selected = sorted(known) if slugs is None else [s for s in slugs if s in known]
    print(json.dumps(selected))


def cmd_lang(folder: str, key: str) -> None:
    defaults = load()["defaults"]
    mapping = defaults["ios"]["screenshot_dir_to_asc_lang"] if key == "asc" else defaults["screenshot_dir_to_agc_lang"]
    print(mapping.get(folder, folder))


def main(argv: list[str]) -> None:
    if not argv:
        sys.exit(__doc__)
    cmd, args = argv[0], argv[1:]
    if cmd == "list":
        platform = args[args.index("--platform") + 1] if "--platform" in args else None
        cmd_list(platform)
    elif cmd == "get" and len(args) == 2:
        cmd_get(*args)
    elif cmd == "env" and len(args) == 1:
        cmd_env(args[0])
    elif cmd == "changed" and len(args) >= 2:
        platform = args[args.index("--platform") + 1] if "--platform" in args else None
        cmd_changed(args[0], args[1], platform)
    elif cmd == "plan-ios" and len(args) == 4:
        cmd_plan(args[0], args[1], args[2], args[3], "ios")
    elif cmd == "plan-android" and len(args) == 4:
        cmd_plan(args[0], args[1], args[2], args[3], "android")
    elif cmd == "agc-lang" and len(args) == 1:
        cmd_lang(args[0], "agc")
    elif cmd == "asc-lang" and len(args) == 1:
        cmd_lang(args[0], "asc")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
