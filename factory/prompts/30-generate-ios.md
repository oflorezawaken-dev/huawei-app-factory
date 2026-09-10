# Step: generate the iOS app from its spec

Read `factory/prompts/00-factory-rules.md` first. Input: `specifications/<slug>.json`
and its registry entry in `factory/apps.json`.

## Do the work in this session

Build the app here, directly, with your own tools. Do not delegate it to a
background agent, a sub-agent or a separate git worktree: this step is invoked as
headless `claude -p`, and work handed to a background task is terminated when the
step's own session ends -- the first PriceJar run lost a finished models-and-logic
layer that way, and reported success while the tree held one file. Long is fine;
detached is not.

## Method

1. **Skeleton.** Copy `apps-ios/_template` to `apps-ios/<slug>`. Rename `AppTemplate`
   to the app's name everywhere: `project.yml` (`name`, the three target names, both
   scheme names), the folder's Swift files, the test targets, `@testable import`, and
   the `Config/AdMob.xcconfig` defaults for `APP_BUNDLE_ID` and
   `IAP_REMOVE_ADS_PRODUCT_ID`. Delete the template's sample `Item` model and its
   Today/All screens once you have replaced them; keep the monetisation layer, the
   settings screen, `UITestMode`, `PrivacyInfo.xcprivacy`, the asset catalog and the
   String Catalog structure.

2. **Do not restructure `project.yml`.** Its settings were established by building the
   template and each one exists for a reason that cost a build cycle to find:
   - `PRODUCT_NAME: $(TARGET_NAME)` — without it Xcode leaves it empty and three
     targets collide producing `.app`.
   - `ENABLE_TESTABILITY: YES` in Debug — without it `@testable import` cannot resolve.
   - `BUNDLE_LOADER: $(TEST_HOST)` on the unit-test target — without it every app
     symbol comes back undefined at link time.
   - `INFOPLIST_FILE` pointing at the committed `Sources/Info.plist`, and **never**
     XcodeGen's `info:` key — that key *generates* the plist and silently overwrites
     the committed one, taking the ad app ID and usage strings with it.
   - `excludes: [Info.plist]` on the sources entry, so the plist is not also copied as
     a resource.
   - `TARGETED_DEVICE_FAMILY` set from the spec's `devices`: `"1"` for iPhone only,
     `"1,2"` for iPhone and iPad. XcodeGen does not set it and Xcode's default is
     universal, so an iPhone-only app shipped to Apple as universal — and Apple then
     demanded iPad screenshots for it. The gate's `device_family` rule checks this.
   - `UIRequiresFullScreen: true` in Info.plist. Without it Apple's upload servers reject an iPhone-only, portrait-only app with error 90474 ("iPad Multitasking support requires these orientations"), because a single-orientation app must either declare all four orientations or opt out of iPad multitasking entirely. The first PriceJar upload found this after Archive and Export both succeeded.
   Add targets or dependencies if the spec needs them; do not rewrite what is there.

3. **AdMob is already wired.** The template has the real `GoogleMobileAds` SPM package,
   `BannerAdView`, `AdsBootstrap`, ATT and `AdsConfiguration` reading IDs from
   `Info.plist` via the xcconfig. Do not reimplement it and do not replace it with a
   stand-in. What you must do is honour the spec's `monetization` section: put the
   banner only on `banner_screens`, fire the interstitial only at
   `interstitial_moments`, and — this is a product constraint, not a nicety —
   guarantee that no ad can appear on anything in `ads_never_on`.

4. **Features.** Implement the spec's feature list, screen by screen, with real
   persistence and real logic. No placeholder screens, no `TODO`, no `fatalError`
   behind a button, no fake data generator posing as a feature. The quality gate's
   `no_stubs` rule fails the build on those, and the reason it exists is that a
   previous generated app shipped a fake OCR that passed twenty-two steps unnoticed.
   If the full list does not fit, implement every P0 completely rather than all of
   them partially, and say plainly in the PR what you left out.

5. **Accessibility identifiers on every control, from the first line.** The screenshot
   test addresses controls by identifier; automating by coordinates is what made the
   Android lane's screenshot capture unreliable. Three traps found while building the
   template: a `TabView`'s tab buttons do **not** inherit an identifier from the tab
   content; `app.staticTexts["X"]` matches an *identifier*, not a label; and **an iPad
   has no tab bar at all** — the same tabs are plain buttons there, so
   `app.tabBars.buttons["<label>"]` finds nothing and the iPad screenshot run fails.
   Address tabs through a helper that tries the tab bar and falls back to a plain
   button match, the way the PriceJar template's `tabButton(_:)` does.

6. **Never let a UI test reach a system alert, and never `await` one.** The ATT
   prompt is the case that bites: nothing dismisses a system alert during an
   XCUITest run, so `await ATTrackingManager.requestTrackingAuthorization()`
   never returns and every line after it in that function never runs. In PriceJar
   the line after it dismissed a sheet, so saving a price left the form open and
   the screenshot test failed 20s later at an unrelated assertion, intermittently.
   The template's `TrackingAuthorization.requestIfNeeded()` guards on
   `UITestMode.isActive`; keep that guard at the call site, not only in a comment.

7. **One `.sheet` per view.** SwiftUI honours a single `.sheet` modifier per view; a
   second one is silently ignored and the button appears dead. If a screen presents
   more than one sheet, drive them from one `Identifiable` enum.

8. **Strings.** Every user-visible string goes in `Sources/Localizable.xcstrings`,
   translated into all nine registry languages. Arabic must lay out RTL.

9. **Tests.** XCTest for the pure logic the spec calls out as critical — for a
   calculation the app's premise depends on, cover the conversion table exhaustively,
   including both measurement systems and locale decimal separators. Fix a timezone in
   date tests (`Calendar.timeZone = UTC`) or they pass locally and fail in CI.

10. **Verify — actually run it, do not assume.**
   ```bash
   cd apps-ios/<slug>
   xcodegen generate
   xcodebuild test -project <App>.xcodeproj -scheme <App> \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO
   ```
   Then the screenshots, on a 6.9" device, which is the only iPhone set Apple requires:
   ```bash
   xcodebuild test -project <App>.xcodeproj -scheme <App>Screenshots \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
     -resultBundlePath shots.xcresult CODE_SIGNING_ALLOWED=NO
   xcrun xcresulttool export attachments --path shots.xcresult --output-path shots-out
   ```
   The screenshot test must walk the app's real screens and leave it in a populated
   state — an empty app makes a bad store screenshot. It launches with `-FactoryUITest`,
   which suppresses the ATT prompt and the banner: a system alert hides the whole
   hierarchy from XCUITest, and a screenshot showing a "Test mode" banner is not
   shippable. Copy 3-5 of the exported PNGs into
   `apps-ios/<slug>/store/screenshots/en/`, named in display order. They must be
   1320x2868 with no alpha channel.

   Use `xcrun simctl list devices available` if those simulator names are absent, and
   look at the screenshots before continuing — they are the only way to see the app.

11. **Store scaffolding.** A 1024x1024 app icon in the asset catalog, PNG, **no alpha
    channel** (Apple rejects transparency); its own visual identity, not the template's
    green. `store/listing.json` with the English entry complete and within Apple's
    limits. `docs/<slug>/privacy/index.html` and `docs/<slug>/support/index.html` —
    write them honestly for this app, disclosing AdMob and IDFA, and matching the
    spec's privacy section. Do not copy another app's page without rewriting it.

12. **Gate.**
    ```bash
    python factory/tools/check_ios_app.py <slug>
    ```
    `admob_unit_ids` will FAIL when you run this locally, and that is expected:
    factory rule 5 keeps ad unit IDs out of git, so the real ones live in GitHub
    Actions repository variables (`ADMOB_<SLUG>_APP_ID` and the two unit IDs) and
    the registry entry is empty. CI passes them in as `FACTORY_VARS`. To see what
    CI will see:
    ```bash
    FACTORY_VARS="$(gh variable list --json name,value | python3 -c 'import json,sys; print(json.dumps({v["name"]: v["value"] for v in json.load(sys.stdin)}))')" \
      python factory/tools/check_ios_app.py <slug>
    ```
    Do **not** paste ad unit IDs into `factory/apps.json` -- the `ad_ids_not_in_git`
    rule fails on that. Add
    `"known_gaps": {"admob_unit_ids": "AdMob console pending; step 6 of the iOS flow."}`
    only when the variables genuinely do not exist yet, and say so in the PR.
    Everything else must pass. Never hide a failure by deleting a test or
    loosening a rule.

13. **PR.** Branch `app/<slug>`, small commits, then `gh pr create` with a body that
    lists: features implemented, what was left out and why, unit and screenshot test
    results, the gate output, the screenshots, and anything a human must decide. Attach
    or reference the screenshots — they are what the human reviews.

If something in the spec is impossible or contradictory, stop, write the problem in
the PR body, and do not paper over it.
