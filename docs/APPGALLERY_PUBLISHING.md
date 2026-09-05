# Publishing to Huawei AppGallery

This document describes the publishing stage of the factory: how a signed
release produced by CI reaches AppGallery Connect, what is automated, and what
Huawei requires a human to do.

## What is automated

Workflow: `.github/workflows/receipt-lens-publish.yml` (manual trigger only).
Tool: `factory/tools/agc_publish.py` (standard library Python, reusable for any app).

The workflow:

1. Picks a successful `ReceiptLens Build` run on `main` (latest, or the run ID you give it).
2. Downloads the signed `receipt-lens-release-apk` or `-aab` artifact.
3. Verifies the APK signature with `apksigner`.
4. Obtains a Publishing API token, resolves the app ID from the package name,
   uploads the package, registers it on the app, and, only if you ask, submits it for review.

Nothing is submitted for review unless `submit_for_review` is set to `true`.

## What Huawei does not allow via API (one-time, per app)

| Manual step | Where | Notes |
|---|---|---|
| Developer account registration and identity verification | developer.huawei.com | Account-level, once. |
| Create the app | AppGallery Connect > My apps > New | The Publishing API cannot create apps. Package name must be `com.huaweiappfactory.receiptlens`. |
| Content rating questionnaire | App > Distribute > Version information | Cannot be completed via API. |
| **Privacy tags** (personal-data declaration) | App > Distribute > Version information > Privacy tags | No API. Tick exactly the boxes in `apps/<slug>/store/privacy-tags.md`, then write the date in `factory/apps.json` → `privacy_tags_configured`. ReceiptLens 1.0 was rejected on 2026-09-07 for leaving this at "No". |
| Privacy policy URL, app category, countries, pricing | App information | Can be set via API later, but must exist before the first submission. |
| Screenshots and icon | App information | Uploadable via API (fileType 0/2); for V1 do it in the console with real captures. |
| Enable App Signing (AAB only) | App > Develop > App Signing | Required before uploading an AAB. APK does not need it. |
| Create an API client | Users and permissions > API client > Connect API | Role must allow release management (e.g. Administrator or App Administrator). Project field: **N/A**. |

## Secrets to configure in GitHub

Repository or `appgallery` environment secrets. Names only, never commit values:

```text
AGC_CLIENT_ID
AGC_CLIENT_SECRET
```

Recommended: create the `appgallery` environment in repository settings and add
yourself as a **required reviewer**. Every publish run will then pause until you
approve it, which is the human gate for anything that reaches the store.

## How to run

GitHub > Actions > "ReceiptLens Publish to AppGallery" > Run workflow:

| Input | Meaning |
|---|---|
| `release_run_id` | Empty = latest successful release build on `main`. |
| `package_type` | `apk` (default) or `aab` (requires App Signing enabled in AGC). |
| `submit_for_review` | `false` = upload only, you finish in the console. `true` = submit immediately. |
| `release_notes` | 10-300 characters, mandatory when submitting. |
| `app_id` | AppGallery Connect App ID. Overrides the repository variable `RECEIPT_LENS_AGC_APP_ID`. |

**App ID vs package name.** AppGallery Connect assigns an app's package name from the
first package uploaded to it, so `appid-list?packageName=` returns nothing for a
brand-new app. Set the repository variable `RECEIPT_LENS_AGC_APP_ID` (Settings →
Secrets and variables → Actions → Variables) to the App ID shown in the console under
My apps → the app → App information. The App ID is an identifier, not a secret.

Recommended first run: `package_type=apk`, `submit_for_review=false`. Check that the
package appears under the app's version information in the console, then complete
the remaining console fields and submit from there. Automate submission only once
one release has passed review.

## Running the tool locally

```bash
export AGC_CLIENT_ID=TU_CLIENT_ID_AQUI
export AGC_CLIENT_SECRET=TU_CLIENT_SECRET_AQUI
python factory/tools/agc_publish.py --package-name com.huaweiappfactory.receiptlens --file app-release.apk --dry-run
```

Drop `--dry-run` to perform the upload. Add `--submit --release-notes "..."` to submit.

## API reference used

Endpoints (AppGallery Connect Publishing API v2, base `https://connect-api.cloud.huawei.com/api`):

| Step | Call |
|---|---|
| Token | `POST /oauth2/v1/token` `{grant_type: client_credentials, client_id, client_secret}` (valid 48 h) |
| App ID | `GET /publish/v2/appid-list?packageName=` |
| Upload URL | `GET /publish/v2/upload-url/for-obs?appId=&fileName=&contentLength=&suffix=` → `urlInfo{url, method, headers, objectId}` |
| Upload | `PUT urlInfo.url` with `urlInfo.headers`, raw body |
| Register | `PUT /publish/v2/app-file-info?appId=` `{fileType: 5, files: [{fileName, fileDestUrl: objectId, size}]}` |
| AAB status | `GET /publish/v2/aab/complile/status?appId=&pkgIds=` (`aabCompileStatus` 1 = compiling, 2 = done) |
| Submit | `POST /publish/v2/app-submit?appId=&remark=` |

All non-token calls carry headers `client_id` and `Authorization: Bearer <token>`.
Huawei's documentation site renders client-side; the flow above was cross-checked against
two maintained open-source clients (fastlane `huawei_appgallery_connect`, Python `appgallery`).
Re-verify against the official reference before relying on new fields.

## Errors seen and their fix

| API error | Cause | Fix |
|---|---|---|
| `No AppGallery app found for package ...` | New app: AGC assigns the package name from the first uploaded package. | Use the App ID (`RECEIPT_LENS_AGC_APP_ID`). |
| `204144694 [cfs] get siteId failed ... distContryList is empty` | The app has no distribution countries/regions yet, so Huawei cannot pick a storage site for the upload. | In the console: the app → Distribute → Version information → **Countries/Regions** → select and save. Can later be automated with `PUT /publish/v2/app-info` field `publishCountry`. |

## Privacy tags: the rejection of 2026-09-07 and the fix

Huawei's review report for ReceiptLens 1.0.0 ("Privacidad del usuario, número 1"): *the app
collects personal information but this was not indicated in the privacy tag configuration*.
The console had **Collect personal data = No**. That is false for every factory app: the Petal
Ads SDK reads the OAID and sends IP, device, network and app information with each ad request,
and the camera-based apps store photos. The reviewer also reads the public privacy policy, which
already disclosed Petal Ads.

What changed in the factory:

- `factory/tools/privacy_tags.py` holds the official taxonomy (7 scenarios, 12 categories, 91
  items) and the Petal Ads block; `init` derives a baseline from the manifest permissions,
  `check` validates, `render --write` produces `store/privacy-tags.md`, the click-by-click list.
- The quality gate has a `privacy_tags` rule; the spec template defaults
  `collects_personal_data` to true and asks for the app's own data items.
- `factory-store.yml` (`what: privacy-tags`) prints the checklist in the run summary;
  `factory-publish.yml` refuses `submit_for_review` while `privacy_tags_configured` is empty
  in the registry, which makes the console step an explicit human gate.

Standard block for every app (scenario **Advertising and marketing**): OAID; Other approximate
location information; Basic app information; App usage information; OS information; Device
status; Network type; Carrier; IP address; Acceleration sensor; Gyroscope; Other hardware and
software parameters/System settings. Scenario **Disclosure to third parties** (advertisers
receive OAID, device/network info and ad events): OAID; App usage information; OS information;
Network type; Carrier; IP address; Other hardware and software parameters/System settings.
Under **App functionality** each app adds what it handles itself (ReceiptLens: Image or video,
Transaction records; PlantCue: Image or video).

## Next automation candidates

- `PUT /publish/v2/app-language-info` to push the 9 localized store descriptions from `specifications/`.
- Icon and screenshot upload (fileType 0 and 2) from emulator captures.
- Trigger publish automatically from a Git tag once the human gate is the environment approval.

## Superseded workflows (2026-09-06)

The `receipt-lens-*.yml` workflows referenced above were replaced by the generic
`factory-build.yml`, `factory-store.yml` and `factory-publish.yml`, which take an `app`
input and read `factory/apps.json`. The API flow, errors, and fixes documented here are
unchanged; only the entry points moved. See `factory/README.md`.
