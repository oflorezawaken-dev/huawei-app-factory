import XCTest
@testable import PriceJar

/// Drives the frequency capper with a fake clock across the exact 240 second
/// boundary named in the acceptance criteria, and confirms the interstitial
/// never fires on a cold start or more than once per session.
final class AdFrequencyCapperTests: XCTestCase {
    func testColdStartWithNoPriorAdAllowsShowing() {
        let capper = AdFrequencyCapper()
        XCTAssertTrue(capper.canShowInterstitial(now: .now))
    }

    func testJustBefore240SecondsIsBlocked() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let capper = AdFrequencyCapper(lastAdShownAt: start)
        XCTAssertFalse(capper.canShowInterstitial(now: start.addingTimeInterval(239)))
    }

    func testExactly240SecondsIsAllowed() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let capper = AdFrequencyCapper(lastAdShownAt: start)
        XCTAssertTrue(capper.canShowInterstitial(now: start.addingTimeInterval(240)))
    }

    func testJustAfter240SecondsIsAllowed() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        let capper = AdFrequencyCapper(lastAdShownAt: start)
        XCTAssertTrue(capper.canShowInterstitial(now: start.addingTimeInterval(241)))
    }

    func testBannerImpressionAlsoCountsAgainstTheCap() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        var capper = AdFrequencyCapper()
        capper.recordAdShown(at: start, isInterstitial: false)
        XCTAssertFalse(capper.canShowInterstitial(now: start.addingTimeInterval(100)))
    }

    func testInterstitialShownOnceThisSessionBlocksASecondOne() {
        let start = Date(timeIntervalSince1970: 1_780_000_000)
        var capper = AdFrequencyCapper()
        capper.recordAdShown(at: start, isInterstitial: true)
        XCTAssertFalse(capper.canShowInterstitial(now: start.addingTimeInterval(10_000)),
                       "at most one interstitial per session, regardless of elapsed time")
    }

    @MainActor
    func testActivityLogResetForTestingClearsState() {
        let log = AdActivityLog.shared
        log.recordInterstitialShown(at: .now)
        XCTAssertFalse(log.canShowInterstitial(now: .now))
        log.resetForTesting()
        XCTAssertTrue(log.canShowInterstitial(now: .now))
    }
}
