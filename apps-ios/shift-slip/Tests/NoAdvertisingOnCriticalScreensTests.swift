import XCTest
@testable import ShiftSlip

/// F013's `ads_never_on` list: the entry form, the tip-out split, the daily
/// tip record, export and the share flow, the minimum-wage check, first run,
/// settings and the purchase/restore flow must never show an ad -- not
/// merely hide one. Since none of these views ever construct a `BannerAdView`
/// or call the interstitial, the ad container is structurally absent, which
/// this scans for directly rather than driving a slower UI test.
final class NoAdvertisingOnCriticalScreensTests: XCTestCase {
    private let criticalScreenFiles = [
        "LogShiftView.swift",       // S002 Log Shift
        "TipOutSplitView.swift",    // S003 Tip-Out Split
        "DailyTipRecordView.swift", // S006 Daily Tip Record
        "ExportView.swift",         // S010 Export and the share flow
        "MinimumWageCheckView.swift", // S008 Minimum-Wage Check
        "FirstRunView.swift",       // S012 First Run
        "SettingsView.swift",       // S011 Settings, and the purchase/restore flow
    ]

    func testNoneOfTheCriticalScreensConstructAnAdView() throws {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<2 { url.deleteLastPathComponent() }
        let featuresRoot = url.appendingPathComponent("Sources/Features")

        var offenders: [String] = []
        for fileName in criticalScreenFiles {
            let fileURL = featuresRoot.appendingPathComponent(fileName)
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            if source.contains("BannerAdView(") || source.contains("TabRootBanner(")
                || source.contains("InterstitialAdController") || source.contains("presentIfAllowed") {
                offenders.append(fileName)
            }
        }
        XCTAssertTrue(offenders.isEmpty, "Ad container referenced on a critical screen: \(offenders)")
    }
}
