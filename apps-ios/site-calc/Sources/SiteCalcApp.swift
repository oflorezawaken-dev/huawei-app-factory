import SwiftData
import SwiftUI

@main
struct SiteCalcApp: App {
    @State private var adsStore = RemoveAdsStore()
    @State private var settings: AppSettings
    @State private var calculator: CalculatorViewModel

    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _calculator = State(initialValue: CalculatorViewModel(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(adsStore)
                .environment(settings)
                .environment(calculator)
                .task {
                    guard !UITestMode.isActive else { return }
                    // Requested once, after First Run completes -- not at every
                    // cold start. On a fresh install this does nothing here;
                    // FirstRunView calls AppLaunchSequence.run itself when the
                    // user finishes onboarding. On every later launch, first run
                    // is already behind us, so this is where it happens.
                    if settings.firstRunCompleted {
                        await AppLaunchSequence.run(adsStore: adsStore)
                    }
                }
        }
        .modelContainer(for: SiteJob.self)
    }
}

/// The ATT prompt, then the ad SDK, then a refreshed entitlement -- in that
/// order, exactly once. Both SiteCalcApp (subsequent launches) and
/// FirstRunView (the first launch, once onboarding completes) call this same
/// function so there is exactly one place this sequence is written.
enum AppLaunchSequence {
    @MainActor
    static func run(adsStore: RemoveAdsStore) async {
        await TrackingAuthorization.requestIfNeeded()
        AdsBootstrap.start()
        await adsStore.refreshEntitlement()
    }
}
