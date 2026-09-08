import XCTest
@testable import PriceJar

final class AdsConfigurationTests: XCTestCase {
    func testDeveloperBuildShipsGoogleTestIDsSoNoRealAdIsServedByAccident() {
        XCTAssertTrue(AdsConfiguration.isUsingTestIDs)
        XCTAssertTrue(AdsConfiguration.appID.hasPrefix(AdsConfiguration.testIDPrefix))
    }

    func testAdUnitIDsAreReadFromTheBundleNotHardcoded() {
        XCTAssertFalse(AdsConfiguration.bannerUnitID.isEmpty)
        XCTAssertFalse(AdsConfiguration.interstitialUnitID.isEmpty)
        XCTAssertFalse(AdsConfiguration.removeAdsProductID.isEmpty)
    }

    func testRemoveAdsProductIDMatchesTheRegistry() {
        XCTAssertEqual(AdsConfiguration.removeAdsProductID, "com.proapps.pricejar.removeads")
    }

    /// No `ca-app-pub-` literal may exist in tracked Swift source; every ID
    /// must come through `AdsConfiguration` from the xcconfig instead.
    /// `AdsConfiguration.swift` itself is the one allowed exception: it
    /// holds `testIDPrefix`, the shared prefix used to detect Google's test
    /// IDs, which is not an ad unit ID being served.
    func testNoAdUnitLiteralExistsInTrackedSwiftSource() throws {
        let sourcesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        let enumerator = FileManager.default.enumerator(at: sourcesURL, includingPropertiesForKeys: nil)
        var offenders: [String] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift", url.lastPathComponent != "AdsConfiguration.swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            if text.contains("ca-app-pub-") {
                offenders.append(url.lastPathComponent)
            }
        }
        XCTAssertTrue(offenders.isEmpty, "ca-app-pub- literal found in: \(offenders)")
    }
}
