#!/usr/bin/env python3
"""
Huawei App Factory - read factory/apps.json (the app registry).

Single source of truth for workflows and the local CLI, so nobody parses the
JSON twice in bash. Standard library only.

  python factory/tools/registry.py list
  python factory/tools/registry.py get receipt-lens package
  python factory/tools/registry.py env receipt-lens        # KEY=VALUE lines for $GITHUB_ENV
  python factory/tools/registry.py changed <base_sha> <head_sha>   # slugs whose path changed
  python factory/tools/registry.py agc-lang en             # screenshot folder -> AGC language code
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REGISTRY = os.path.join(ROOT, "factory", "apps.json")


def load() -> dict:
    with open(REGISTRY, encoding="utf-8") as fh:
        return json.load(fh)


def find(slug: str) -> dict:
    for app in load()["apps"]:
        if app["slug"] == slug:
            return app
    sys.exit(f"registry: unknown app '{slug}'. Known: {', '.join(a['slug'] for a in load()['apps'])}")


def cmd_list() -> None:
    for app in load()["apps"]:
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


def cmd_env(slug: str) -> None:
    app = find(slug)
    defaults = load()["defaults"]
    slug_upper = slug.upper().replace("-", "_")
    lines = {
        "APP_SLUG": slug,
        "APP_SLUG_UPPER": slug_upper,
        "APP_NAME": app["name"],
        "APP_PATH": app["path"],
        "APP_PACKAGE": app["package"],
        "APP_STORE_DIR": app["store_dir"],
        "APP_PRIVACY_PATH": app["privacy_path"],
        "AGC_APP_ID": str(app.get("agc_app_id") or ""),
        "PRIVACY_TAGS_CONFIGURED": str(app.get("privacy_tags_configured") or ""),
        "PETAL_BANNER_AD_ID": str((app.get("ads") or {}).get("banner_ad_id") or ""),
        "PETAL_INTERSTITIAL_AD_ID": str((app.get("ads") or {}).get("interstitial_ad_id") or ""),
        "FACTORY_JAVA_VERSION": defaults["java_version"],
        "FACTORY_GRADLE_VERSION": defaults["gradle_version"],
        "ARTIFACT_APK": f"{slug}-release-apk",
        "ARTIFACT_AAB": f"{slug}-release-aab",
    }
    for k, v in lines.items():
        print(f"{k}={v}")


def cmd_changed(base: str, head: str) -> None:
    try:
        out = subprocess.check_output(["git", "diff", "--name-only", base, head], cwd=ROOT, text=True)
    except subprocess.CalledProcessError:
        # shallow clone or unknown base: be conservative and build everything
        for app in load()["apps"]:
            print(app["slug"])
        return
    changed_files = out.split()
    for app in load()["apps"]:
        prefix = app["path"].rstrip("/") + "/"
        if any(f.startswith(prefix) for f in changed_files):
            print(app["slug"])


def cmd_agc_lang(folder: str) -> None:
    mapping = load()["defaults"]["screenshot_dir_to_agc_lang"]
    print(mapping.get(folder, folder))


def main(argv: list[str]) -> None:
    if not argv:
        sys.exit(__doc__)
    cmd, args = argv[0], argv[1:]
    if cmd == "list":
        cmd_list()
    elif cmd == "get" and len(args) == 2:
        cmd_get(*args)
    elif cmd == "env" and len(args) == 1:
        cmd_env(args[0])
    elif cmd == "changed" and len(args) == 2:
        cmd_changed(*args)
    elif cmd == "agc-lang" and len(args) == 1:
        cmd_agc_lang(args[0])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
