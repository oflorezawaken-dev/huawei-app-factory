import Foundation

/// Screenshot runs launch the app with -FactoryUITest. In that mode the app
/// skips the tracking prompt and the ad banner, for two reasons: a system
/// alert hides the whole hierarchy from XCUITest, and a banner that reads
/// "Test mode" must never end up in a store screenshot.
enum UITestMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-FactoryUITest")
    }
}
