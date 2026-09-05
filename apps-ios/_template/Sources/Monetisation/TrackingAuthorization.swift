import AppTrackingTransparency
import AdSupport

enum TrackingAuthorization {
    /// Shows Apple's tracking prompt once. Ads keep working when the answer is
    /// no; they are simply non-personalised and pay less.
    @MainActor
    static func requestIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    @MainActor
    static var isAuthorized: Bool {
        ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
}
