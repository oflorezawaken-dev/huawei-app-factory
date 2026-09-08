import Foundation

/// Pure decision logic for whether the interstitial may show. Deliberately
/// decoupled from GoogleMobileAds and from the wall clock so it can be
/// exhaustively unit tested with a fake `now`, including the exact 240 second
/// boundary the spec calls out.
struct AdFrequencyCapper {
    static let minimumSecondsBetweenAds: TimeInterval = 240

    var lastAdShownAt: Date?
    var hasShownInterstitialThisSession: Bool

    init(lastAdShownAt: Date? = nil, hasShownInterstitialThisSession: Bool = false) {
        self.lastAdShownAt = lastAdShownAt
        self.hasShownInterstitialThisSession = hasShownInterstitialThisSession
    }

    /// The interstitial may show only once per session and never within
    /// `minimumSecondsBetweenAds` of any other ad impression (banner or
    /// interstitial). Cold start is handled by the call site: nothing calls
    /// this before a trip has been saved, so a fresh session with no prior ad
    /// naturally cannot fire on cold start.
    func canShowInterstitial(now: Date) -> Bool {
        guard !hasShownInterstitialThisSession else { return false }
        guard let lastAdShownAt else { return true }
        return now.timeIntervalSince(lastAdShownAt) >= Self.minimumSecondsBetweenAds
    }

    mutating func recordAdShown(at date: Date, isInterstitial: Bool) {
        lastAdShownAt = date
        if isInterstitial { hasShownInterstitialThisSession = true }
    }
}

/// Session-scoped (in-memory, never persisted) record of the last ad shown of
/// any kind, shared between the banner and the interstitial so the capper can
/// see both. Being in-memory is what makes "once per session" and "never on
/// cold start" true for free: a fresh launch is a fresh session.
@Observable
@MainActor
final class AdActivityLog {
    static let shared = AdActivityLog()

    private var capper = AdFrequencyCapper()

    private init() {}

    func recordBannerShown(at date: Date = .now) {
        capper.recordAdShown(at: date, isInterstitial: false)
    }

    func recordInterstitialShown(at date: Date = .now) {
        capper.recordAdShown(at: date, isInterstitial: true)
    }

    func canShowInterstitial(now: Date = .now) -> Bool {
        capper.canShowInterstitial(now: now)
    }

    /// Test-only hook so screenshot/UI tests never depend on real timing.
    func resetForTesting() {
        capper = AdFrequencyCapper()
    }
}
