# Huawei App Factory — rules every step must respect

You are working inside the `huawei-app-factory` repository. Read `factory/apps.json`
first; it is the registry of apps and the source of factory-wide rules.

## Non-negotiable rules

1. **Petal Ads is mandatory and must be real.** Every app includes the Huawei Maven
   repository (`https://developer.huawei.com/repo/`) and the Petal Ads SDK dependency
   (`com.huawei.hms:ads-lite` or `com.huawei.hms:ads`) in Gradle, declares the
   `INTERNET` permission, and shows ads on non-critical screens. Ad unit IDs come from
   environment/BuildConfig, never hard-coded. Never during capture, processing, review,
   or data entry.
2. **No fake integrations.** Never use `Class.forName("com.huawei...")` or any
   reflection stand-in for an SDK. If a feature needs an SDK, add the dependency and call
   it directly. If you cannot, leave the feature out and say so in the spec.
3. **Offline-first core.** The app's main job works without network. Ads may need
   network; nothing else does. No Firebase, no Google Play Services, no Google AI, no
   backend, no accounts.
4. **Truth in copy.** Store listing, privacy policy, and in-app text describe what the
   shipped build actually does. Ads are disclosed. "100% offline" is only claimed if
   `allowBackup` is false or backup rules exclude user data.
5. **Secrets never touch the repo.** No keystores, API keys, client secrets, ad unit IDs
   or `agconnect-services.json` in git. Use GitHub secrets/variables and `BuildConfig`.
6. **Stack.** Android native, Kotlin, Jetpack Compose + Material 3, MVVM, Room,
   Coroutines/Flow, minSdk 26, Gradle and Java versions from `factory/apps.json`.
   Start new apps by copying `apps/receipt-lens` as the skeleton and stripping what the
   spec doesn't need.
7. **Quality gate.** `python factory/tools/check_app.py <slug>` must pass before you
   open a pull request. `--strict` must pass for any *new* app (no excused gaps).
8. **Verify, don't assume.** Run `gradle :app:testDebugUnitTest` and
   `gradle :app:assembleDebug` inside the app folder and read the output. Fix real
   errors; never delete a test to make CI green unless the test itself is wrong and you
   explain why in the commit message. Then **run the app on a real phone**, tap through
   every screen, and take the store screenshots from that build. Unit tests cannot see
   layout: Sudoku 1.0 shipped a number pad whose ninth key fell off the right edge of a
   384dp screen (nine 48dp keys need 432dp), and the digit 9 was simply unreachable.
   Assume ~360dp of usable width: no row of fixed-size controls may assume it fits,
   every such row measures first and wraps or shrinks, and the main content takes the
   room the controls leave rather than claiming its own size first.
9. **Privacy tags are part of every app.** AppGallery requires a personal-data
   declaration ("Privacy tags" under Version information) and rejects releases whose
   tags contradict the app; Petal Ads alone means every factory app collects personal
   data (OAID, IP, device and app info). Each app keeps `store/privacy-tags.json` using
   the exact labels from https://developer.huawei.com/consumer/en/doc/app/privacy-label ;
   `python factory/tools/privacy_tags.py init <slug>` writes the baseline (manifest
   permissions + Petal Ads block), you add what the code really stores or processes
   (photos, transaction records, health data...), `check` validates it, `render --write`
   produces the console checklist `store/privacy-tags.md`. Manifest, privacy policy and
   privacy tags must agree. There is no API for this step: a human ticks the boxes.
10. **The store name must contain the search keyword.** On AppGallery, discovery is
    search-driven: an invented brand name gets no impressions. Every app ships a store
    name shaped `Keyword - short descriptor` or `Brand - Keyword`, and `store/listing.json`
    carries a **per-language `appName`** with the keyword translated (Spanish matters
    most; AppGallery is strong in Latin America and Spain). Never name an app after
    someone else's trademark. The in-app `app_name` string may stay short and brandable;
    it is the store `appName` that has to carry the keyword.
11. **Every new app enables App Signing in AppGallery Connect before its first upload**
    (method 1: AGC generates and keeps the signature key). Without it, losing the local
    keystore makes the app impossible to update forever -- Huawei does not allow changing
    a signature key, and enrolling later requires the very key you lost. Keep the factory
    keystore and its passwords backed up in a password manager as well.
12. **Small, explained commits.** One concern per commit. Never force-push. Never commit
   secrets, build output, or `.gradle/`.

## Where things live

| Thing | Path |
|---|---|
| App registry | `factory/apps.json` |
| Spec template / specs | `specifications/APP_SPEC_TEMPLATE.json`, `specifications/<slug>.json` |
| App code | `apps/<slug>/` |
| Store assets | `apps/<slug>/store/{icon/icon-512.png, screenshots/<lang>/*.png, listing.json}` |
| Privacy policy page | `docs/<slug>/privacy/index.html` (ReceiptLens uses `docs/privacy/`) |
| Privacy tags (AppGallery data declaration) | `apps/<slug>/store/privacy-tags.json` + rendered `privacy-tags.md`; tool `factory/tools/privacy_tags.py` |
| AGC tools | `factory/tools/agc_*.py` |
| Quality gate | `factory/tools/check_app.py` |
| Workflows | `.github/workflows/factory-*.yml` |
| Lessons learned | `docs/RELEASE_STATUS.md`, `docs/APPGALLERY_PUBLISHING.md` |
