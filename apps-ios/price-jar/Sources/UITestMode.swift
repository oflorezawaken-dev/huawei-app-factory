import Foundation

/// Screenshot runs launch the app with -FactoryUITest. In that mode the app
/// skips the tracking prompt and the ad banner, for two reasons: a system
/// alert hides the whole hierarchy from XCUITest, and a banner that reads
/// "Test mode" must never end up in a store screenshot. The same flag also
/// makes SampleData available for immediate seeding via a second launch
/// argument, so screenshot tests can populate the app deterministically.
enum UITestMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-FactoryUITest")
    }

    /// -FactorySeedSampleData asks the app to load the twelve sample items on
    /// launch, skipping the First Run offer, so UI tests do not depend on
    /// tapping through onboarding to reach a populated screen.
    static var shouldSeedSampleData: Bool {
        ProcessInfo.processInfo.arguments.contains("-FactorySeedSampleData")
    }
}
