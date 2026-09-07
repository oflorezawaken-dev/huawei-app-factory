#!/usr/bin/env python3
"""
Exercise factory/tools/asc_client.py against a local mock App Store Connect.

  python factory/tools/tests/test_asc_client.py

Serves canned App Store Connect JSON:API responses on localhost, points the
client at them with ASC_API_BASE, and checks that it parses versions, build
processing states and Apple's error envelope. A throwaway P-256 key is
generated per run, so no real credential is ever involved.
"""

from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
REAL_ROOT = os.path.dirname(os.path.dirname(TOOLS))
CLIENT = os.path.join(TOOLS, "asc_client.py")

SLUG = "fixture-app"
ASC_APP_ID = "1234567890"

STATE = {"build_state": "PROCESSING"}


def version_row(state: str) -> dict:
    return {"type": "appStoreVersions", "id": "v1",
            "attributes": {"versionString": "1.0.0", "appStoreState": state, "platform": "IOS"}}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args) -> None:  # keep the test output clean
        pass

    def _send(self, code: int, payload: dict) -> None:
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if not self.headers.get("Authorization", "").startswith("Bearer ey"):
            self._send(401, {"errors": [{"title": "NOT_AUTHORIZED", "detail": "missing bearer token"}]})
            return
        path = self.path.split("?")[0]
        if path == "/v1/apps":
            self._send(200, {"data": [{"type": "apps", "id": ASC_APP_ID,
                                       "attributes": {"name": "Fixture", "bundleId": "com.example.fixture",
                                                      "sku": SLUG}}]})
        elif path == f"/v1/apps/{ASC_APP_ID}":
            self._send(200, {"data": {"type": "apps", "id": ASC_APP_ID,
                                      "attributes": {"name": "Fixture", "bundleId": "com.example.fixture",
                                                     "sku": SLUG}}})
        elif path == f"/v1/apps/{ASC_APP_ID}/appStoreVersions":
            self._send(200, {"data": [version_row("WAITING_FOR_REVIEW")]})
        elif path == "/v1/builds":
            # First poll reports PROCESSING, the next one VALID.
            state = STATE["build_state"]
            STATE["build_state"] = "VALID"
            self._send(200, {"data": [{"type": "builds", "id": "b1",
                                       "attributes": {"version": "1", "processingState": state,
                                                      "uploadedDate": "2026-09-05T10:00:00Z"}}]})
        elif path == "/v1/apps/404":
            self._send(404, {"errors": [{"status": "404", "code": "NOT_FOUND",
                                         "title": "The resource does not exist",
                                         "detail": "There is no app with ID 404"}]})
        else:
            self._send(404, {"errors": [{"title": "NOT_FOUND", "detail": path}]})


def fixture_root(asc_app_id: str = ASC_APP_ID) -> str:
    root = tempfile.mkdtemp(prefix="asc-test-")
    with open(os.path.join(REAL_ROOT, "factory", "apps.json"), encoding="utf-8") as fh:
        real = json.load(fh)
    reg = {"defaults": real["defaults"], "apps": [{
        "slug": SLUG, "platform": "ios", "name": "Fixture", "path": f"apps-ios/{SLUG}",
        "bundle_id": "com.example.fixture", "asc_app_id": asc_app_id, "sku": SLUG,
        "spec": f"specifications/{SLUG}.json", "store_dir": f"apps-ios/{SLUG}/store",
        "privacy_path": f"docs/{SLUG}/privacy", "support_path": f"docs/{SLUG}/support",
        "current_version": {"marketing_version": "1.0.0", "build": 1},
    }]}
    os.makedirs(os.path.join(root, "factory"))
    with open(os.path.join(root, "factory", "apps.json"), "w", encoding="utf-8") as fh:
        json.dump(reg, fh, indent=2)
    return root


def throwaway_key_b64() -> str:
    gen = subprocess.run(["openssl", "genpkey", "-algorithm", "EC",
                          "-pkeyopt", "ec_paramgen_curve:P-256", "-outform", "PEM"],
                         capture_output=True, check=True)
    return base64.b64encode(gen.stdout).decode()


def main() -> int:
    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_address[1]}"

    env = dict(os.environ,
               ASC_API_BASE=base,
               ASC_KEY_ID="TESTKEY1234",
               ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000",
               ASC_PRIVATE_KEY_P8=throwaway_key_b64())

    failures = []

    def run(args: list[str], root: str) -> tuple[int, str]:
        proc = subprocess.run([sys.executable, CLIENT] + args, capture_output=True, text=True,
                              env=dict(env, FACTORY_ROOT=root))
        return proc.returncode, proc.stdout + proc.stderr

    def check(label: str, condition: bool, detail: str = "") -> None:
        print(f"  {'ok  ' if condition else 'FAIL'}  {label}" + (f"\n        {detail}" if not condition else ""))
        if not condition:
            failures.append(label)

    root = fixture_root()

    code, out = run(["apps"], root)
    check("apps lists the account's apps", code == 0 and ASC_APP_ID in out and "com.example.fixture" in out, out)

    code, out = run(["app", SLUG], root)
    check("app resolves the slug and matches bundle IDs", code == 0 and '"name": "Fixture"' in out, out)

    code, out = run(["versions", SLUG], root)
    check("versions reports the App Store state", code == 0 and "WAITING_FOR_REVIEW" in out, out)

    code, out = run(["state", SLUG], root)
    check("state prints just the state", code == 0 and out.splitlines()[0] == "WAITING_FOR_REVIEW", out)

    code, out = run(["builds", SLUG], root)
    check("builds reports processing state", code == 0 and "PROCESSING" in out, out)

    STATE["build_state"] = "PROCESSING"
    code, out = run(["wait-build", SLUG, "--build", "1", "--timeout", "90"], root)
    check("wait-build polls until the build is VALID", code == 0 and "VALID" in out, out)

    # Registry without asc_app_id: the error must name the missing human step.
    empty = fixture_root(asc_app_id="")
    code, out = run(["state", SLUG], empty)
    check("missing asc_app_id explains the console step",
          code == 1 and "asc_app_id" in out and "App Store Connect" in out, out)

    # Apple's error envelope must surface as a readable message.
    notfound = fixture_root(asc_app_id="404")
    code, out = run(["app", SLUG], notfound)
    check("HTTP 404 surfaces Apple's error detail",
          code == 1 and "404" in out and "There is no app with ID 404" in out, out)

    # A malformed key must fail loudly rather than send an unsigned request.
    proc = subprocess.run([sys.executable, CLIENT, "apps"], capture_output=True, text=True,
                          env=dict(env, FACTORY_ROOT=root, ASC_PRIVATE_KEY_P8="not-base64!!"))
    check("a bad private key is rejected before any request",
          proc.returncode == 1 and "not valid base64" in (proc.stdout + proc.stderr),
          proc.stdout + proc.stderr)

    # No command may ever print the signed token.
    code, out = run(["apps"], root)
    check("the JWT never reaches stdout", not re.search(r"eyJ[\w-]+\.eyJ[\w-]+\.", out), out)

    server.shutdown()
    print(f"\n{len(failures)} assertion(s) failed" if failures else "\nall assertions passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
