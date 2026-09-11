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
import struct
import threading
import zlib
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
    "copyright": None,
    "next_id": 100,
    # Set to simulate Apple refusing the version: the reviewSubmissionItems
    # POST is the only place that failure surfaces.
    "reject_review_item": False,
    # What the diagnosis probes find. None means the endpoint 404s, which is
    # how a requirement the console has never touched behaves.
    "price_schedule": {"id": "ps1"},
    "age_rating": {"id": "ar1"},
    "data_usages": [{"id": "du1"}],
    "review_detail": {"id": "rd1", "attributes": {
        "contactFirstName": "Ada", "contactLastName": "Byron",
        "contactEmail": "ada@example.com", "contactPhone": "+1000000000"}},
    "build_encryption": False,
    # What Apple reports once it has looked at the uploaded image.
    "asset_state": {"state": "COMPLETE", "errors": []},
    # Apple's in-app purchases for this app, and how they come back.
    "iaps": [{"type": "inAppPurchases", "id": "iap1",
              "attributes": {"productId": "com.example.fixture.removeads",
                             "state": "READY_TO_SUBMIT"}}],
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

    def _maybe(self, row) -> None:
        """A to-one relationship: None = set up but empty, "404" = no such path.

        The two are different answers and the diagnosis must not conflate them:
        an empty relationship means the requirement is unmet, while a 404 might
        just mean this probe's URL is wrong, which says nothing about the app.
        """
        if row == "404":
            self._json(404, {"errors": [{"title": "NOT_FOUND"}]})
        else:
            self._json(200, {"data": row})

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
        elif path.startswith("/v1/appScreenshots/"):
            # Apple validates the image asynchronously: the reservation and the
            # PATCH both succeed even for an image it goes on to reject.
            shot_id = path.rsplit("/", 1)[-1]
            self._json(200, {"data": {"type": "appScreenshots", "id": shot_id,
                                      "attributes": {"assetDeliveryState": STATE["asset_state"]}}})
        elif "/appScreenshotSets/" in path and path.endswith("/appScreenshots"):
            set_id = path.split("/appScreenshotSets/")[1].split("/")[0]
            rows = [{"id": sid} for sid, shot in STATE["screenshots"].items()
                    if shot.get("set") == set_id]
            self._json(200, {"data": rows})
        elif path.endswith("/appScreenshotSets"):
            # Apple IGNORES filter[screenshotDisplayType] and returns every set
            # for the localization. Honouring it here is what hid the bug that
            # sent the iPad images into the iPhone set, so the mock must be as
            # unhelpful as Apple is and always return the lot.
            rows = [{"id": sid, "attributes": {"screenshotDisplayType": dt}}
                    for dt, sid in STATE["screenshot_sets"].items()]
            self._json(200, {"data": rows})
        elif path == f"/v1/apps/{ASC_APP_ID}/inAppPurchasesV2":
            self._json(200, {"data": STATE["iaps"]})
        elif path == f"/v1/apps/{ASC_APP_ID}/reviewSubmissions":
            rows = [{"type": "reviewSubmissions", "id": sid, "attributes": sub["attributes"]}
                    for sid, sub in STATE["submissions"].items()]
            self._json(200, {"data": rows})
        elif path == f"/v1/apps/{ASC_APP_ID}/appPriceSchedule":
            self._maybe(STATE["price_schedule"])
        elif path == f"/v1/appInfos/{APP_INFO_ID}/ageRatingDeclaration":
            self._maybe(STATE["age_rating"])
        elif path == f"/v1/apps/{ASC_APP_ID}/appDataUsages":
            self._json(200, {"data": STATE["data_usages"]})
        elif path == f"/v1/appStoreVersions/{VERSION_ID}/appStoreReviewDetail":
            self._maybe(STATE["review_detail"])
        elif path == f"/v1/apps/{ASC_APP_ID}/builds":
            self._json(200, {"data": [{"type": "builds", "id": "b1", "attributes": {
                "version": "3", "processingState": "VALID",
                "usesNonExemptEncryption": STATE["build_encryption"]}}]})
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
            # Apple refuses a duplicate set with 409 rather than returning the
            # existing one. Faking it as idempotent is what let the real bug
            # through: the second screenshot of every locale aborted the run.
            if display_type in STATE["screenshot_sets"]:
                self._json(409, {"errors": [{
                    "title": "The request cannot be fulfilled because of the state of another resource.",
                    "detail": "Screenshot Set Already Exists!"}]})
                return
            set_id = STATE["screenshot_sets"].setdefault(display_type, new_id())
            self._json(201, {"data": {"type": rtype, "id": set_id}})
        elif rtype == "appScreenshots":
            shot_id = new_id()
            set_id = data["relationships"]["appScreenshotSet"]["data"]["id"]
            STATE["screenshots"][shot_id] = {"uploaded": False, "checksum": None, "set": set_id}
            port = self.server.server_address[1]
            self._json(201, {"data": {"type": rtype, "id": shot_id, "attributes": {
                "uploadOperations": [{"method": "PUT", "url": f"http://127.0.0.1:{port}/upload/{shot_id}",
                                      "offset": 0, "length": 999999, "requestHeaders": []}]}}})
        elif rtype == "reviewSubmissions":
            sub_id = new_id()
            STATE["submissions"][sub_id] = {"attributes": {"submitted": False}, "items": []}
            self._json(201, {"data": {"type": rtype, "id": sub_id}})
        elif rtype == "reviewSubmissionItems":
            if "inAppPurchaseV2" in data["relationships"]:
                # Apple: 'inAppPurchaseV2' is not a relationship on the resource
                # 'reviewSubmissionItems'. The mock said yes to it for a whole
                # submission attempt.
                self._json(409, {"errors": [{
                    "title": "The provided entity includes an unknown relationship",
                    "detail": "'inAppPurchaseV2' is not a relationship on the resource "
                              "'reviewSubmissionItems'"}]})
                return
            iap = data["relationships"].get("inAppPurchase")
            if iap:
                sub_id = data["relationships"]["reviewSubmission"]["data"]["id"]
                STATE["submissions"][sub_id].setdefault("iaps", []).append(iap["data"]["id"])
                self._json(201, {"data": {"type": rtype, "id": new_id()}})
                return
            if STATE["reject_review_item"]:
                self._json(409, {"errors": [{
                    "title": "The request cannot be fulfilled because of the state of another resource.",
                    "detail": "The specified resource is not in valid state to be submitted."}]})
                return
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
            attrs = data.get("attributes", {})
            if "copyright" in attrs:
                STATE["copyright"] = attrs["copyright"]
            build_rel = data.get("relationships", {}).get("build", {}).get("data")
            if build_rel:
                STATE["attached_build"] = build_rel.get("id")
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
        elif rtype == "reviewSubmissions" and data.get("attributes", {}).get("canceled"):
            STATE["submissions"].pop(rid, None)
            STATE["cancelled_submissions"] = STATE.get("cancelled_submissions", 0) + 1
            self._json(200, {"data": {"type": rtype, "id": rid}})
        elif rtype == "reviewSubmissions":
            if not STATE["submissions"][rid]["items"]:
                self._json(422, {"errors": [{"title": "NO_ITEMS", "detail": "add an item before submitting"}]})
                return
            STATE["submissions"][rid]["attributes"]["submitted"] = data["attributes"].get("submitted")
            self._json(200, {"data": {"type": rtype, "id": rid}})
        else:
            self._json(404, {"errors": [{"title": "NOT_FOUND"}]})

    def do_DELETE(self) -> None:
        if not self._authed():
            self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
            return
        rid = self.path.rsplit("/", 1)[-1]
        if "/reviewSubmissions/" in self.path:
            # Apple forbids this outright; the mock used to accept it.
            self._json(403, {"errors": [{
                "title": "The given operation is not allowed",
                "detail": "The resource 'reviewSubmissions' does not allow 'DELETE'."}]})
            return
        if False:
            pass
        else:
            STATE["screenshots"].pop(rid, None)
            STATE["deleted_screenshots"] = STATE.get("deleted_screenshots", 0) + 1
        self.send_response(204)
        self.end_headers()

    def do_PUT(self) -> None:
        # Screenshot byte upload: any body, any auth (Apple's asset URLs are pre-signed).
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        self.send_response(204)
        self.end_headers()


def write_png(path: str, width: int, height: int) -> None:
    """A real, valid PNG of solid black at the requested size."""
    raw = (b"\x00" + b"\x00" * (width * 3)) * height

    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + tag + payload
                + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    with open(path, "wb") as fh:
        fh.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
                 + chunk(b"IDAT", zlib.compress(raw, 1)) + chunk(b"IEND", b""))


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
    # Real dimensions, because asc_metadata routes each image to a screenshot
    # set by its pixel size. Two iPhone-sized files (one alone would never reach
    # the "set already exists" path that actually broke) plus one iPad-sized,
    # which proves the routing sends them to different sets.
    shots_dir = os.path.join(store, "screenshots", "en")
    for name, (w, h) in (("01.png", (1320, 2868)), ("02.png", (1320, 2868)),
                         ("ipad-01.png", (2064, 2752))):
        write_png(os.path.join(shots_dir, name), w, h)
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

    # listing.json carries no URLs at all: these must come from the registry's
    # privacy_path/support_path, which is what the app actually published.
    info_attrs = STATE["app_info_locs"].get("en-US", {}).get("attrs", {})
    ver_attrs = STATE["version_locs"].get("en-US", {}).get("attrs", {})
    check("privacy policy URL derived from the registry path",
          info_attrs.get("privacyPolicyUrl", "").endswith(f"/{SLUG}/privacy/"),
          str(info_attrs))
    check("support URL derived from the registry path",
          ver_attrs.get("supportUrl", "").endswith(f"/{SLUG}/support/"),
          str(ver_attrs))
    check("copyright written to the version itself, as '<year> <holder>'",
          bool(STATE["copyright"]) and STATE["copyright"].split(" ", 1)[0].isdigit(),
          str(STATE["copyright"]))

    # Second run must PATCH the existing rows, not create duplicates.
    before_count = len(STATE["app_info_locs"])
    code, out = run(METADATA, [SLUG, "--what", "text"])
    check("second run updates in place (no duplicate rows)",
          code == 0 and len(STATE["app_info_locs"]) == before_count, out)

    print("\nasc_metadata.py --what screenshots:")
    code, out = run(METADATA, [SLUG, "--what", "screenshots"])
    check("exits 0", code == 0, out)
    check("a set was created for each device, routed by the image's pixel size",
          "APP_IPHONE_67" in STATE["screenshot_sets"]
          and "APP_IPAD_PRO_3GEN_129" in STATE["screenshot_sets"],
          str(sorted(STATE["screenshot_sets"])))
    check("the two iPhone images share one set -- the second is what proves the "
          "set is reused rather than re-created",
          STATE["screenshot_sets"]["APP_IPHONE_67"] != STATE["screenshot_sets"]["APP_IPAD_PRO_3GEN_129"],
          str(STATE["screenshot_sets"]))
    uploaded = [s for s in STATE["screenshots"].values() if s["uploaded"]]
    check("all three screenshots uploaded, each with a checksum",
          len(uploaded) == 3 and all(s["checksum"] for s in uploaded), out)

    # Apple caps a set at 10. Without replacement a third push of five images
    # fails with "Too many screenshots", which is how PriceJar's set filled up.
    code, out = run(METADATA, [SLUG, "--what", "screenshots"])
    check("a second push replaces rather than accumulates", code == 0, out)
    check("still exactly three screenshots after the second push",
          len([s for s in STATE["screenshots"].values() if s["uploaded"]]) == 3,
          str(len(STATE["screenshots"])))
    check("the previous three were deleted", STATE.get("deleted_screenshots") == 3,
          str(STATE.get("deleted_screenshots")))

    # Apple validates the image after the PATCH. Reporting "uploaded" off a
    # 200 is how five screenshots were declared pushed while the version page
    # showed five empty frames with a red warning.
    STATE["asset_state"] = {"state": "FAILED", "errors": [
        {"code": "IMAGE_WRONG_DIMENSIONS", "description": "Image dimensions are wrong"}]}
    code, out = run(METADATA, [SLUG, "--what", "screenshots"])
    check("a rejected image fails the push instead of reporting success", code != 0, out)
    check("and repeats Apple's reason for rejecting it",
          "IMAGE_WRONG_DIMENSIONS" in out and "Image dimensions are wrong" in out, out)
    check("the failure names the file Apple rejected", ".png" in out, out)

    STATE["asset_state"] = {"state": "AWAITING_UPLOAD", "errors": []}
    code, out = run(METADATA, [SLUG, "--what", "screenshots", "--asset-timeout", "1"])
    check("an image Apple never finishes processing is a failure, not a success",
          code != 0 and "never finished processing" in out, out)

    STATE["asset_state"] = {"state": "COMPLETE", "errors": []}

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

    print("\na version that sells something must carry the purchase:")
    # "Ready to Submit" is configured-and-waiting, not submitted. PriceJar 1.0.0
    # (4) was rejected because the version went in without the product.
    asc_publish.submit_for_review(ASC_APP_ID, None, "com.example.fixture.removeads")
    with_iap = [s for s in STATE["submissions"].values() if s.get("iaps")]
    check("the in-app purchase is added as its own submission item",
          len(with_iap) == 1 and with_iap[0]["iaps"] == ["iap1"],
          str([s.get("iaps") for s in STATE["submissions"].values()]))

    print("\nan unfinished purchase stops the submission instead of repeating the rejection:")
    STATE["iaps"] = [{"type": "inAppPurchases", "id": "iap1",
                      "attributes": {"productId": "com.example.fixture.removeads",
                                     "state": "MISSING_METADATA"}}]
    try:
        asc_publish.submit_for_review(ASC_APP_ID, None, "com.example.fixture.removeads")
        msg = ""
    except asc_publish.ASCError as exc:
        msg = str(exc)
    check("raises rather than submitting without the product", bool(msg), msg)
    check("names the product and the state Apple reports",
          "com.example.fixture.removeads" in msg and "MISSING_METADATA" in msg, msg)
    STATE["iaps"] = [{"type": "inAppPurchases", "id": "iap1",
                      "attributes": {"productId": "com.example.fixture.removeads",
                                     "state": "READY_TO_SUBMIT"}}]

    print("\nApple refuses the version -- diagnose it, and leave nothing behind:")
    # Apple's own error says only "not in valid state", so the run has to ask
    # the API which console-only requirements are unmet. Half are set here and
    # half are not, so a diagnosis that just prints the whole checklist fails.
    STATE["reject_review_item"] = True
    STATE["price_schedule"] = None                             # never set
    STATE["data_usages"] = []                                  # unanswered
    STATE["review_detail"]["attributes"]["contactPhone"] = ""   # half filled
    STATE["build_encryption"] = None                           # unanswered
    before = len(STATE["submissions"])
    try:
        asc_publish.submit_for_review(ASC_APP_ID, None)
        check("raises when Apple refuses the version", False)
        msg = ""
    except asc_publish.ASCError as exc:
        msg = str(exc)
        check("raises when Apple refuses the version", True)
    check("reports Pricing as unmet", "!!  Pricing" in msg, msg)
    check("reports the App Privacy questionnaire as unmet", "!!  App Privacy" in msg, msg)
    check("names the contact field that is actually blank", "contactPhone" in msg, msg)
    check("reports export compliance as unmet", "!!  Export compliance" in msg, msg)
    check("does NOT flag the age rating, which is set -- the diagnosis has to "
          "distinguish, not list the whole checklist", "!!  Age rating" not in msg, msg)
    check("leaves no open submission behind to block the retry",
          len(STATE["submissions"]) == before,
          f"{before} before, {len(STATE['submissions'])} after")

    print("\na probe whose endpoint 404s must not accuse the app:")
    # These probe URLs are not exercised anywhere else, so one of them being
    # wrong is a live risk. A wrong URL must degrade to "I could not check",
    # never to "this requirement is unmet" -- otherwise the report sends you
    # to fix something in the console that was never broken.
    STATE["age_rating"] = "404"
    try:
        asc_publish.submit_for_review(ASC_APP_ID, None)
        msg = ""
    except asc_publish.ASCError as exc:
        msg = str(exc)
    check("a 404 reports 'could not check', not 'unmet'",
          "?  Age rating" in msg and "!!  Age rating" not in msg, msg)
    STATE["age_rating"] = {"id": "ar1"}

    print("\na stale open submission from an earlier failed run:")
    STATE["reject_review_item"] = False
    stale = new_id()
    STATE["submissions"][stale] = {"attributes": {"submitted": False}, "items": []}
    # asc_publish.main calls this BEFORE touching the version, because adding a
    # version to a submission locks it against every metadata edit: a run that
    # died mid-way left the version unreachable until the submission was gone.
    asc_publish.clear_open_review_submission(ASC_APP_ID, None)
    check("is cancelled, not left to lock the version", stale not in STATE["submissions"],
          str(sorted(STATE["submissions"])))
    check("cancelled by PATCH, which is the only verb Apple allows",
          STATE.get("cancelled_submissions", 0) > 0,
          f"cancelled={STATE.get('cancelled_submissions')}")

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
