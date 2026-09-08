# Step: fix a failing Factory iOS Build

Read `factory/prompts/00-factory-rules.md` first. Input: the failing run URL or ID and
the app slug.

## Method

1. `gh run view <run_id> --log-failed` and read the FIRST real error, not the last line.
   `xcodebuild` output buries the cause: the final lines are usually
   `** BUILD FAILED **` and a command summary, while the real message is far above.
2. Reproduce locally:
   ```bash
   cd apps-ios/<slug>
   xcodegen generate
   xcodebuild test -project <App>.xcodeproj -scheme <App> \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO
   ```
   If the failure was in the screenshot job, reproduce with the `<App>Screenshots`
   scheme on a `Pro Max` destination instead.
3. Make the smallest change that fixes the root cause. Do not:
   - delete, skip or `XCTSkip` tests to go green,
   - lower a rule in `check_ios_app.py` or add a `known_gaps` entry to hide a real
     failure (`known_gaps` documents a gap a human must close, never a bug),
   - bump the `GoogleMobileAds` package version blindly,
   - change `PRODUCT_BUNDLE_IDENTIFIER`, `MARKETING_VERSION`,
     `CURRENT_PROJECT_VERSION`, the deployment target or the signing settings —
     those come from the registry and changing them here desynchronises the two.
4. Errors whose cause is not where it looks, all found while building the template:
   - `Multiple commands produce ... .app` → `PRODUCT_NAME` is empty.
   - `unable to resolve Swift module dependency` on `@testable import` →
     `ENABLE_TESTABILITY` is not YES in Debug.
   - `Undefined symbols` for the app's own types in a test target → the test target
     is missing `BUNDLE_LOADER: $(TEST_HOST)`.
   - Missing `GADApplicationIdentifier` at runtime, or usage strings gone → something
     regenerated `Info.plist`; XcodeGen's `info:` key overwrites the committed file,
     `INFOPLIST_FILE` does not.
   - A UI test seeing an empty accessibility hierarchy → a system alert (the ATT
     prompt) is covering the app, or the ad banner keeps it from ever going idle.
     Both are suppressed by the `-FactoryUITest` launch argument.
   - A button in a UI test that "does nothing" → two `.sheet` modifiers on one view;
     SwiftUI honours only one.
   - `Unable to find a device matching the destination` → check
     `xcrun simctl list devices available`; runner images move between iPhone
     generations.
5. Re-run locally, then `python factory/tools/check_ios_app.py <slug>`.
6. Commit as `fix(<slug>): <what and why>` with the error message quoted in the body.
   Push to the same branch. One fix attempt per run; if the second run still fails,
   stop and report what you found instead of trying a third blind change.
