#!/usr/bin/env python3
"""
Exercise factory/tools/asc_watch.py against a mock App Store Connect and a fake
`gh` binary, so nothing touches Apple or GitHub.

  python factory/tools/tests/test_asc_watch.py

The fake gh records every invocation to a JSON file, which is how the test
asserts that an issue is opened exactly once per app+version+state and that
in-progress states never open one at all.
"""

from __future__ import annotations

import base64
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
REAL_ROOT = os.path.dirname(os.path.dirname(TOOLS))
WATCH = os.path.join(TOOLS, "asc_watch.py")

ASC_APP_ID = "1234567890"
STATE = {"app_state": "IN_REVIEW"}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args) -> None:
        pass

    def do_GET(self) -> None:
        if not self.headers.get("Authorization", "").startswith("Bearer ey"):
            body = json.dumps({"errors": [{"title": "NOT_AUTHORIZED"}]}).encode()
            self.send_response(401)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        payload = {"data": [{"type": "appStoreVersions", "id": "v1", "attributes": {
            "versionString": "1.0.0", "appStoreState": STATE["app_state"]}}]}
        body = json.dumps(payload).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def make_fake_gh(bin_dir: str, log_path: str, existing_titles_path: str) -> None:
    """A stand-in `gh` that logs calls and answers `issue list` from a JSON file."""
    script = f'''#!/usr/bin/env python3
import json, sys
LOG = {log_path!r}
TITLES = {existing_titles_path!r}
args = sys.argv[1:]
with open(LOG, "a") as fh:
    fh.write(json.dumps(args) + "\\n")
if args[:2] == ["issue", "list"]:
    titles = json.load(open(TITLES))
    print(json.dumps([{{"title": t}} for t in titles]))
elif args[:2] == ["label", "list"]:
    print(json.dumps([]))
elif args[:2] == ["issue", "create"]:
    # Record the new title so a second run in the same test sees it.
    title = args[args.index("--title") + 1]
    titles = json.load(open(TITLES))
    titles.append(title)
    json.dump(titles, open(TITLES, "w"))
    print("https://github.com/fake/repo/issues/1")
sys.exit(0)
'''
    path = os.path.join(bin_dir, "gh")
    with open(path, "w") as fh:
        fh.write(script)
    os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)


def fixture_root(root: str) -> None:
    with open(os.path.join(REAL_ROOT, "factory", "apps.json"), encoding="utf-8") as fh:
        real = json.load(fh)
    reg = {"defaults": real["defaults"], "apps": [
        {"slug": "watched", "platform": "ios", "name": "Watched", "path": "apps-ios/watched",
         "bundle_id": "com.proapps.watched", "asc_app_id": ASC_APP_ID, "store_dir": "s",
         "privacy_path": "p", "spec": "z", "current_version": {"marketing_version": "1.0.0", "build": 1}},
        # No asc_app_id: must be skipped, not crash.
        {"slug": "unregistered", "platform": "ios", "name": "Unregistered", "path": "apps-ios/u",
         "bundle_id": "com.proapps.u", "asc_app_id": "", "store_dir": "s",
         "privacy_path": "p", "spec": "z", "current_version": {"marketing_version": "1.0.0", "build": 1}},
        # Android app: must never be polled.
        {"slug": "android-app", "name": "Android", "path": "apps/a", "package": "com.x.a",
         "store_dir": "s", "privacy_path": "p", "spec": "z"},
    ]}
    os.makedirs(os.path.join(root, "factory"))
    with open(os.path.join(root, "factory", "apps.json"), "w", encoding="utf-8") as fh:
        json.dump(reg, fh)


def throwaway_key_b64() -> str:
    gen = subprocess.run(["openssl", "genpkey", "-algorithm", "EC",
                          "-pkeyopt", "ec_paramgen_curve:P-256", "-outform", "PEM"],
                         capture_output=True, check=True)
    return base64.b64encode(gen.stdout).decode()


def main() -> int:
    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_address[1]}"

    tmp = tempfile.mkdtemp(prefix="asc-watch-")
    root, bin_dir = os.path.join(tmp, "repo"), os.path.join(tmp, "bin")
    os.makedirs(bin_dir)
    fixture_root(root)
    log_path = os.path.join(tmp, "gh.log")
    titles_path = os.path.join(tmp, "titles.json")
    json.dump([], open(titles_path, "w"))
    make_fake_gh(bin_dir, log_path, titles_path)

    env = dict(os.environ,
               ASC_API_BASE=base, FACTORY_ROOT=root,
               ASC_KEY_ID="TESTKEY1234",
               ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000",
               ASC_PRIVATE_KEY_P8=throwaway_key_b64(),
               PATH=bin_dir + os.pathsep + os.environ["PATH"])

    failures = []

    def check(label: str, condition: bool, detail: str = "") -> None:
        print(f"  {'ok  ' if condition else 'FAIL'}  {label}" + (f"\n        {detail}" if not condition else ""))
        if not condition:
            failures.append(label)

    def run(args: list[str]) -> tuple[int, str]:
        proc = subprocess.run([sys.executable, WATCH] + args + ["--repo", "fake/repo"],
                              capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout + proc.stderr

    def gh_calls() -> list[list[str]]:
        if not os.path.exists(log_path):
            return []
        with open(log_path) as fh:
            return [json.loads(l) for l in fh if l.strip()]

    def created_titles() -> list[str]:
        return [c[c.index("--title") + 1] for c in gh_calls() if c[:2] == ["issue", "create"]]

    print("in-progress state (IN_REVIEW):")
    STATE["app_state"] = "IN_REVIEW"
    code, out = run([])
    check("exits 0", code == 0, out)
    check("no issue opened for a state nobody must act on", not created_titles(), out)
    check("only the registered iOS app was polled (android + no-asc_app_id skipped)",
          "android-app" not in out and "unregistered" not in out, out)

    print("\nterminal state (REJECTED):")
    STATE["app_state"] = "REJECTED"
    code, out = run([])
    check("exits 0", code == 0, out)
    titles = created_titles()
    check("exactly one issue opened", len(titles) == 1, str(titles))
    check("title names app, version and state",
          titles and titles[0] == "iOS review: Watched 1.0.0 is now REJECTED", str(titles))
    body_calls = [c for c in gh_calls() if c[:2] == ["issue", "create"]]
    body = body_calls[0][body_calls[0].index("--body") + 1] if body_calls else ""
    check("body tells the human what to do, not just the state",
          "Resolution Center" in body and "guideline" in body, body[:200])

    print("\nsecond run, same state (the idempotency that matters):")
    code, out = run([])
    check("exits 0", code == 0, out)
    check("still exactly one issue -- no daily duplicate", len(created_titles()) == 1,
          str(created_titles()))
    check("run says it was already reported", "already reported" in out, out)

    print("\nstate moves on (READY_FOR_SALE):")
    STATE["app_state"] = "READY_FOR_SALE"
    code, out = run([])
    check("a new state opens a new issue", len(created_titles()) == 2, str(created_titles()))
    check("new title reflects the new state",
          created_titles()[-1] == "iOS review: Watched 1.0.0 is now READY_FOR_SALE",
          str(created_titles()))

    print("\n--dry-run:")
    STATE["app_state"] = "METADATA_REJECTED"
    before = len(created_titles())
    code, out = run(["--dry-run"])
    check("exits 0", code == 0, out)
    check("reports what it would do", "would open issue" in out, out)
    check("creates nothing", len(created_titles()) == before, str(created_titles()))

    server.shutdown()
    shutil.rmtree(tmp, ignore_errors=True)
    print(f"\n{len(failures)} assertion(s) failed" if failures else "\nall assertions passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
