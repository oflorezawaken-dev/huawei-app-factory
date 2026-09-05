#!/usr/bin/env python3
"""
App Factory - App Store Connect API client.

Reads app, version, build and review state from App Store Connect. Standard
library only (ES256 is signed by shelling out to `openssl`), so it runs on any
GitHub Actions runner without installing dependencies.

Credentials are read ONLY from environment variables, never printed, and the
signed token is masked in CI logs:
  ASC_KEY_ID          Key ID          (App Store Connect > Users and Access > Integrations)
  ASC_ISSUER_ID       Issuer ID       (same page, above the key table)
  ASC_PRIVATE_KEY_P8  base64 of the AuthKey_<KEY_ID>.p8 file  (or ASC_PRIVATE_KEY_PATH)

  python factory/tools/asc_client.py selftest              # no network: proves JWT signing works
  python factory/tools/asc_client.py apps
  python factory/tools/asc_client.py app <slug>            # resolve the app from the registry
  python factory/tools/asc_client.py versions <slug>
  python factory/tools/asc_client.py state <slug>          # appStoreState of the newest version
  python factory/tools/asc_client.py builds <slug>
  python factory/tools/asc_client.py wait-build <slug> --build <n> [--timeout 1800]

Exit codes: 0 fine, 1 API or configuration error, 2 wait-build timed out.

The App Store Connect API will not create an app for you: the human creates it
in the console (Bundle ID first, then the app record) and pastes the numeric
Apple ID into factory/apps.json as asc_app_id. Every command here reads.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from registry import find, platform_of  # noqa: E402

# ASC_API_BASE override exists only for local testing against a mock server.
API_BASE = os.environ.get("ASC_API_BASE", "https://api.appstoreconnect.apple.com")
AUDIENCE = "appstoreconnect-v1"
TOKEN_TTL = 15 * 60  # Apple rejects anything over 20 minutes.

# appStoreState values worth acting on (there are more; these are the ones the
# factory's daily poll reports).
TERMINAL_STATES = {"READY_FOR_SALE", "REJECTED", "DEVELOPER_REJECTED", "METADATA_REJECTED",
                   "INVALID_BINARY", "PENDING_DEVELOPER_RELEASE"}


class ASCError(RuntimeError):
    pass


def log(msg: str) -> None:
    print(f"[asc] {msg}", flush=True)


def mask_in_ci(value: str) -> None:
    """Ask GitHub Actions to mask a runtime secret (no-op elsewhere)."""
    if os.environ.get("GITHUB_ACTIONS") == "true" and value:
        print(f"::add-mask::{value}", flush=True)


def b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def der_to_jose(der: bytes) -> bytes:
    """Convert an OpenSSL ECDSA DER signature to the raw r||s JWS wants.

    DER is SEQUENCE { INTEGER r, INTEGER s } with minimal-length, sign-extended
    integers; JWS needs both padded to exactly 32 bytes for P-256.
    """
    if not der or der[0] != 0x30:
        raise ASCError("openssl did not return a DER ECDSA signature")
    # Skip SEQUENCE tag and its length (short or long form).
    i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    out = b""
    for _ in range(2):
        if der[i] != 0x02:
            raise ASCError("malformed DER signature: expected INTEGER")
        length = der[i + 1]
        value = der[i + 2:i + 2 + length].lstrip(b"\x00")
        if len(value) > 32:
            raise ASCError("DER integer longer than the P-256 field size")
        out += value.rjust(32, b"\x00")
        i += 2 + length
    return out


def private_key_pem() -> bytes:
    """The .p8 contents from the environment. Never logged, never written to the repo."""
    b64 = os.environ.get("ASC_PRIVATE_KEY_P8", "").strip()
    path = os.environ.get("ASC_PRIVATE_KEY_PATH", "").strip()
    if b64:
        try:
            # Accept both a base64 blob and a pasted PEM.
            return b64.encode() if "-----BEGIN" in b64 else base64.b64decode(b64, validate=True)
        except (ValueError, base64.binascii.Error) as exc:
            raise ASCError("ASC_PRIVATE_KEY_P8 is not valid base64 nor a PEM block") from exc
    if path:
        if not os.path.isfile(path):
            raise ASCError(f"ASC_PRIVATE_KEY_PATH points at a missing file: {path}")
        with open(path, "rb") as fh:
            return fh.read()
    raise ASCError("set ASC_PRIVATE_KEY_P8 (base64 of the .p8) or ASC_PRIVATE_KEY_PATH")


def sign_es256(message: bytes, key_pem: bytes) -> bytes:
    """Sign with openssl. The key lives in a 0600 temp file only for this call."""
    fd, key_path = tempfile.mkstemp(prefix="asc-key-", suffix=".p8")
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "wb") as fh:
            fh.write(key_pem)
        proc = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path],
                              input=message, capture_output=True)
        if proc.returncode != 0:
            # stderr can echo the key path but never the key itself.
            raise ASCError(f"openssl failed to sign: {proc.stderr.decode('utf-8', 'replace').strip()}")
        return der_to_jose(proc.stdout)
    finally:
        if os.path.exists(key_path):
            os.remove(key_path)


def make_token() -> str:
    key_id = os.environ.get("ASC_KEY_ID", "").strip()
    issuer_id = os.environ.get("ASC_ISSUER_ID", "").strip()
    if not key_id or not issuer_id:
        raise ASCError("set ASC_KEY_ID and ASC_ISSUER_ID")
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iss": issuer_id, "iat": now, "exp": now + TOKEN_TTL, "aud": AUDIENCE}
    signing_input = ".".join(
        b64url(json.dumps(part, separators=(",", ":")).encode()) for part in (header, payload)
    ).encode()
    token = f"{signing_input.decode()}.{b64url(sign_es256(signing_input, private_key_pem()))}"
    mask_in_ci(token)
    return token


def api_get(path: str, params: dict | None = None, token: str | None = None) -> dict:
    url = f"{API_BASE}{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params, doseq=True)
    req = urllib.request.Request(url, method="GET")
    req.add_header("Authorization", f"Bearer {token or make_token()}")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        try:
            errors = json.loads(body).get("errors", [])
            detail = "; ".join(f"{e.get('title')}: {e.get('detail')}" for e in errors) or body
        except json.JSONDecodeError:
            detail = body
        raise ASCError(f"GET {path} -> HTTP {exc.code}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise ASCError(f"GET {path} failed: {exc.reason}") from exc


def resolve_app(slug: str) -> tuple[str, dict]:
    """(asc_app_id, registry entry). Fails with the human step that is missing."""
    app = find(slug)
    if platform_of(app) != "ios":
        raise ASCError(f"'{slug}' is a {platform_of(app)} app")
    asc_app_id = str(app.get("asc_app_id") or "")
    if not asc_app_id:
        raise ASCError(
            f"'{slug}' has no asc_app_id yet. Create the app in App Store Connect "
            "(register the Bundle ID first), then paste its numeric Apple ID into "
            "factory/apps.json as asc_app_id. See step 6 of the iOS flow.")
    return asc_app_id, app


def cmd_selftest() -> int:
    """Prove signing works end to end without touching Apple or a real key."""
    log("generating a throwaway P-256 key (never leaves this process)")
    gen = subprocess.run(["openssl", "genpkey", "-algorithm", "EC",
                          "-pkeyopt", "ec_paramgen_curve:P-256", "-outform", "PEM"],
                         capture_output=True)
    if gen.returncode != 0:
        log(f"openssl genpkey failed: {gen.stderr.decode('utf-8', 'replace').strip()}")
        return 1
    env_backup = {k: os.environ.get(k) for k in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_PRIVATE_KEY_P8")}
    try:
        os.environ["ASC_KEY_ID"] = "SELFTESTKEY"
        os.environ["ASC_ISSUER_ID"] = "00000000-0000-0000-0000-000000000000"
        os.environ["ASC_PRIVATE_KEY_P8"] = base64.b64encode(gen.stdout).decode()
        token = make_token()
        header_b64, payload_b64, sig_b64 = token.split(".")

        def unb64(part: str) -> bytes:
            return base64.urlsafe_b64decode(part + "=" * (-len(part) % 4))

        header, payload = json.loads(unb64(header_b64)), json.loads(unb64(payload_b64))
        checks = [
            ("alg is ES256", header.get("alg") == "ES256"),
            ("kid is the key ID", header.get("kid") == "SELFTESTKEY"),
            ("aud is appstoreconnect-v1", payload.get("aud") == AUDIENCE),
            ("exp is within Apple's 20-minute limit", 0 < payload["exp"] - payload["iat"] <= 1200),
            ("signature is 64 raw bytes (r||s)", len(unb64(sig_b64)) == 64),
        ]
        for label, ok in checks:
            log(f"{'ok  ' if ok else 'FAIL'}  {label}")
        if all(ok for _, ok in checks):
            log("JWT signing works; the API calls need the real ASC_* secrets")
            return 0
        return 1
    finally:
        for k, v in env_backup.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v


def cmd_apps() -> int:
    data = api_get("/v1/apps", {"limit": 200, "fields[apps]": "name,bundleId,sku"})
    rows = data.get("data", [])
    if not rows:
        log("the account has no apps yet")
    for row in rows:
        attrs = row.get("attributes", {})
        print(f"{row['id']}\t{attrs.get('bundleId', '')}\t{attrs.get('name', '')}")
    return 0


def cmd_app(slug: str) -> int:
    asc_app_id, app = resolve_app(slug)
    data = api_get(f"/v1/apps/{asc_app_id}", {"fields[apps]": "name,bundleId,sku"})
    attrs = data.get("data", {}).get("attributes", {})
    print(json.dumps({"slug": slug, "asc_app_id": asc_app_id,
                      "bundle_id_registry": app["bundle_id"],
                      "bundle_id_apple": attrs.get("bundleId"),
                      "name": attrs.get("name"), "sku": attrs.get("sku")}, indent=2))
    if attrs.get("bundleId") and attrs["bundleId"] != app["bundle_id"]:
        log(f"WARNING: registry bundle_id {app['bundle_id']} != Apple's {attrs['bundleId']}")
        return 1
    return 0


def versions(asc_app_id: str, token: str | None = None) -> list[dict]:
    data = api_get(f"/v1/apps/{asc_app_id}/appStoreVersions",
                   {"limit": 10, "fields[appStoreVersions]": "versionString,appStoreState,createdDate,platform"},
                   token)
    return data.get("data", [])


def cmd_versions(slug: str) -> int:
    asc_app_id, _ = resolve_app(slug)
    rows = versions(asc_app_id)
    if not rows:
        log("no versions yet; create version 1.0 in App Store Connect")
    for row in rows:
        attrs = row.get("attributes", {})
        print(f"{attrs.get('versionString', '?')}\t{attrs.get('appStoreState', '?')}\t{row['id']}")
    return 0


def cmd_state(slug: str) -> int:
    asc_app_id, _ = resolve_app(slug)
    rows = versions(asc_app_id)
    if not rows:
        print("NO_VERSION")
        return 0
    attrs = rows[0].get("attributes", {})
    state = attrs.get("appStoreState", "UNKNOWN")
    print(state)
    log(f"{slug} {attrs.get('versionString', '?')}: {state}"
        + ("  (terminal)" if state in TERMINAL_STATES else ""))
    return 0


def builds(asc_app_id: str, token: str | None = None) -> list[dict]:
    data = api_get("/v1/builds", {
        "filter[app]": asc_app_id, "limit": 20, "sort": "-uploadedDate",
        "fields[builds]": "version,processingState,uploadedDate,expired",
    }, token)
    return data.get("data", [])


def cmd_builds(slug: str) -> int:
    asc_app_id, _ = resolve_app(slug)
    rows = builds(asc_app_id)
    if not rows:
        log("no builds uploaded yet")
    for row in rows:
        attrs = row.get("attributes", {})
        print(f"{attrs.get('version', '?')}\t{attrs.get('processingState', '?')}\t{attrs.get('uploadedDate', '')}")
    return 0


def cmd_wait_build(slug: str, build: str, timeout: int) -> int:
    """Poll until a build finishes processing. Apple takes 5-30 minutes."""
    asc_app_id, _ = resolve_app(slug)
    token, deadline, delay = make_token(), time.time() + timeout, 30
    while time.time() < deadline:
        for row in builds(asc_app_id, token):
            attrs = row.get("attributes", {})
            if str(attrs.get("version")) != str(build):
                continue
            state = attrs.get("processingState")
            log(f"build {build}: {state}")
            if state == "VALID":
                return 0
            if state in ("INVALID", "FAILED"):
                log(f"build {build} will not become usable ({state}); check the email from Apple")
                return 1
            break
        else:
            log(f"build {build} has not appeared yet")
        time.sleep(delay)
        delay = min(delay * 2, 120)
        if time.time() + 60 > deadline:  # token outlives the loop only if refreshed
            token = make_token()
    log(f"timed out after {timeout}s waiting for build {build}")
    return 2


def main(argv: list[str]) -> int:
    p = argparse.ArgumentParser(description="App Store Connect API client", add_help=True)
    p.add_argument("command", choices=["selftest", "apps", "app", "versions", "state", "builds", "wait-build"])
    p.add_argument("slug", nargs="?")
    p.add_argument("--build", default="")
    p.add_argument("--timeout", type=int, default=1800)
    a = p.parse_args(argv)

    needs_slug = {"app", "versions", "state", "builds", "wait-build"}
    if a.command in needs_slug and not a.slug:
        sys.exit(f"{a.command} needs an app slug (see: python factory/tools/registry.py list --platform ios)")

    try:
        if a.command == "selftest":
            return cmd_selftest()
        if a.command == "apps":
            return cmd_apps()
        if a.command == "app":
            return cmd_app(a.slug)
        if a.command == "versions":
            return cmd_versions(a.slug)
        if a.command == "state":
            return cmd_state(a.slug)
        if a.command == "builds":
            return cmd_builds(a.slug)
        if a.command == "wait-build":
            if not a.build:
                sys.exit("wait-build needs --build <n> (the CURRENT_PROJECT_VERSION that was uploaded)")
            return cmd_wait_build(a.slug, a.build, a.timeout)
    except ASCError as exc:
        log(f"error: {exc}")
        return 1
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
