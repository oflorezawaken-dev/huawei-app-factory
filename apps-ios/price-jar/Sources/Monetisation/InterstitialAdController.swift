import GoogleMobileAds
import UIKit

/// A real AdMob interstitial. Loaded eagerly after a trip is saved so it is
/// ready by the time the trip summary decides whether to present it; there is
/// no simulated fallback, matching BannerAdView's stance that a fake ad
/// object would pass every check and ship an app that earns nothing.
@Observable
@MainActor
final class InterstitialAdController: NSObject {
    private var interstitial: InterstitialAd?
    private var isLoading = false

    /// Loads a fresh interstitial. Safe to call speculatively; a load that is
    /// never presented is simply discarded.
    func load() async {
        guard !isLoading, interstitial == nil else { return }
        isLoading = true
        defer { isLoading = false }
        interstitial = try? await InterstitialAd.load(
            with: AdsConfiguration.interstitialUnitID, request: Request())
        interstitial?.fullScreenContentDelegate = self
    }

    /// Presents the interstitial if one is loaded and the frequency cap
    /// allows it. Returns whether an ad was actually presented, so the caller
    /// (Trip Summary) can decide not to wait for it.
    @discardableResult
    func presentIfAllowed(from viewController: UIViewController?, activityLog: AdActivityLog) async -> Bool {
        guard activityLog.canShowInterstitial(now: .now) else { return false }
        if interstitial == nil { await load() }
        guard let interstitial, let viewController else { return false }
        activityLog.recordInterstitialShown()
        interstitial.present(from: viewController)
        return true
    }
}

extension InterstitialAdController: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.interstitial = nil
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.interstitial = nil
        }
    }
}
