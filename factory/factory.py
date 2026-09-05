#!/usr/bin/env python3
"""
Huawei App Factory - local command line.

Thin wrapper so a human (or a scheduled task) runs one command per step instead of
remembering gh/claude invocations. Standard library only.

  python factory/factory.py list
  python factory/factory.py check <slug> [--strict]           # Android quality gate
  python factory/factory.py check-ios <slug> [--strict]       # iOS quality gate
  python factory/factory.py asc <slug> [--what state|app|versions|builds]   # App Store Connect status
  python factory/factory.py build <slug>                      # gh: Factory Build
  python factory/factory.py store <slug> [--what all|listing|icon|screenshots|app-info] [--lang X] [--dry-run]
  python factory/factory.py publish <slug> [--aab] [--submit --notes "..."] [--run-id N]
  python factory/factory.py research                          # claude: propose an app
  python factory/factory.py spec <slug> --proposal proposals/<file>.md
  python factory/factory.py generate <slug>                   # claude: build the app from its spec
  python factory/factory.py fix <slug> --run-id N             # claude: fix a failing build
  python factory/factory.py listing <slug>                    # claude: 9-language store text
  python factory/factory.py privacy <slug>                    # claude: privacy policy page

Add --print to see the underlying command without running it.
The `claude` steps use Claude Code headless (`claude -p`) under your own subscription;
the `gh` steps dispatch the GitHub workflows, which run with the repo's secrets.
"""

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS = os.path.join(ROOT, "factory", "prompts")
REPO = "oflorezawaken-dev/huawei-app-factory"


def run(cmd: list[str], print_only: bool) -> int:
    print("$ " + " ".join(shlex.quote(c) for c in cmd), flush=True)
    if print_only:
        return 0
    return subprocess.call(cmd, cwd=ROOT)


def gh_dispatch(workflow: str, fields: dict, print_only: bool) -> int:
    cmd = ["gh", "workflow", "run", workflow, "-R", REPO]
    for k, v in fields.items():
        cmd += ["-f", f"{k}={v}"]
    return run(cmd, print_only)


def claude_step(prompt_files: list[str], extra: str, print_only: bool) -> int:
    parts = [open(os.path.join(PROMPTS, "00-factory-rules.md"), encoding="utf-8").read()]
    for f in prompt_files:
        parts.append(open(os.path.join(PROMPTS, f), encoding="utf-8").read())
    if extra:
        parts.append(extra)
    prompt = "\n\n---\n\n".join(parts)
    cmd = ["claude", "-p", prompt, "--allowedTools", "Bash,Read,Edit,Write,Glob,Grep,WebSearch,WebFetch"]
    if print_only:
        print("$ claude -p <prompt: " + ", ".join(["00-factory-rules.md"] + prompt_files) + f"> ({len(prompt)} chars)")
        return 0
    return subprocess.call(cmd, cwd=ROOT)


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="Huawei App Factory CLI", add_help=True)
    p.add_argument("command")
    p.add_argument("slug", nargs="?")
    p.add_argument("--strict", action="store_true")
    p.add_argument("--what", default="all")
    p.add_argument("--lang", default="")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--aab", action="store_true")
    p.add_argument("--submit", action="store_true")
    p.add_argument("--notes", default="")
    p.add_argument("--run-id", default="")
    p.add_argument("--proposal", default="")
    p.add_argument("--print", dest="print_only", action="store_true")
    a = p.parse_args(argv)

    needs_slug = {"check", "check-ios", "asc", "build", "store", "publish", "spec", "generate", "fix",
                  "listing", "privacy"}
    if a.command in needs_slug and not a.slug:
        sys.exit(f"{a.command} needs an app slug (see: python factory/factory.py list)")

    py = sys.executable
    if a.command == "list":
        return run([py, "factory/tools/registry.py", "list"], a.print_only)
    if a.command == "check":
        cmd = [py, "factory/tools/check_app.py", a.slug] + (["--strict"] if a.strict else [])
        return run(cmd, a.print_only)
    if a.command == "check-ios":
        cmd = [py, "factory/tools/check_ios_app.py", a.slug] + (["--strict"] if a.strict else [])
        return run(cmd, a.print_only)
    if a.command == "asc":
        # Reads only; needs ASC_* in the environment (never passed on the command line).
        return run([py, "factory/tools/asc_client.py", a.what if a.what != "all" else "state", a.slug],
                   a.print_only)
    if a.command == "build":
        return gh_dispatch("factory-build.yml", {"app": a.slug}, a.print_only)
    if a.command == "store":
        return gh_dispatch("factory-store.yml", {"app": a.slug, "what": a.what, "lang": a.lang,
                                                 "dry_run": "true" if a.dry_run else "false"}, a.print_only)
    if a.command == "publish":
        if a.submit and not (10 <= len(a.notes) <= 300):
            sys.exit("--submit requires --notes with 10-300 characters")
        return gh_dispatch("factory-publish.yml", {
            "app": a.slug, "release_run_id": a.run_id,
            "package_type": "aab" if a.aab else "apk",
            "submit_for_review": "true" if a.submit else "false",
            "release_notes": a.notes}, a.print_only)
    if a.command == "research":
        return claude_step(["10-research.md"], "", a.print_only)
    if a.command == "spec":
        if not a.proposal:
            sys.exit("spec needs --proposal proposals/<file>.md")
        return claude_step(["20-spec.md"], f"Slug: {a.slug}\nProposal file: {a.proposal}", a.print_only)
    if a.command == "generate":
        return claude_step(["30-generate.md"], f"Slug: {a.slug}", a.print_only)
    if a.command == "fix":
        if not a.run_id:
            sys.exit("fix needs --run-id")
        return claude_step(["40-fix-build.md"], f"Slug: {a.slug}\nFailing run: {a.run_id}", a.print_only)
    if a.command == "listing":
        return claude_step(["50-listing.md"], f"Slug: {a.slug}", a.print_only)
    if a.command == "privacy":
        return claude_step(["60-privacy.md"], f"Slug: {a.slug}", a.print_only)
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
