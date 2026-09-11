import GoogleMobileAds
import SwiftUI
import UIKit

/// A real AdMob banner. There is no simulated fallback on purpose: a fake ad
/// view would pass every check and ship an app that earns nothing.
struct BannerAdView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdsConfiguration.bannerUnitID
        banner.rootViewController = Self.rootViewController
        banner.delegate = context.coordinator
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

    /// Records every banner impression into the shared activity log, so the
    /// interstitial's "never within 240 seconds of any other ad" rule also
    /// counts banner ads, not only other interstitials.
    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            Task { @MainActor in
                AdActivityLog.shared.recordBannerShown()
            }
        }
    }
}

enum AdsBootstrap {
    private static var started = false

    /// Asks for tracking permission, then starts the ad SDK -- in that order,
    /// once, on the first launch that follows First Run.
    ///
    /// App Review rejected PriceJar 1.0.0 (4) under guideline 2.1 for a prompt
    /// they could not find: it fired only after the user completed a specific
    /// action deep in the app, and a reviewer who never performed that action
    /// never saw it. ShiftSlip's spec asked for the same shape -- after the
    /// first saved shift -- so it would have been rejected the same way.
    ///
    /// Waiting for First Run keeps the intent behind that line: do not ask
    /// before the user has been told what the app is. Onboarding is where they
    /// are told, and it is somewhere a review pass reaches immediately.
    @MainActor
    static func startAfterTrackingPrompt(settings: AppSettings) async {
        guard !UITestMode.isActive, settings.hasCompletedFirstRun else { return }
        await TrackingAuthorization.requestIfNeeded(settings: settings)
        guard !started else { return }
        started = true
        MobileAds.shared.start(completionHandler: nil)
    }
}
