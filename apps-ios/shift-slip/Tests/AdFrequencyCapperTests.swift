import XCTest
@testable import ShiftSlip

/// Drives the frequency capper with a fake clock across the exact 240-second
/// and third-saved-shift boundaries named in the acceptance criteria.
final class AdFrequencyCapperTests: XCTestCase {
    func testColdStartWithNoPriorAdAndEnoughShiftsAllowsShowing() {
        let capper = AdFrequencyCapper()
        XCTAssertTrue(capper.canShowInterstitial(now: .now, savedShiftCount: 3))
    }

    func testFewerThanThreeSavedShiftsBlocksTheInterstitial() {
        let capper = AdFrequencyCapper()
        XCTAssertFalse(capper.canShowInterstitial(now: .now, savedShiftCount: 2))
    }

    func testExactlyThreeSavedShiftsAllowsTheInterstitial() {
        let capper = AdFrequencyCapper()
        XCTAssertTrue(capper.canShowInterstitial(now: .now, savedShiftCount: 3))
    }

    func testJustBefore240SecondsIsBlocked() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let capper = AdFrequencyCapper(lastAdShownAt: start)
        XCTAssertFalse(capper.canShowInterstitial(now: start.addingTimeInterval(239), savedShiftCount: 5))
    }

    func testExactly240SecondsIsAllowed() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let capper = AdFrequencyCapper(lastAdShownAt: start)
        XCTAssertTrue(capper.canShowInterstitial(now: start.addingTimeInterval(240), savedShiftCount: 5))
    }

    func testJustAfter240SecondsIsAllowed() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let capper = AdFrequencyCapper(lastAdShownAt: start)
        XCTAssertTrue(capper.canShowInterstitial(now: start.addingTimeInterval(241), savedShiftCount: 5))
    }

    func testBannerImpressionAlsoCountsAgainstTheCap() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        var capper = AdFrequencyCapper()
        capper.recordAdShown(at: start, isInterstitial: false)
        XCTAssertFalse(capper.canShowInterstitial(now: start.addingTimeInterval(100), savedShiftCount: 5))
    }

    func testInterstitialShownOnceThisSessionBlocksASecondOneRegardlessOfElapsedTime() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        var capper = AdFrequencyCapper()
        capper.recordAdShown(at: start, isInterstitial: true)
        XCTAssertFalse(capper.canShowInterstitial(now: start.addingTimeInterval(10_000), savedShiftCount: 100))
    }

    @MainActor
    func testActivityLogResetForTestingClearsState() {
        let log = AdActivityLog.shared
        log.resetForTesting()
        log.recordInterstitialShown(at: .now)
        XCTAssertFalse(log.canShowInterstitial(now: .now, savedShiftCount: 5))
        log.resetForTesting()
        XCTAssertTrue(log.canShowInterstitial(now: .now, savedShiftCount: 5))
    }
}
