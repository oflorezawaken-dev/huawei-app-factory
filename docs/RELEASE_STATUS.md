# ReceiptLens — release build status

## PASO 23 — first signed release build (2026-09-06)

| Item | Value |
|---|---|
| Commit | `c8624c0` — `ci: add signed release build for ReceiptLens` |
| Workflow run | https://github.com/oflorezawaken-dev/huawei-app-factory/actions/runs/34048749169 |
| Job `verify` | success — `:app:testDebugUnitTest` |
| Job `release` | success — keystore materialized, `:app:assembleRelease`, `:app:bundleRelease`, keystore removed |
| Artifact APK | `receipt-lens-release-apk` → `app-release.apk` (15.4 MB) |
| Artifact AAB | `receipt-lens-release-aab` → `app-release.aab` (14.7 MB) |
| Signature check | `apksigner verify`: 1 signer, RSA 4096, APK Signature Scheme v2 |
| Signer cert SHA-256 | `ce11aa273f03b687bf3cc8eac4b5efe485cbf387e16f7c0957375148fb73b711` |
| Identity | `com.huaweiappfactory.receiptlens`, minSdk 26, versionCode 1, versionName 1.0.0 (unchanged) |

Secrets used by the `release` job (names only): `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`,
`RELEASE_KEY_ALIAS`, `RELEASE_KEY_PASSWORD`. Pull requests run only the `verify` job and receive no secrets.

## Known gaps (not blockers for this step)

- The workflow no longer publishes a debug APK artifact; consider re-adding it to `verify`.
- Only APK Signature Scheme v2 is applied; v3 would allow future key rotation.
- `isMinifyEnabled = false` in release.
- Huawei ML Kit OCR and Petal Ads SDKs are **not** integrated; the code degrades to manual entry / no ads.
- Unused network dependencies (Retrofit, OkHttp, Moshi) remain in `app/build.gradle.kts`.

## First upload to AppGallery Connect (2026-09-06)

| Item | Value |
|---|---|
| Workflow run | https://github.com/oflorezawaken-dev/huawei-app-factory/actions/runs/34051561303 |
| Mode | upload only (`submit_for_review=false`) |
| Source release run | 34048749169 (`app-release.apk`, sha256 `742b20bb…39ac8e`) |
| AGC App ID | `118896647` (repository variable `RECEIPT_LENS_AGC_APP_ID`) |
| Result | Package uploaded to OBS and registered via `app-file-info` (1 pkgVersion) |

Prerequisites that had to be completed in the console first: create the app, set distribution countries.
Not yet done: privacy policy URL, content rating, icon/screenshots, review submission.

## Store readiness (2026-09-06)

| Item | Status | Where |
|---|---|---|
| Privacy policy | Published (private artifact) | https://claude.ai/code/artifact/d0654ce5-4a54-4e8e-a208-95e0eec411b6 — must be shared to public or hosted elsewhere before submitting for review; source kept at `docs/privacy/artifact.html`. GitHub Pages is unavailable because the repo is private on the Free plan. |
| App icon | Done | `apps/receipt-lens/store/icon/icon-512.png` — 512x512, rendered from the app's real adaptive-icon vectors/colors, no placeholder. |
| Screenshots | Done (English) | `apps/receipt-lens/store/screenshots/en/` — 5 real captures from the signed release APK on an emulator: Home (with data), Receipt Detail, Statistics, Receipt History, Settings. Camera/scan screen skipped (emulator has no camera feed, would look broken). |
| Store listing text | Pushed to AppGallery Connect for all 9 languages | `apps/receipt-lens/store/listing.json`, uploaded via `.github/workflows/receipt-lens-listing.yml` runs 34053728967 (en-US), 34053759619 (8 languages), 34053801947 (ar retry). Machine-drafted; see `_notes` in listing.json — have a native speaker review before a real launch. Deliberately does not claim automatic OCR extraction (see known gaps below). |

### Real bugs found while testing the signed build

- **OCR notice leaks an internal message to end users.** The Review screen's "Text Recognition
  Notice" reads "Huawei ML Kit OCR is ready for AppGallery deployment. Please configure
  agconnect-services.json and Huawei HMS Core dependencies in production." That is a
  developer-facing implementation note, not user-facing copy. Fix before shipping: replace with
  something like "We couldn't read this receipt automatically — please enter the details below."
  (`apps/receipt-lens/app/src/main/java/.../ml/HuaweiMlKitOcrService.kt` and wherever the string
  is defined/localized.)
- **Receipt History shows a false "no results" empty state on first entry**, even with receipts
  present and no user-selected filter — reproduced by opening the History tab right after saving
  a receipt. Tapping "All Categories" fixes it. Looks like the category-filter chip group doesn't
  default to "all" on first composition. Worth a real fix before relying on this screen.
- **`data_extraction_rules.xml` and `backup_rules.xml` are untouched Android Studio templates**
  (all `<include>`/`<exclude>` commented out) while `android:allowBackup="true"` is set. That
  means the app's private storage (including receipt images in `filesDir`) can be swept into a
  standard OS-level device/account backup, which is broader than the in-app claim
  "100% Offline & Private" and the privacy policy's implication of local-only storage. Either add
  explicit excludes for the receipts/database, or soften the in-app and store copy.
