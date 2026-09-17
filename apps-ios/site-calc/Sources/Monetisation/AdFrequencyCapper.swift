import Foundation

/// The interstitial's gating rules (F013/S010), as pure logic so it can be
/// tested with a fake clock instead of real AdMob calls and real sleeps: at
/// most once per app session, never within 240 seconds of another ad, and
/// never on a cold start (there is no "another ad" yet, but a cold start is
/// also never the export moment, so that case never reaches this type).
final class AdFrequencyCapper {
    private var shownThisSession = false
    private var lastShownAt: Date?
    private let minimumInterval: TimeInterval

    init(minimumInterval: TimeInterval = 240) {
        self.minimumInterval = minimumInterval
    }

    func canShow(now: Date) -> Bool {
        guard !shownThisSession else { return false }
        if let lastShownAt, now.timeIntervalSince(lastShownAt) < minimumInterval { return false }
        return true
    }

    func recordShown(at date: Date) {
        shownThisSession = true
        lastShownAt = date
    }
}
