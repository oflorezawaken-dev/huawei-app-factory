import Foundation

/// Ad identifiers, read from Info.plist so they come from the xcconfig and can
/// be swapped in CI without touching tracked source.
enum AdsConfiguration {
    /// Google's public test identifiers. A build still carrying these must never
    /// reach review; the publish workflow refuses to submit one.
    static let testIDPrefix = "ca-app-pub-3940256099942544"

    static var appID: String { value(for: "GADApplicationIdentifier") }
    static var bannerUnitID: String { value(for: "ADMOB_BANNER_UNIT_ID") }
    static var interstitialUnitID: String { value(for: "ADMOB_INTERSTITIAL_UNIT_ID") }
    static var removeAdsProductID: String { value(for: "IAP_REMOVE_ADS_PRODUCT_ID") }

    static var isUsingTestIDs: Bool {
        [appID, bannerUnitID, interstitialUnitID].contains { $0.hasPrefix(testIDPrefix) }
    }

    private static func value(for key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}
