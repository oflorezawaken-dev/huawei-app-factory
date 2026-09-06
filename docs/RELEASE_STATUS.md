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
