# Step: generate the Android app from its spec

Read `factory/prompts/00-factory-rules.md` first. Input: `specifications/<slug>.json`
and its registry entry in `factory/apps.json`.

## Method

1. **Skeleton.** Copy `apps/receipt-lens` to `apps/<slug>`. Rename package, namespace,
   `applicationId`, `rootProject.name`, app name strings, and launcher icon. Delete
   ReceiptLens-specific features (receipts, OCR, CSV export) unless the spec needs them.
   Keep: Gradle setup, theme, navigation shell, Room setup, settings screen pattern,
   9-language string structure, `PetalAds` placement pattern (but implemented for real,
   see rule 1).
2. **Petal Ads for real.** Add `maven { url = uri("https://developer.huawei.com/repo/") }`
   to `settings.gradle.kts` (both `pluginManagement` and `dependencyResolutionManagement`)
   and `implementation("com.huawei.hms:ads-lite:<current version>")`. Look up the
   current version on the Huawei Maven repo; do not invent one. Read ad unit IDs from
   `BuildConfig` fields populated from Gradle properties/env
   (`PETAL_BANNER_AD_ID`, `PETAL_INTERSTITIAL_AD_ID`); default to Huawei's documented
   test IDs when unset so debug builds show test ads. Declare `INTERNET`.
3. **Features.** Implement exactly the V1 feature list from the spec, screen by screen,
   with real persistence and real logic. No placeholder screens, no fake data generators
   posing as features, no TODO stubs behind buttons.
4. **Strings.** Every user-visible string in `res/values/strings.xml` and translated into
   every registry language folder. Arabic layouts must work RTL.
5. **Tests.** Unit tests for pure logic (parsers, calculators, formatters). No
   Robolectric sample tests.
6. **Verify.** In `apps/<slug>`: `gradle :app:testDebugUnitTest` and
   `gradle :app:assembleDebug`. Read the output. Fix until both pass.
7. **Store scaffolding.** `store/icon/icon-512.png` (render from the launcher vector),
   `store/listing.json` (English complete), `docs/<slug>/privacy/index.html`
   (copy `docs/privacy/index.html` and rewrite honestly for this app, including the
   Petal Ads disclosure). Add an instrumented screenshot test or a documented
   `adb` script under `apps/<slug>/store/screenshots/README.md` describing how to
   capture the 5 store screenshots.
8. **Gate.** `python factory/tools/check_app.py <slug> --strict` must pass.
9. **PR.** Branch `app/<slug>`, small commits, then
   `gh pr create --title "feat(<slug>): initial app" --body-file <summary>` where the
   body lists: features implemented, what was left out and why, test results, gate
   output, and anything a human must decide.

If something in the spec is impossible or contradictory, stop, write the problem in
the PR body, and do not paper over it.
