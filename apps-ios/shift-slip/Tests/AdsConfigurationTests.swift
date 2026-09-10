import XCTest
@testable import ShiftSlip

final class AdsConfigurationTests: XCTestCase {
    func testTemplateShipsGoogleTestIDsSoNoRealAdIsServedByAccident() {
        // A developer build (and every PR, which cannot read repo secrets)
        // must never carry live IDs; CI injects the real ones at build time.
        XCTAssertTrue(AdsConfiguration.isUsingTestIDs)
        XCTAssertTrue(AdsConfiguration.appID.hasPrefix(AdsConfiguration.testIDPrefix))
    }

    func testAdUnitIDsAreReadFromTheBundleNotHardcoded() {
        XCTAssertFalse(AdsConfiguration.bannerUnitID.isEmpty)
        XCTAssertFalse(AdsConfiguration.interstitialUnitID.isEmpty)
        XCTAssertFalse(AdsConfiguration.removeAdsProductID.isEmpty)
    }

    /// F013: "no ID is ever a literal in tracked source." Scans every Swift
    /// file under Sources/ for a "ca-app-pub-" literal; the only places that
    /// string may appear are Config/AdMob.xcconfig (not scanned here) and
    /// AdsConfiguration.swift's `testIDPrefix`, which is Google's own public
    /// test-ID root used to detect a test build -- not a real ad unit ID.
    func testNoAdMobLiteralAppearsAnywhereInTrackedSwiftSource() throws {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<2 { url.deleteLastPathComponent() } // Tests/ -> app root
        let sourcesRoot = url.appendingPathComponent("Sources")
        let enumerator = FileManager.default.enumerator(at: sourcesRoot, includingPropertiesForKeys: nil)
        var offenders: [String] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift", fileURL.lastPathComponent != "AdsConfiguration.swift" else { continue }
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            if text.contains("ca-app-pub-") {
                offenders.append(fileURL.lastPathComponent)
            }
        }
        XCTAssertTrue(offenders.isEmpty, "ca-app-pub- literal found in tracked Swift source: \(offenders)")
    }
}
