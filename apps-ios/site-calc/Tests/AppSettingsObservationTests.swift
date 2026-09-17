import XCTest
import Observation
@testable import SiteCalc

/// `@Observable` generates change tracking for **stored** properties only.
/// Every property on `AppSettings` is computed over `UserDefaults`, so until
/// each accessor called `access(keyPath:)` and `withMutation(keyPath:)` by
/// hand, the class was observable in name only: a write updated the stored
/// value and notified nobody.
///
/// What that cost: `FirstRunView` sets `firstRunCompleted = true` and
/// `RootView` decides between onboarding and the app on that value. The write
/// happened, no re-render followed, and a fresh install sat on the onboarding
/// screen after the user tapped either button. Every install. It reached a
/// screenshot run before anything noticed, because the unit tests all build
/// `AppSettings` directly and read it back, which works perfectly well without
/// any observation at all.
final class AppSettingsObservationTests: XCTestCase {
    private func freshSettings(_ name: String = #function) -> AppSettings {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return AppSettings(defaults: defaults)
    }

    /// Runs `mutate` and reports whether an observer watching `read` was told.
    private func notifiesObserver(_ settings: AppSettings,
                                   read: @escaping (AppSettings) -> Void,
                                   mutate: (AppSettings) -> Void) -> Bool {
        var notified = false
        withObservationTracking { read(settings) } onChange: { notified = true }
        mutate(settings)
        return notified
    }

    func testFirstRunCompletedNotifiesItsObservers() {
        let settings = freshSettings()
        XCTAssertTrue(notifiesObserver(settings, read: { _ = $0.firstRunCompleted },
                                        mutate: { $0.firstRunCompleted = true }),
                      "RootView watches this: without a notification the app never leaves onboarding")
    }

    func testEverySettingTheUserCanChangeNotifiesItsObservers() {
        let checks: [(String, (AppSettings) -> Void, (AppSettings) -> Void)] = [
            ("preferredSystem", { _ = $0.preferredSystem }, { $0.preferredSystem = .metric }),
            ("fractionPrecision", { _ = $0.fractionPrecision }, { $0.fractionPrecision = .thirtySecond }),
            ("preferredMetricUnit", { _ = $0.preferredMetricUnit }, { $0.preferredMetricUnit = .millimeter }),
            ("maxRiserHeight", { _ = $0.maxRiserHeight }, { $0.maxRiserHeight = Length(7, .inches) }),
            ("minTreadDepth", { _ = $0.minTreadDepth }, { $0.minTreadDepth = Length(10, .inches) }),
            ("studSpacing", { _ = $0.studSpacing }, { $0.studSpacing = Length(24, .inches) }),
            ("sheetWidth", { _ = $0.sheetWidth }, { $0.sheetWidth = Length(5, .feet) }),
            ("sheetHeight", { _ = $0.sheetHeight }, { $0.sheetHeight = Length(10, .feet) }),
            ("tileWastePercent", { _ = $0.tileWastePercent }, { $0.tileWastePercent = Rational(15) }),
            ("concreteBagYieldCubicFeet", { _ = $0.concreteBagYieldCubicFeet },
             { $0.concreteBagYieldCubicFeet = Rational(45, 100) }),
        ]
        for (name, read, mutate) in checks {
            let settings = freshSettings("observation.\(name)")
            XCTAssertTrue(notifiesObserver(settings, read: read, mutate: mutate),
                          "changing \(name) notifies nobody, so nothing on screen updates")
        }
    }

    /// The value still has to survive a relaunch -- observation must not have
    /// been bought by moving the truth out of UserDefaults.
    func testValuesStillPersist() {
        let name = "observation.persistence"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)

        let first = AppSettings(defaults: defaults)
        first.preferredSystem = .metric
        first.fractionPrecision = .sixtyFourth
        first.firstRunCompleted = true

        let second = AppSettings(defaults: defaults)
        XCTAssertEqual(second.preferredSystem, .metric)
        XCTAssertEqual(second.fractionPrecision, .sixtyFourth)
        XCTAssertTrue(second.firstRunCompleted)
    }
}
