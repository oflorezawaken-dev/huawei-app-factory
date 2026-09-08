#!/usr/bin/env python3
"""
Exercise the write paths of asc_metadata.py and asc_publish.py against a local
mock App Store Connect: text metadata (create + update), screenshot upload
(reserve/PUT/commit), attaching a build to a version, setting release notes,
and the reviewSubmissions -> reviewSubmissionItems -> submitted:true sequence.

  python factory/tools/tests/test_asc_write_paths.py

A throwaway P-256 key is generated per run; nothing here touches Apple or the
real registry (FACTORY_ROOT points at a temp tree).
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
REAL_ROOT = os.path.dirname(os.path.dirname(TOOLS))
METADATA = os.path.join(TOOLS, "asc_metadata.py")
PUBLISH = os.path.join(TOOLS, "asc_publish.py")

SLUG = "fixture-app"
ASC_APP_ID = "1234567890"
VERSION_ID = "v1"
APP_INFO_ID = "info1"

STATE = {
    "app_info_locs": {},      # locale -> {id, attrs}
    "version_locs": {},       # locale -> {id, attrs}
    "screenshot_sets": {},    # display_type -> id
    "screenshots": {},        # id -> {uploaded, checksum}
    "submissions": {},        # id -> {"attributes": {...}, "items": [...]}
    "attached_build": None,
    "next_id": 100,
}


def new_id() -> str:
    STATE["next_id"] += 1
    return str(STATE["next_id"])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args) -> None:
        pass

    def _json(self, code: int, payload: dict) -> None:
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length) if length else b""
        return json.loads(raw) if raw else {}

    def _authed(self) -> bool:
        return self.headers.get("Authorization", "").startswith("Bearer ey")

    def do_GET(self) -> None:
        if not self._authed():
            self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
            return
        path, _, query = self.path.partition("?")
        params = dict(p.split("=", 1) for p in query.split("&") if "=" in p)

        if path == f"/v1/apps/{ASC_APP_ID}/appInfos":
            self._json(200, {"data": [{"type": "appInfos", "id": APP_INFO_ID}]})
        elif path == f"/v1/apps/{ASC_APP_ID}/appStoreVersions":
            self._json(200, {"data": [{"type": "appStoreVersions", "id": VERSION_ID,
                                       "attributes": {"versionString": "1.0.0",
                                                      "appStoreVersionState": "PREPARE_FOR_SUBMISSION"}}]})
        elif path == f"/v1/appInfos/{APP_INFO_ID}/appInfoLocalizations":
            locale = params.get("filter[locale]")
            row = STATE["app_info_locs"].get(locale)
            self._json(200, {"data": [{"id": row["id"]}] if row else []})
        elif path == f"/v1/appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations":
            locale = params.get("filter[locale]")
            if locale:
                row = STATE["version_locs"].get(locale)
                self._json(200, {"data": [{"id": row["id"]}] if row else []})
            else:
                rows = [{"id": r["id"], "attributes": {"locale": loc}}
                        for loc, r in STATE["version_locs"].items()]
                self._json(200, {"data": rows[:1]})
        elif path == "/v1/builds":
            self._json(200, {"data": [{"type": "builds", "id": "b1",
                                       "attributes": {"version": "3", "processingState": "VALID"}}]})
        else:
            self._json(404, {"errors": [{"title": "NOT_FOUND", "detail": path}]})

    def do_POST(self) -> None:
        if not self._authed():
            self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
            return
        body = self._body()
        data = body.get("data", {})
        rtype = data.get("type")

        if rtype == "appInfoLocalizations":
            locale = data["attributes"]["locale"]
            row = {"id": new_id(), "attrs": {k: v for k, v in data["attributes"].items() if k != "locale"}}
            STATE["app_info_locs"][locale] = row
            self._json(201, {"data": {"type": rtype, "id": row["id"]}})
        elif rtype == "appStoreVersionLocalizations":
            locale = data["attributes"]["locale"]
            row = {"id": new_id(), "attrs": {k: v for k, v in data["attributes"].items() if k != "locale"}}
            STATE["version_locs"][locale] = row
            self._json(201, {"data": {"type": rtype, "id": row["id"]}})
        elif rtype == "appScreenshotSets":
            display_type = data["attributes"]["screenshotDisplayType"]
            set_id = STATE["screenshot_sets"].setdefault(display_type, new_id())
            self._json(201, {"data": {"type": rtype, "id": set_id}})
        elif rtype == "appScreenshots":
            shot_id = new_id()
            STATE["screenshots"][shot_id] = {"uploaded": False, "checksum": None}
            port = self.server.server_address[1]
            self._json(201, {"data": {"type": rtype, "id": shot_id, "attributes": {
                "uploadOperations": [{"method": "PUT", "url": f"http://127.0.0.1:{port}/upload/{shot_id}",
                                      "offset": 0, "length": 999999, "requestHeaders": []}]}}})
        elif rtype == "reviewSubmissions":
            sub_id = new_id()
            STATE["submissions"][sub_id] = {"attributes": {"submitted": False}, "items": []}
            self._json(201, {"data": {"type": rtype, "id": sub_id}})
        elif rtype == "reviewSubmissionItems":
            sub_id = data["relationships"]["reviewSubmission"]["data"]["id"]
            version_id = data["relationships"]["appStoreVersion"]["data"]["id"]
            STATE["submissions"][sub_id]["items"].append(version_id)
            self._json(201, {"data": {"type": rtype, "id": new_id()}})
        else:
            self._json(400, {"errors": [{"title": "UNKNOWN_TYPE", "detail": str(rtype)}]})

    def do_PATCH(self) -> None:
        if not self._authed():
            self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
            return
        body = self._body()
        data = body.get("data", {})
        rtype, rid = data.get("type"), data.get("id")

        if rtype == "appStoreVersions" and rid == VERSION_ID:
            STATE["attached_build"] = data.get("relationships", {}).get("build", {}).get("data", {}).get("id")
            self._json(200, {"data": {"type": rtype, "id": rid}})
        elif rtype == "appStoreVersionLocalizations":
            attrs = data.get("attributes", {})
            # Apple refuses whatsNew on a first version -- there is no previous
            # release for anything to be new relative to -- and rejects the
            # whole PATCH with 409 rather than ignoring the one field.
            if STATE.get("reject_whats_new") and "whatsNew" in attrs:
                self._json(409, {"errors": [{
                    "title": "The request cannot be fulfilled because of the state of another resource.",
                    "detail": "Attribute 'whatsNew' cannot be edited at this time"}]})
                return
            for loc, row in STATE["version_locs"].items():
                if row["id"] == rid:
                    row["attrs"].update(attrs)
            self._json(200, {"data": {"type": rtype, "id": rid}})
        elif rtype == "appScreenshots":
            STATE["screenshots"][rid]["uploaded"] = data["attributes"].get("uploaded")
            STATE["screenshots"][rid]["checksum"] = data["attributes"].get("sourceFileChecksum")
            self._json(200, {"data": {"type": rtype, "id": rid}})
        elif rtype == "appInfoLocalizations":
            for loc, row in STATE["app_info_locs"].items():
                if row["id"] == rid:
                    row["attrs"].update(data.get("attributes", {}))
            self._json(200, {"data": {"type": rtype, "id": rid}})
        elif rtype == "reviewSubmissions":
            if not STATE["submissions"][rid]["items"]:
                self._json(422, {"errors": [{"title": "NO_ITEMS", "detail": "add an item before submitting"}]})
                return
            STATE["submissions"][rid]["attributes"]["submitted"] = data["attributes"].get("submitted")
            self._json(200, {"data": {"type": rtype, "id": rid}})
        else:
            self._json(404, {"errors": [{"title": "NOT_FOUND"}]})

    def do_PUT(self) -> None:
        # Screenshot byte upload: any body, any auth (Apple's asset URLs are pre-signed).
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        self.send_response(204)
        self.end_headers()


def fixture_root() -> str:
    root = tempfile.mkdtemp(prefix="asc-write-")
    with open(os.path.join(REAL_ROOT, "factory", "apps.json"), encoding="utf-8") as fh:
        real = json.load(fh)
    reg = {"defaults": real["defaults"], "apps": [{
        "slug": SLUG, "platform": "ios", "name": "Fixture", "path": f"apps-ios/{SLUG}",
        "bundle_id": "com.example.fixture", "asc_app_id": ASC_APP_ID, "sku": SLUG,
        "spec": f"specifications/{SLUG}.json", "store_dir": f"apps-ios/{SLUG}/store",
        "privacy_path": f"docs/{SLUG}/privacy", "support_path": f"docs/{SLUG}/support",
        "current_version": {"marketing_version": "1.0.0", "build": 3},
    }]}
    os.makedirs(os.path.join(root, "factory"))
    with open(os.path.join(root, "factory", "apps.json"), "w", encoding="utf-8") as fh:
        json.dump(reg, fh, indent=2)

    store = os.path.join(root, f"apps-ios/{SLUG}/store")
    os.makedirs(os.path.join(store, "screenshots", "en"))
    with open(os.path.join(store, "listing.json"), "w", encoding="utf-8") as fh:
        json.dump({"languages": [
            {"lang": "en-US", "name": "Fixture", "subtitle": "Sub", "description": "Desc",
             "keywords": "a,b,c", "promotional_text": "Promo", "release_notes": "Notes",
             "privacy_policy_url": "https://example.com/privacy", "support_url": "https://example.com/support"},
        ]}, fh)
    # A tiny valid PNG, content does not matter for these tests.
    png = bytes.fromhex(
        "89504e470d0a1a0a0000000d49484452000000010000000108020000009077"
        "53de0000000c4944415478da6360606060000000050001a5f645400000000049454e44ae426082")
    with open(os.path.join(store, "screenshots", "en", "01.png"), "wb") as fh:
        fh.write(png)
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

    env = dict(os.environ, ASC_API_BASE=base, ASC_KEY_ID="TESTKEY1234",
              ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000",
              ASC_PRIVATE_KEY_P8=throwaway_key_b64())
    root = fixture_root()
    env["FACTORY_ROOT"] = root

    failures = []

    def run(tool: str, args: list[str]) -> tuple[int, str]:
        proc = subprocess.run([sys.executable, tool] + args, capture_output=True, text=True, env=env)
        return proc.returncode, proc.stdout + proc.stderr

    def check(label: str, condition: bool, detail: str = "") -> None:
        print(f"  {'ok  ' if condition else 'FAIL'}  {label}" + (f"\n        {detail}" if not condition else ""))
        if not condition:
            failures.append(label)

    print("asc_metadata.py --what text:")
    code, out = run(METADATA, [SLUG, "--what", "text"])
    check("exits 0", code == 0, out)
    check("app info localization created", "en-US" in STATE["app_info_locs"], out)
    check("name/subtitle went to appInfoLocalizations",
          STATE["app_info_locs"].get("en-US", {}).get("attrs", {}).get("name") == "Fixture", out)
    check("description went to appStoreVersionLocalizations, not appInfo",
          "description" not in STATE["app_info_locs"].get("en-US", {}).get("attrs", {})
          and STATE["version_locs"].get("en-US", {}).get("attrs", {}).get("description") == "Desc", out)

    # Second run must PATCH the existing rows, not create duplicates.
    before_count = len(STATE["app_info_locs"])
    code, out = run(METADATA, [SLUG, "--what", "text"])
    check("second run updates in place (no duplicate rows)",
          code == 0 and len(STATE["app_info_locs"]) == before_count, out)

    print("\nasc_metadata.py --what screenshots:")
    code, out = run(METADATA, [SLUG, "--what", "screenshots"])
    check("exits 0", code == 0, out)
    check("a screenshot set was created for the 6.9in display type",
          "APP_IPHONE_69" in STATE["screenshot_sets"], out)
    uploaded = [s for s in STATE["screenshots"].values() if s["uploaded"]]
    check("the screenshot was marked uploaded with a checksum",
          len(uploaded) == 1 and uploaded[0]["checksum"], out)

    print("\nasc_publish.py --attach:")
    code, out = run(PUBLISH, [SLUG, "--ipa", os.path.join(root, "fake.ipa"), "--attach", "--dry-run"])
    # --dry-run never touches the filesystem or the API; the .ipa need not exist.
    check("dry-run explains what it would do without requiring the ipa to exist",
          code == 0 and "would" in out.lower(), out)

    # For the network-touching assertions below, call the same functions
    # asc_publish's subprocess invocations use, but in-process; they need the
    # ASC_* credentials in this process's own environment to sign a token.
    os.environ.update(env)
    sys.path.insert(0, TOOLS)
    import asc_publish  # noqa: E402

    token = None  # asc_publish.make_token() re-signs each call; fine for a mock
    asc_publish.attach_build(VERSION_ID, "b1", None)
    check("attach_build recorded the build on the mock version",
          STATE["attached_build"] == "b1")

    asc_publish.set_release_notes(VERSION_ID, "Fixes the watering reminder.", None)
    check("release notes landed on the existing locale row",
          STATE["version_locs"]["en-US"]["attrs"].get("whatsNew") == "Fixes the watering reminder.")

    asc_publish.submit_for_review(ASC_APP_ID, None)
    submitted = [s for s in STATE["submissions"].values() if s["attributes"]["submitted"]]
    check("exactly one submission ended up submitted:true", len(submitted) == 1)
    check("that submission has the version attached as an item",
          bool(submitted) and VERSION_ID in submitted[0]["items"])

    print("\na first version rejects whatsNew; the rest of the listing still lands:")
    STATE["reject_whats_new"] = True
    STATE["version_locs"]["en-US"]["attrs"].pop("description", None)
    code, out = run(METADATA, [SLUG, "--what", "text"])
    check("exits 0 instead of aborting the whole listing", code == 0, out)
    check("says which attribute Apple refused", "whatsNew" in out and "will not accept" in out, out)
    check("description still got through on the retry",
          STATE["version_locs"]["en-US"]["attrs"].get("description") == "Desc", out)
    STATE["reject_whats_new"] = False

    print("\nupload() treats error -19232 (build already present) as non-fatal:")
    import subprocess as _subprocess

    class FakeCompleted:
        def __init__(self, returncode, stdout):
            self.returncode, self.stdout, self.stderr = returncode, stdout, ""

    real_run = _subprocess.run

    def fake_run_already_uploaded(cmd, **kwargs):
        if cmd[:2] == ["xcrun", "altool"]:
            return FakeCompleted(1, "ERROR: The provided entity includes an attribute with a "
                                   "value that has already been used (-19232) The bundle version "
                                   "must be higher than the previously uploaded version: '1'.")
        return real_run(cmd, **kwargs)

    def fake_run_other_failure(cmd, **kwargs):
        if cmd[:2] == ["xcrun", "altool"]:
            return FakeCompleted(1, "ERROR: some unrelated failure")
        return real_run(cmd, **kwargs)

    _subprocess.run = fake_run_already_uploaded
    try:
        asc_publish.upload(os.path.join(root, "fake.ipa"), "TESTKEY1234")
        check("does not raise on -19232", True)
    except asc_publish.ASCError:
        check("does not raise on -19232", False)
    finally:
        _subprocess.run = real_run

    _subprocess.run = fake_run_other_failure
    try:
        asc_publish.upload(os.path.join(root, "fake.ipa"), "TESTKEY1234")
        check("still raises on an unrelated altool failure", False)
    except asc_publish.ASCError:
        check("still raises on an unrelated altool failure", True)
    finally:
        _subprocess.run = real_run

    server.shutdown()
    print(f"\n{len(failures)} assertion(s) failed" if failures else "\nall assertions passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
