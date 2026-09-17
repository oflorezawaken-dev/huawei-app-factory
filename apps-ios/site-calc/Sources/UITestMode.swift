import Foundation

/// Screenshot runs launch the app with -FactoryUITest. In that mode the app
/// skips the tracking prompt and the ad banner, for two reasons: a system
/// alert hides the whole hierarchy from XCUITest, and a banner that reads
/// "Test mode" must never end up in a store screenshot.
enum UITestMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-FactoryUITest")
    }

    /// Normally a UI-test run skips First Run so the walk starts inside the
    /// app. The screenshot run wants the opposite: First Run is where the
    /// sample job is offered, and a Jobs list with the sample in it is the
    /// state a new user -- and an App Store reviewer -- actually sees. Without
    /// this the walk photographed an empty Jobs screen and called it the lead
    /// store asset.
    static var startsAtFirstRun: Bool {
        ProcessInfo.processInfo.arguments.contains("-FactoryUITestFirstRun")
    }
}
