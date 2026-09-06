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

## App icon and screenshots uploaded to AppGallery Connect (2026-09-06)

| Item | Result |
|---|---|
| Icon | Registered via run 34054098481 (initial, failed — missing lang) then 34054214365 (success) |
| Screenshots (en-US) | 5 files registered in one call, run 34054214365 |
| Tool | `factory/tools/agc_upload_assets.py`, `.github/workflows/receipt-lens-assets.yml` |

Note: AppGallery Connect's `app-file-info` endpoint rejected the icon upload with
`lang is necessary` even though the fileType-0 (icon) reference implementation we
checked didn't always pass one — this account/app requires `lang` on every
`app-file-info` call, icon included. The workflow now resolves and sends it for both.

Content rating was completed manually by the user in the console (date not recorded here).

## Privacy policy made public and linked in AppGallery Connect (2026-09-06)

| Item | Result |
|---|---|
| Repo visibility | Changed to public by the repo owner (required for GitHub Pages on the Free plan). |
| GitHub Pages | Enabled from `main` / `/docs`, build status `built`. |
| Live URL | https://oflorezawaken-dev.github.io/huawei-app-factory/privacy/ (HTTP 200, no auth) |
| AppGallery Connect | `privacyPolicy` field set via run 34054605709 (`agc_update_app_info.py`) |

The Claude Artifact version (`docs/privacy/artifact.html`, published at
https://claude.ai/code/artifact/d0654ce5-4a54-4e8e-a208-95e0eec411b6) is no longer the
canonical URL; the GitHub Pages page above is what's registered with Huawei. Both can
stay published, but if the policy text changes, update `docs/privacy/index.html`
(the one Pages actually serves) — `artifact.html` is a styled duplicate, not the source
of truth.

## Factory templatized (2026-09-06)

| Item | Result |
|---|---|
| Registry | `factory/apps.json` (receipt-lens: App ID 118896647, status in_review, 4 known_gaps) |
| Quality gate | `factory/tools/check_app.py` — receipt-lens: 7 PASS, 3 EXCUSED (petal_ads, internet_perm, no_stubs), 0 FAIL; `--strict` fails as intended |
| Generic build | `factory-build.yml` run 34056069465: plan, verify, release all green; artifacts `receipt-lens-release-apk`, `receipt-lens-release-aab`, `receipt-lens-debug-apk` |
| Generic store | `factory-store.yml` dry-run 34056102861: listing (9 langs), icon, screenshots, app-info all resolved from the registry |
| Removed | the five `receipt-lens-*.yml` workflows (commit 4e1d916) |
| Brain | `factory/prompts/*.md` + `factory/factory.py` (`research`, `spec`, `generate`, `fix`, `listing`, `privacy`, `build`, `store`, `publish`) |

Next: ReceiptLens 1.1 with the real Petal Ads SDK (closes the three excused gaps), then app #2.

## ReceiptLens 1.1.0 (versionCode 2) — real Petal Ads (2026-09-06)

| Item | Result |
|---|---|
| SDK | `com.huawei.hms:ads-lite:13.4.90.302` from `https://developer.huawei.com/repo/` (added to `settings.gradle.kts`) |
| Code | `ads/PetalAdsManager.kt` rewritten on the real SDK (`HwAds.init`, `InterstitialAd` with 60 s warm-up, 3 min spacing, 1 per 4 triggers); `ads/PetalBanner.kt` Compose banner (`BannerView`, smart size, 60 s refresh) + `LocalAdManager` |
| Placements | Banners: History bottom, Statistics end, Settings footer. Interstitial trigger: opening Statistics. Never on Scan / Review / Detail. |
| Manifest | `INTERNET`, `ACCESS_NETWORK_STATE` |
| Ad unit IDs | `BuildConfig.PETAL_BANNER_AD_ID` / `PETAL_INTERSTITIAL_AD_ID` from env `PETAL_*_AD_ID` (CI exports them from `factory/apps.json` → `ads`). Empty → Huawei TEST units `testw6vs28auh3` / `teste9ih9j0rc3` and `BuildConfig.PETAL_ADS_USING_TEST_IDS=true`. `factory-publish.yml` refuses to upload while the registry IDs are empty. |
| Copy | Settings privacy + Petal Ads texts and version string updated in 9 locales (apostrophes escaped for AAPT); privacy policy page and `store/listing.json` now disclose ads; 1.1 release notes in 9 languages |
| Local verification | `gradle :app:testDebugUnitTest :app:assembleDebug` green (5/5 tests), debug APK 24.3 MB (was 21.5 MB) with SDK classes present |
| Gate | `check_app.py receipt-lens`: petal_ads PASS, internet_perm PASS; excused: `ad_unit_ids` (until IDs are pasted), `ml_kit_ocr` |
| Removed | `ads/PetalAdConfig.kt` (reflection stub) |

Pending for release: paste the real banner + interstitial ad unit IDs into `factory/apps.json` → `apps[receipt-lens].ads`, then Factory Build → Factory Publish (upload) → submit 1.1 once 1.0 review concludes.

### 1.1 device verification (emulator, 2026-09-06)

- Installed the 1.1.0 debug APK on the `pixel_api35` emulator (after uninstalling the release-signed
  1.0 — `adb install -r` over a differently-signed build fails silently in a pipe).
- Settings shows the new privacy/ads copy and "Version 1.1.0". Layouts on History / Statistics /
  Settings render normally with no empty ad box.
- Logcat: `PetalAds: Petal Ads initialised (test ids: true)`; the SDK (`HiAdSDK.*`) creates and
  destroys `PPSBannerView` correctly and tries to bind the PPS service in `com.huawei.hwid`.
- Ads do not fill here because **Petal Ads needs HMS Core on the device**; the Google-image
  emulator has none, so loads end with error code 2 (network/service unavailable). Interstitial and
  banners degrade silently as designed. Ad rendering itself must be checked on a Huawei device (or an
  HMS-enabled image) — the factory has no such device in CI yet.
