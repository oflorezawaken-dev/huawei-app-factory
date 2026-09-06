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
   explain why in the commit message.
9. **Small, explained commits.** One concern per commit. Never force-push. Never commit
   secrets, build output, or `.gradle/`.

## Where things live

| Thing | Path |
|---|---|
| App registry | `factory/apps.json` |
| Spec template / specs | `specifications/APP_SPEC_TEMPLATE.json`, `specifications/<slug>.json` |
| App code | `apps/<slug>/` |
| Store assets | `apps/<slug>/store/{icon/icon-512.png, screenshots/<lang>/*.png, listing.json}` |
| Privacy policy page | `docs/<slug>/privacy/index.html` (ReceiptLens uses `docs/privacy/`) |
| AGC tools | `factory/tools/agc_*.py` |
| Quality gate | `factory/tools/check_app.py` |
| Workflows | `.github/workflows/factory-*.yml` |
| Lessons learned | `docs/RELEASE_STATUS.md`, `docs/APPGALLERY_PUBLISHING.md` |
