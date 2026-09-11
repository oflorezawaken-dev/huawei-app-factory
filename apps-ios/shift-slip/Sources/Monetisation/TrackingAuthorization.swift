import AppTrackingTransparency
import AdSupport

enum TrackingAuthorization {
    /// Shows Apple's tracking prompt exactly once, on the first launch after
    /// First Run. Call it through AdsBootstrap.startAfterTrackingPrompt, which
    /// owns the order: the prompt must come before the ad SDK starts. Ads keep
    /// working when the answer is no; they are simply non-personalised.
    @MainActor
    static func requestIfNeeded(settings: AppSettings) async {
        // A UI test must never reach the system prompt. Nothing dismisses it,
        // so the await never returns and whatever the caller does after this
        // line never happens -- in PriceJar that was dismissing a sheet,
        // which stayed open and made the screenshot test fail 20s later at an
        // unrelated assertion, intermittently.
        guard !UITestMode.isActive else { return }
        guard settings.hasCompletedFirstRun, !settings.hasRequestedTracking else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            settings.hasRequestedTracking = true
            return
        }
        _ = await ATTrackingManager.requestTrackingAuthorization()
        settings.hasRequestedTracking = true
    }

    @MainActor
    static var isAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
