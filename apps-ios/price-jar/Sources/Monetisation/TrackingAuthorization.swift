import AppTrackingTransparency
import AdSupport

enum TrackingAuthorization {
    /// Shows Apple's tracking prompt once. Ads keep working when the answer is
    /// no; they are simply non-personalised and pay less.
    @MainActor
    static func requestIfNeeded() async {
        // A UI test must never reach the system prompt. Nothing dismisses it, so
        // the await never returns, the continuation after it never runs, and the
        // caller is left half-finished -- which is how saving a price left the
        // Record Price sheet open on screen and made the screenshot test fail at
        // an unrelated assertion 20s later. UITestMode's own documentation said
        // the prompt was skipped in test mode; this is the call site that has to
        // honour it.
        guard !UITestMode.isActive else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    @MainActor
    static var isAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
