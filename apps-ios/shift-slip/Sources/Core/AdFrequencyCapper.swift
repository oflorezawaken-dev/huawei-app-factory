import Foundation

/// Pure decision logic for whether the interstitial may show (F013).
/// Deliberately decoupled from GoogleMobileAds and from the wall clock so it
/// is exhaustively unit-testable with a fake `now`, including the exact
/// 240-second boundary and the third-saved-shift boundary the spec names.
struct AdFrequencyCapper {
    static let minimumSecondsBetweenAds: TimeInterval = 240
    static let minimumSavedShiftsBeforeFirstAd = 3

    var lastAdShownAt: Date?
    var hasShownInterstitialThisSession: Bool

    init(lastAdShownAt: Date? = nil, hasShownInterstitialThisSession: Bool = false) {
        self.lastAdShownAt = lastAdShownAt
        self.hasShownInterstitialThisSession = hasShownInterstitialThisSession
    }

    /// The interstitial may show only once per session, never within
    /// `minimumSecondsBetweenAds` of any other ad impression (banner or
    /// interstitial), and never before `savedShiftCount` reaches 3. Cold
    /// start needs no separate flag: nothing calls this before a shift has
    /// been saved, and a fresh session starts with no prior ad, so a cold
    /// start naturally cannot fire.
    func canShowInterstitial(now: Date, savedShiftCount: Int) -> Bool {
        guard !hasShownInterstitialThisSession else { return false }
        guard savedShiftCount >= Self.minimumSavedShiftsBeforeFirstAd else { return false }
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

    func canShowInterstitial(now: Date = .now, savedShiftCount: Int) -> Bool {
        capper.canShowInterstitial(now: now, savedShiftCount: savedShiftCount)
    }

    /// Test-only hook so screenshot/UI tests never depend on real timing.
    func resetForTesting() {
        capper = AdFrequencyCapper()
    }
}
