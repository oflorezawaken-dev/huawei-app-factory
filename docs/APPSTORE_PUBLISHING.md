# App Store publishing: credentials, tools and the human steps

Companion to `docs/APPGALLERY_PUBLISHING.md` for the iOS lane. Written while
building the tooling; the flow itself is in `docs/IOS_FACTORY_HANDOFF.md`.

**No secret value appears in this file, in the repository, or in CI logs.**
Only the *names* of secrets are written down.

---

## 1. Secrets the iOS lane needs

Created by the repository owner (`oflorezawaken-dev`) in the **`appstore`**
environment of this repository. They come from one App Store Connect API key
with the **App Manager** role (Users and Access > Integrations > App Store
Connect API).

| Secret name | Where it comes from | Notes |
|---|---|---|
| `ASC_KEY_ID` | Key ID column in the key table | ~10 characters |
| `ASC_ISSUER_ID` | Above the key table, one per account | UUID |
| `ASC_PRIVATE_KEY_P8` | base64 of the `AuthKey_<KEY_ID>.p8` file | **Downloadable exactly once.** Store it in a password manager before uploading |

To produce the third value without the key ever passing through a chat or a
tracked file:

```bash
base64 -i ~/Downloads/AuthKey_XXXXXXXXXX.p8 | pbcopy
```

Then paste it into the GitHub secret form. Delete the `.p8` from `~/Downloads`
afterwards, keeping the copy in your password manager.

Verify the three names are registered (values are never readable again):

```bash
gh api repos/oflorezawaken-dev/huawei-app-factory/environments/appstore/secrets --jq '.secrets[].name'
```

> Creating environments and secrets requires **admin** on the repository. The
> `orlandofm079` account has push access only, so this step cannot be
> automated and is one of the human gates.

The same key also drives cloud-managed signing in the build workflow
(`xcodebuild -allowProvisioningUpdates -authenticationKeyPath ...`), so no
`.p12` certificate or `.mobileprovision` profile has to be stored anywhere.

---

## 2. Tools in this lane

| Tool | What it does | Needs the network? |
|---|---|---|
| `factory/tools/registry.py` | Reads `factory/apps.json`. iOS entries are the ones with `"platform": "ios"` | no |
| `factory/tools/check_ios_app.py` | Quality gate: ads SDK, ATT, privacy manifest, identity, icon, screenshots, listing limits, tests | no |
| `factory/tools/asc_client.py` | Reads app / version / build / review state from App Store Connect | yes (except `selftest`) |

Local commands:

```bash
python factory/factory.py check-ios <slug> --strict
python factory/factory.py asc <slug> --what state
python factory/tools/asc_client.py selftest      # proves JWT signing works, no key needed
```

Tests, neither of which touches Apple or needs Xcode:

```bash
python factory/tools/tests/test_check_ios_app.py
python factory/tools/tests/test_asc_client.py
```

Both build a throwaway tree under a temporary `FACTORY_ROOT`, so they never
read or modify the real registry.

---

## 3. Why the JWT is signed with `openssl`

App Store Connect wants an **ES256** JWT. The factory's rule is standard
library only, so `asc_client.py` shells out to `openssl dgst -sha256 -sign`
and converts the DER signature to the raw `r||s` form JWS requires
(`der_to_jose`). This avoids adding `PyJWT` + `cryptography` to every runner.

Details that cost time if you get them wrong:

- `aud` must be exactly `appstoreconnect-v1`.
- `exp` must be **at most 20 minutes** ahead; the client uses 15.
- The signature must be 64 raw bytes, not DER. A DER signature returns
  `401 NOT_AUTHORIZED` with no explanation of why.
- The private key file must never be left on disk: it is written to a `0600`
  temp file for the duration of one signature and removed in a `finally`.

`selftest` generates its own throwaway P-256 key and asserts all of the above,
so a signing regression is caught without any real credential.

---

## 4. Order of the human steps

Apple enforces an order, and each tool fails with the step that is missing
rather than a generic error:

1. **Register the Bundle ID** at developer.apple.com > Identifiers (explicit
   App ID). Signing in CI fails without it.
2. **Create the app** in App Store Connect (+ New App). The Bundle ID only
   appears in the dropdown after step 1.
3. Paste the numeric **Apple ID** of the app into `factory/apps.json` as
   `asc_app_id`. Until then `asc_client.py` refuses to run and says so.
4. **AdMob**: create the app and the banner / interstitial units, paste the
   three IDs into the registry. Until then the gate reports `admob_unit_ids`
   as a failure, and it is `--strict` that decides whether that blocks a
   submission.
5. Upload a build; it must finish **processing** (5-30 minutes) before it can
   be attached to a version. `asc_client.py wait-build <slug> --build <n>`
   polls for it.

---

## 5. Limits already encoded in the gate

Verified against Apple's current documentation on 2026-09-05. Re-check before
trusting them in a year.

| Thing | Value |
|---|---|
| App name / subtitle | 30 characters each |
| Promotional text | 170 characters |
| Description / What's New | 4000 characters |
| Keywords | 100 characters total, comma separated |
| Screenshots | 3 to 10 per set; 6.9" iPhone at 1320x2868 (1290x2796 and 1260x2736 also accepted) |
| iPad screenshots | Only when the app declares iPad support: 13" at 2064x2752 or 2048x2732 |
| App icon | 1024x1024 PNG, **no alpha channel** |
| Locale codes | `en-US`, `es-ES`, `pt-PT`, `fr-FR`, `de-DE`, `it`, `tr`, `ar-SA`, `zh-Hans` |

The locale codes differ from Huawei's (`ar` vs `ar-SA`, `zh-CN` vs `zh-Hans`,
`it-IT` vs `it`, `tr-TR` vs `tr`). `defaults.ios.screenshot_dir_to_asc_lang`
maps the shared screenshot folders to Apple's codes; never reuse
`defaults.languages`, which is Huawei's list.

Apple scales the 6.9" iPhone set down to every smaller iPhone, so that is the
only iPhone set the gate requires.
