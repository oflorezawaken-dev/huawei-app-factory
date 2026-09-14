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
    /// Apple rejected 1.0.0 (4) under guideline 2.1 because the tracking prompt
    /// could not be found. It used to fire from VerdictView, after the user saved
    /// their very first price, so a reviewer who opened Settings and never
    /// completed a price entry never saw it at all. The SDK also started at
    /// launch, before the prompt, which is the opposite of what Apple asks for.
    ///
    /// Waiting for First Run keeps the spec's intent -- never ask before the user
    /// has been told what the app is -- while putting the prompt somewhere a
    /// reviewer reaches in the first thirty seconds. FirstRunView calls this on
    /// completion so a fresh install is asked immediately, and the launch task
    /// calls it for everyone who has already been through onboarding.
    @MainActor
    static func startAfterTrackingPrompt(settings: AppSettings) async {
        guard !UITestMode.isActive, settings.hasCompletedFirstRun else { return }
        if !settings.hasRequestedTracking {
            settings.hasRequestedTracking = true
            await TrackingAuthorization.requestIfNeeded()
        }
        guard !started else { return }
        started = true
        MobileAds.shared.start(completionHandler: nil)
    }
}
