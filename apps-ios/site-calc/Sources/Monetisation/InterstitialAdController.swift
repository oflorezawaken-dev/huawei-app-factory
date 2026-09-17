import Foundation
import GoogleMobileAds
import UIKit

/// The single interstitial placement in the whole app (F013/S010): shown only
/// after an export file has been written and its existence on disk confirmed
/// with a real FileManager check, and after the share sheet has been
/// dismissed. Gated by `AdFrequencyCapper`, never on a cold start (this
/// controller is never called at launch -- only from the export flow), and
/// never once Remove Ads is owned (the caller checks that before presenting).
@MainActor
final class InterstitialAdController: NSObject {
    private var interstitial: InterstitialAd?
    private let capper: AdFrequencyCapper

    init(capper: AdFrequencyCapper = AdFrequencyCapper()) {
        self.capper = capper
    }

    func preload() {
        Task {
            interstitial = try? await InterstitialAd.load(with: AdsConfiguration.interstitialUnitID,
                                                            request: Request())
        }
    }

    /// Presents the interstitial only if the export file genuinely exists on
    /// disk and the frequency cap allows it. Returns whether it presented.
    @discardableResult
    func presentIfFileExists(at fileURL: URL, from viewController: UIViewController?, now: Date = .now) -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return false }
        guard capper.canShow(now: now) else { return false }
        guard let interstitial, let viewController else { return false }
        capper.recordShown(at: now)
        interstitial.present(from: viewController)
        self.interstitial = nil
        preload()
        return true
    }
}
