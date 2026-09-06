#!/usr/bin/env python3
"""
Huawei App Factory - local command line.

Thin wrapper so a human (or a scheduled task) runs one command per step instead of
remembering gh/claude invocations. Standard library only.

  python factory/factory.py list
  python factory/factory.py check <slug> [--strict]           # Android quality gate
  python factory/factory.py check-ios <slug> [--strict]       # iOS quality gate
  python factory/factory.py asc <slug> [--what state|app|versions|builds]   # App Store Connect status
  python factory/factory.py watch [<slug>] [--dry-run]        # review state -> issue when it changes
  python factory/factory.py build <slug>                      # gh: Factory Build
  python factory/factory.py store <slug> [--what all|listing|icon|screenshots|app-info|privacy-tags] [--lang X] [--dry-run]
  python factory/factory.py privacy-tags <slug> [--init]     # local: validate + write store/privacy-tags.md (console checklist)
  python factory/factory.py publish <slug> [--aab] [--submit --notes "..."] [--run-id N]
  python factory/factory.py research [--ios]                  # claude: propose an app (App Store lane with --ios)
  python factory/factory.py spec <slug> --proposal proposals/<file>.md [--ios]
  python factory/factory.py generate <slug> [--ios]           # claude: build the app from its spec
  python factory/factory.py fix <slug> --run-id N [--ios]     # claude: fix a failing build
  python factory/factory.py listing <slug> [--ios]            # claude: 9-language store text
  python factory/factory.py privacy <slug> [--ios]            # claude: privacy (+support) pages

Add --print to see the underlying command without running it.
The `claude` steps use Claude Code headless (`claude -p`) under your own subscription;
the `gh` steps dispatch the GitHub workflows, which run with the repo's secrets.

Each `claude` step declares its own model (see STEP_MODEL): judgment-heavy steps
run on Opus, bulk execution on Sonnet. This is deliberate rather than relying on
the `opusplan` alias, which switches on Claude Code's *plan mode* -- and headless
`claude -p` never enters plan mode, so opusplan would silently run every step,
research included, on Sonnet. Override per invocation with --model.
"""

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys

# Which model each brain step is worth. Research and spec set the direction for
# everything downstream and are cheap to run (one shot each); generation and
# fixes are long, mechanical and token-hungry.
STEP_MODEL = {
    "research": "opus",   # market judgement, competitor reading, scoring
    "spec": "opus",       # architecture and acceptance criteria
    "generate": "sonnet",  # bulk code from an already-decided spec
    "fix": "sonnet",       # minimal mechanical change against a build log
    "listing": "sonnet",   # store copy in 9 languages
    "privacy": "sonnet",   # policy page from a template
}

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


def model_for(step: str, override: str) -> str:
    """The model this step runs on: an explicit --model wins, else STEP_MODEL."""
    return override or STEP_MODEL.get(step, "")


def claude_step(prompt_files: list[str], extra: str, print_only: bool, model: str = "") -> int:
    parts = [open(os.path.join(PROMPTS, "00-factory-rules.md"), encoding="utf-8").read()]
    for f in prompt_files:
        parts.append(open(os.path.join(PROMPTS, f), encoding="utf-8").read())
    if extra:
        parts.append(extra)
    prompt = "\n\n---\n\n".join(parts)
    cmd = ["claude", "-p", prompt, "--allowedTools", "Bash,Read,Edit,Write,Glob,Grep,WebSearch,WebFetch"]
    if model:
        cmd += ["--model", model]
    if print_only:
        print("$ claude -p <prompt: " + ", ".join(["00-factory-rules.md"] + prompt_files)
              + f"> ({len(prompt)} chars)" + (f" --model {model}" if model else ""))
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
    p.add_argument("--init", action="store_true")
    p.add_argument("--ios", action="store_true")
    p.add_argument("--model", default="", help="override the step's default model (see STEP_MODEL)")
    p.add_argument("--print", dest="print_only", action="store_true")
    a = p.parse_args(argv)

    needs_slug = {"check", "check-ios", "asc", "build", "store", "publish", "spec", "generate", "fix",
                  "listing", "privacy", "privacy-tags"}
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
    if a.command == "watch":
        cmd = [py, "factory/tools/asc_watch.py"] + ([a.slug] if a.slug else []) \
              + (["--dry-run"] if a.dry_run else [])
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
        # The iOS lane researches the App Store market on its own terms; it
        # never ports the AppGallery apps (owner's decision, 2026-09-07).
        prompt = "10-research-ios.md" if a.ios else "10-research.md"
        return claude_step([prompt], "", a.print_only, model_for("research", a.model))
    if a.command == "spec":
        if not a.proposal:
            sys.exit("spec needs --proposal proposals/<file>.md")
        # The iOS spec template and prompt are not interchangeable with the
        # Android ones: bundle IDs, AdMob, Apple privacy answers, Apple locales.
        prompt = "20-spec-ios.md" if a.ios else "20-spec.md"
        return claude_step([prompt], f"Slug: {a.slug}\nProposal file: {a.proposal}", a.print_only, model_for("spec", a.model))
    if a.command == "generate":
        # The iOS generator drives SwiftUI/XcodeGen from apps-ios/_template and
        # carries the build traps found while verifying that template.
        prompt = "30-generate-ios.md" if a.ios else "30-generate.md"
        return claude_step([prompt], f"Slug: {a.slug}", a.print_only, model_for("generate", a.model))
    if a.command == "fix":
        if not a.run_id:
            sys.exit("fix needs --run-id")
        return claude_step([("40-fix-build-ios.md" if a.ios else "40-fix-build.md")], f"Slug: {a.slug}\nFailing run: {a.run_id}", a.print_only, model_for("fix", a.model))
    if a.command == "listing":
        return claude_step([("50-listing-ios.md" if a.ios else "50-listing.md")], f"Slug: {a.slug}", a.print_only, model_for("listing", a.model))
    if a.command == "privacy":
        return claude_step([("60-privacy-ios.md" if a.ios else "60-privacy.md")], f"Slug: {a.slug}", a.print_only, model_for("privacy", a.model))
    if a.command == "privacy-tags":
        if a.init:
            rc = run([py, "factory/tools/privacy_tags.py", "init", a.slug], a.print_only)
            if rc:
                return rc
        return run([py, "factory/tools/privacy_tags.py", "render", a.slug, "--write"], a.print_only)
    sys.exit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
