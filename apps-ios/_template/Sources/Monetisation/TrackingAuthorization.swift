import AppTrackingTransparency
import AdSupport

enum TrackingAuthorization {
    /// Shows Apple's tracking prompt once. Ads keep working when the answer is
    /// no; they are simply non-personalised and pay less.
    @MainActor
    static func requestIfNeeded() async {
        // A UI test must never reach the system prompt. Nothing dismisses it, so
        // the await never returns and whatever the caller does after this line
        // never happens -- in PriceJar that was dismissing a sheet, which stayed
        // open and made the screenshot test fail at an unrelated assertion.
        guard !UITestMode.isActive else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    @MainActor
    static var isAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
