import XCTest
@testable import AppTemplate

final class ItemTests: XCTestCase {
    /// Fixed to UTC so the comparison does not change with the runner's timezone.
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    func testNewItemIsDueSoItIsNeverHidden() {
        let item = Item(title: "Fern")
        XCTAssertNil(item.nextDue)
        XCTAssertTrue(item.isDue())
    }

    func testItemDoneTodayIsNotDueUntilTheIntervalPasses() {
        let today = Date(timeIntervalSince1970: 1_780_000_000)
        let item = Item(title: "Fern", intervalDays: 7, lastDone: today)
        XCTAssertFalse(item.isDue(on: today, calendar: calendar))
        let sixDaysLater = calendar.date(byAdding: .day, value: 6, to: today)!
        XCTAssertFalse(item.isDue(on: sixDaysLater, calendar: calendar))
    }

    func testItemBecomesDueExactlyOnTheIntervalDay() {
        let today = Date(timeIntervalSince1970: 1_780_000_000)
        let item = Item(title: "Fern", intervalDays: 7, lastDone: today)
        let sevenDaysLater = calendar.date(byAdding: .day, value: 7, to: today)!
        XCTAssertTrue(item.isDue(on: sevenDaysLater, calendar: calendar))
    }

    func testOverdueItemStaysDue() {
        let today = Date(timeIntervalSince1970: 1_780_000_000)
        let item = Item(title: "Fern", intervalDays: 3, lastDone: today)
        let muchLater = calendar.date(byAdding: .day, value: 40, to: today)!
        XCTAssertTrue(item.isDue(on: muchLater, calendar: calendar))
    }

    func testDueComparisonIgnoresTimeOfDay() {
        // An item that becomes due at 18:00 must already count as due at 08:00
        // the same day; comparing raw instants would slip it to the next day.
        let evening = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 18))!
        let item = Item(title: "Fern", intervalDays: 1, lastDone: evening)
        let nextMorning = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 8))!
        XCTAssertTrue(item.nextDue! > nextMorning, "next due is later in the day than the check")
        XCTAssertTrue(item.isDue(on: nextMorning, calendar: calendar))
    }

    func testItemIsNotDueTheDayBeforeItsInterval() {
        let evening = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 18))!
        let item = Item(title: "Fern", intervalDays: 2, lastDone: evening)
        let dayBefore = calendar.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 23))!
        XCTAssertFalse(item.isDue(on: dayBefore, calendar: calendar))
    }
}

final class AdsConfigurationTests: XCTestCase {
    func testTemplateShipsGoogleTestIDsSoNoRealAdIsServedByAccident() {
        // The template must never carry live IDs; the registry supplies those in CI.
        XCTAssertTrue(AdsConfiguration.isUsingTestIDs)
        XCTAssertTrue(AdsConfiguration.appID.hasPrefix(AdsConfiguration.testIDPrefix))
    }

    func testAdUnitIDsAreReadFromTheBundleNotHardcoded() {
        XCTAssertFalse(AdsConfiguration.bannerUnitID.isEmpty)
        XCTAssertFalse(AdsConfiguration.interstitialUnitID.isEmpty)
        XCTAssertFalse(AdsConfiguration.removeAdsProductID.isEmpty)
    }
}
