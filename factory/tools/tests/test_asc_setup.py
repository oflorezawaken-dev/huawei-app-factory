#!/usr/bin/env python3
"""
Exercise asc_setup.py -- creating the appStoreVersion and the whole in-app
purchase -- against a local mock App Store Connect.

  python factory/tools/tests/test_asc_setup.py

The mock is deliberately unhelpful, in the ways Apple has proven to be:
  - filter[...] parameters are ignored; everything comes back and the tool must
    match client-side
  - a to-one relationship Apple has nothing for answers 404, not an empty body
  - a reservation and a PATCH both succeed for an image Apple goes on to reject;
    only assetDeliveryState says whether it was accepted
  - every path and verb exists in Apple's OpenAPI spec (test_asc_api_shapes.py
    checks the tool; this file's routes were written from the same spec)

Idempotency is the point: the second run must make zero POSTs.
"""

from __future__ import annotations

import base64
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import threading
import zlib
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
REAL_ROOT = os.path.dirname(os.path.dirname(TOOLS))
SETUP = os.path.join(TOOLS, "asc_setup.py")

SLUG = "fixture-app"
ASC_APP_ID = "1234567890"
PRODUCT_ID = "com.example.fixture.removeads"

STATE: dict = {}


def reset_state() -> None:
    STATE.clear()
    STATE.update({
        "versions": [],            # [{id, versionString, platform}]
        "iaps": [],                # [{id, productId, state}]
        "localizations": {},       # iap_id -> {locale: {id, name, description}}
        "availability": {},        # iap_id -> True
        "price_schedule": {},      # iap_id -> {price_point}
        "review_shot": {},         # iap_id -> {id, uploaded, checksum}
        "posts": [],               # every POST path, to prove idempotency
        "asset_state": {"state": "COMPLETE", "errors": []},
        "next_id": 500,
    })


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
        return json.loads(self.rfile.read(length)) if length else {}

    def _authed(self) -> bool:
        return self.headers.get("Authorization", "").startswith("Bearer ey")

    def _absent(self) -> None:
        # Apple's answer for a to-one relationship with nothing behind it.
        self._json(404, {"errors": [{"title": "NOT_FOUND"}]})

    def do_GET(self) -> None:
        if not self._authed():
            return self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
        path, _, query = self.path.partition("?")
        # Every filter is ignored on purpose. Apple ignored one on us.
        if path == f"/v1/apps/{ASC_APP_ID}/appStoreVersions":
            return self._json(200, {"data": [{"type": "appStoreVersions", "id": v["id"],
                                              "attributes": {"versionString": v["versionString"], "platform": v["platform"]}}
                                             for v in STATE["versions"]]})
        if path == f"/v1/apps/{ASC_APP_ID}/inAppPurchasesV2":
            return self._json(200, {"data": [{"type": "inAppPurchases", "id": i["id"],
                                              "attributes": {"productId": i["productId"], "state": i["state"]}}
                                             for i in STATE["iaps"]]})
        if path.startswith("/v2/inAppPurchases/"):
            iap_id, _, rest = path[len("/v2/inAppPurchases/"):].partition("/")
            if rest == "inAppPurchaseLocalizations":
                rows = [{"type": "inAppPurchaseLocalizations", "id": r["id"],
                         "attributes": {"locale": loc, "name": r["name"], "description": r["description"]}}
                        for loc, r in STATE["localizations"].get(iap_id, {}).items()]
                return self._json(200, {"data": rows})
            if rest == "inAppPurchaseAvailability":
                return self._json(200, {"data": {"type": "inAppPurchaseAvailabilities", "id": "av1"}}) \
                    if STATE["availability"].get(iap_id) else self._absent()
            if rest == "iapPriceSchedule":
                return self._json(200, {"data": {"type": "inAppPurchasePriceSchedules", "id": "ps1"}}) \
                    if STATE["price_schedule"].get(iap_id) else self._absent()
            if rest == "appStoreReviewScreenshot":
                shot = STATE["review_shot"].get(iap_id)
                return self._json(200, {"data": {"type": "inAppPurchaseAppStoreReviewScreenshots", "id": shot["id"]}}) \
                    if shot else self._absent()
            if rest == "pricePoints":
                # Two territories' worth, ignoring filter[territory]: the tool
                # must pick by customerPrice, and must not trip over a foreign
                # price that happens to match numerically.
                return self._json(200, {"data": [
                    {"type": "inAppPurchasePricePoints", "id": "pp-usa-199", "attributes": {"customerPrice": "1.99"}},
                    {"type": "inAppPurchasePricePoints", "id": "pp-usa-299", "attributes": {"customerPrice": "2.99"}},
                    {"type": "inAppPurchasePricePoints", "id": "pp-usa-399", "attributes": {"customerPrice": "3.99"}},
                ]})
        if path == "/v1/territories":
            return self._json(200, {"data": [{"type": "territories", "id": t} for t in ("USA", "CAN", "ESP", "DEU")]})
        if path.startswith("/v1/inAppPurchaseAppStoreReviewScreenshots/"):
            return self._json(200, {"data": {"type": "inAppPurchaseAppStoreReviewScreenshots",
                                             "id": path.rsplit("/", 1)[-1],
                                             "attributes": {"assetDeliveryState": STATE["asset_state"]}}})
        self._json(404, {"errors": [{"title": "NOT_FOUND", "detail": path}]})

    def do_POST(self) -> None:
        if not self._authed():
            return self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
        STATE["posts"].append(self.path)
        data = self._body().get("data", {})
        rtype = data.get("type")
        if self.path == "/v1/appStoreVersions" and rtype == "appStoreVersions":
            v = {"id": new_id(), **data["attributes"]}
            STATE["versions"].append(v)
            return self._json(201, {"data": {"type": rtype, "id": v["id"]}})
        if self.path == "/v2/inAppPurchases" and rtype == "inAppPurchases":
            if data["attributes"]["inAppPurchaseType"] != "NON_CONSUMABLE":
                return self._json(409, {"errors": [{"title": "wrong type"}]})
            i = {"id": new_id(), "productId": data["attributes"]["productId"], "state": "MISSING_METADATA"}
            STATE["iaps"].append(i)
            return self._json(201, {"data": {"type": rtype, "id": i["id"]}})
        if self.path == "/v1/inAppPurchaseLocalizations":
            iap_id = data["relationships"]["inAppPurchaseV2"]["data"]["id"]
            a = data["attributes"]
            STATE["localizations"].setdefault(iap_id, {})[a["locale"]] = {
                "id": new_id(), "name": a["name"], "description": a.get("description", "")}
            return self._json(201, {"data": {"type": rtype, "id": STATE["localizations"][iap_id][a["locale"]]["id"]}})
        if self.path == "/v1/inAppPurchaseAvailabilities":
            iap_id = data["relationships"]["inAppPurchase"]["data"]["id"]
            terr = data["relationships"]["availableTerritories"]["data"]
            if not terr or not data["attributes"].get("availableInNewTerritories"):
                return self._json(409, {"errors": [{"title": "availability incomplete"}]})
            STATE["availability"][iap_id] = True
            return self._json(201, {"data": {"type": rtype, "id": "av1"}})
        if self.path == "/v1/inAppPurchasePriceSchedules":
            rel = data["relationships"]
            body = self._last_body = None  # noqa
            iap_id = rel["inAppPurchase"]["data"]["id"]
            if rel["baseTerritory"]["data"]["id"] != "USA":
                return self._json(409, {"errors": [{"title": "base territory"}]})
            STATE["price_schedule"][iap_id] = {"manual": rel["manualPrices"]["data"]}
            return self._json(201, {"data": {"type": rtype, "id": "ps1"}})
        if self.path == "/v1/inAppPurchaseAppStoreReviewScreenshots":
            iap_id = data["relationships"]["inAppPurchaseV2"]["data"]["id"]
            shot_id = new_id()
            STATE["review_shot"][iap_id] = {"id": shot_id, "uploaded": False, "checksum": None}
            port = self.server.server_address[1]
            return self._json(201, {"data": {"type": rtype, "id": shot_id, "attributes": {
                "uploadOperations": [{"method": "PUT", "url": f"http://127.0.0.1:{port}/upload/{shot_id}",
                                      "offset": 0, "length": 9999999, "requestHeaders": []}]}}})
        self._json(400, {"errors": [{"title": "UNKNOWN", "detail": f"{self.path} {rtype}"}]})

    def do_PATCH(self) -> None:
        if not self._authed():
            return self._json(401, {"errors": [{"title": "NOT_AUTHORIZED"}]})
        data = self._body().get("data", {})
        rtype, rid = data.get("type"), data.get("id")
        if rtype == "inAppPurchaseLocalizations":
            for rows in STATE["localizations"].values():
                for r in rows.values():
                    if r["id"] == rid:
                        r.update({k: v for k, v in data["attributes"].items() if k in ("name", "description")})
            return self._json(200, {"data": {"type": rtype, "id": rid}})
        if rtype == "inAppPurchaseAppStoreReviewScreenshots":
            for shot in STATE["review_shot"].values():
                if shot["id"] == rid:
                    shot["uploaded"] = data["attributes"].get("uploaded")
                    shot["checksum"] = data["attributes"].get("sourceFileChecksum")
            return self._json(200, {"data": {"type": rtype, "id": rid}})
        self._json(404, {"errors": [{"title": "NOT_FOUND"}]})

    def do_PUT(self) -> None:
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        self.send_response(204)
        self.end_headers()


def write_png(path: str, width: int, height: int) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    def chunk(tag: bytes, payload: bytes) -> bytes:
        return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + b"\x10\x80\x40" * width for _ in range(height))
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
    with open(path, "wb") as fh:
        fh.write(png)


def fixture_root(price_usd: str = "2.99") -> str:
    root = tempfile.mkdtemp(prefix="asc-setup-")
    real = json.load(open(os.path.join(REAL_ROOT, "factory", "apps.json")))
    langs = real["defaults"]["ios"]["languages"]
    app = {
        "slug": SLUG, "name": "Fixture", "platform": "ios", "bundle_id": "com.example.fixture",
        "path": f"apps-ios/{SLUG}", "store_dir": f"apps-ios/{SLUG}/store", "spec": f"specifications/{SLUG}.json",
        "privacy_path": f"docs/{SLUG}/privacy", "support_path": f"docs/{SLUG}/support",
        "asc_app_id": ASC_APP_ID, "status": "planned",
        "current_version": {"marketing_version": "1.0.0", "build": 1},
        "admob": {"app_id": "", "banner_unit_id": "", "interstitial_unit_id": ""},
        "iap": {"remove_ads_product_id": PRODUCT_ID, **({"price_usd": price_usd} if price_usd else {})},
        "known_gaps": {},
    }
    os.makedirs(os.path.join(root, "factory"))
    json.dump({"defaults": real["defaults"], "apps": [app]}, open(os.path.join(root, "factory", "apps.json"), "w"))
    store = os.path.join(root, app["store_dir"])
    os.makedirs(store)
    json.dump({"languages": [{"lang": l, "name": "Fixture", "subtitle": "s", "description": "d", "keywords": "k",
                              "iap": {"name": "Remove Ads", "description": "Remove ads, permanently."}}
                             for l in langs]}, open(os.path.join(store, "listing.json"), "w"))
    write_png(os.path.join(store, "iap-review-screenshot.png"), 40, 80)
    return root


def throwaway_key_b64() -> str:
    pem = subprocess.run(["openssl", "ecparam", "-name", "prime256v1", "-genkey", "-noout"],
                         capture_output=True, text=True, check=True).stdout
    return base64.b64encode(pem.encode()).decode()


def main() -> int:
    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_address[1]}"
    env = dict(os.environ, ASC_API_BASE=base, ASC_KEY_ID="TESTKEY1234",
               ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000", ASC_PRIVATE_KEY_P8=throwaway_key_b64())
    failures: list[str] = []

    def check(label: str, ok: bool, detail: str = "") -> None:
        print(f"  {'ok  ' if ok else 'FAIL'}  {label}" + (f"\n        {detail}" if detail and not ok else ""))
        if not ok:
            failures.append(label)

    def run(root: str, *args: str) -> tuple[int, str]:
        proc = subprocess.run([sys.executable, SETUP, SLUG, *args], capture_output=True, text=True,
                              env=dict(env, FACTORY_ROOT=root))
        return proc.returncode, proc.stdout + proc.stderr

    # --- first run creates everything ------------------------------------------
    reset_state()
    root = fixture_root()
    try:
        print("first run, nothing exists yet:")
        code, out = run(root, "--what", "all")
        check("exits 0", code == 0, out)
        check("created the appStoreVersion 1.0.0 for IOS",
              [v for v in STATE["versions"] if v["versionString"] == "1.0.0" and v["platform"] == "IOS"] != [], out)
        check("created the NON_CONSUMABLE purchase with the registry's product id",
              [i for i in STATE["iaps"] if i["productId"] == PRODUCT_ID] != [], out)
        iap_id = STATE["iaps"][0]["id"]
        locs = STATE["localizations"].get(iap_id, {})
        check("one localization per listing language, from listing.json's iap block",
              len(locs) == 9 and all(r["name"] == "Remove Ads" for r in locs.values()), str(sorted(locs)))
        check("availability set across all territories", STATE["availability"].get(iap_id) is True)
        sched = STATE["price_schedule"].get(iap_id)
        check("price schedule created with USA as base", sched is not None, out)
        check("the price point was chosen by customerPrice == 2.99, not by position",
              "pp-usa-299" in out or (sched and any("price" in str(m) for m in sched["manual"])), out)
        shot = STATE["review_shot"].get(iap_id)
        check("review screenshot reserved, uploaded and committed with a checksum",
              bool(shot and shot["uploaded"] and shot["checksum"]), str(shot))
        first_posts = list(STATE["posts"])

        # --- second run must be a no-op ----------------------------------------
        print("\nsecond run, everything exists:")
        code, out = run(root, "--what", "all")
        check("exits 0", code == 0, out)
        check("made zero POSTs -- looked up, found, left alone",
              STATE["posts"] == first_posts, f"new posts: {STATE['posts'][len(first_posts):]}")
        check("did not duplicate the version or the purchase",
              len(STATE["versions"]) == 1 and len(STATE["iaps"]) == 1)

        # --- a changed description is a PATCH, not a duplicate ---------------
        print("\nchanged purchase description:")
        L = json.load(open(os.path.join(root, f"apps-ios/{SLUG}/store/listing.json")))
        for e in L["languages"]:
            if e["lang"] == "en-US":
                e["iap"]["description"] = "Removes every ad. Forever."
        json.dump(L, open(os.path.join(root, f"apps-ios/{SLUG}/store/listing.json"), "w"))
        before = len(STATE["posts"])
        code, out = run(root, "--what", "iap")
        check("updates the existing localization in place",
              STATE["localizations"][iap_id]["en-US"]["description"] == "Removes every ad. Forever."
              and len(STATE["posts"]) == before, out)
    finally:
        shutil.rmtree(root, ignore_errors=True)

    # --- Apple rejects the review screenshot ----------------------------------
    print("\nApple rejects the review screenshot after the upload:")
    reset_state()
    STATE["asset_state"] = {"state": "FAILED", "errors": [{"code": "IMAGE_INCORRECT_DIMENSIONS", "description": "too small"}]}
    root = fixture_root()
    try:
        code, out = run(root, "--what", "iap")
        check("fails instead of reporting the purchase as complete", code != 0, out)
        check("repeats Apple's reason", "IMAGE_INCORRECT_DIMENSIONS" in out, out)
    finally:
        shutil.rmtree(root, ignore_errors=True)

    # --- a price Apple does not offer -----------------------------------------
    print("\na price with no matching price point:")
    reset_state()
    root = fixture_root(price_usd="2.49")
    try:
        code, out = run(root, "--what", "iap")
        check("fails and lists the prices Apple does offer", code != 0 and "1.99" in out and "2.99" in out, out)
    finally:
        shutil.rmtree(root, ignore_errors=True)

    # --- missing price in the registry ----------------------------------------
    print("\nregistry declares the purchase but no price:")
    reset_state()
    root = fixture_root(price_usd="")
    try:
        code, out = run(root, "--what", "iap")
        check("refuses with the field named", code != 0 and "price_usd" in out, out)
    finally:
        shutil.rmtree(root, ignore_errors=True)

    server.shutdown()
    print(f"\n{len(failures)} assertion(s) failed" if failures else "\nall assertions passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
