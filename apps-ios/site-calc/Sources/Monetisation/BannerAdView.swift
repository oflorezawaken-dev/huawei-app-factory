import GoogleMobileAds
import SwiftUI
import UIKit

/// A real AdMob banner. There is no simulated fallback on purpose: a fake ad
/// view would pass every check and ship an app that earns nothing.
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdsConfiguration.bannerUnitID
        banner.rootViewController = Self.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = Self.rootViewController
        }
    }

    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

enum AdsBootstrap {
    /// Starts the SDK once. Called after the first frame, so it never delays launch.
    static func start() {
        MobileAds.shared.start(completionHandler: nil)
    }
}
