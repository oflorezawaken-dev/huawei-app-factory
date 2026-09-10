import SwiftData
import SwiftUI

@main
struct ShiftSlipApp: App {
    @State private var removeAdsStore = RemoveAdsStore()
    @State private var settings = AppSettings.shared
    @State private var interstitial = InterstitialAdController()
    private let container: ModelContainer

    init() {
        let schema = Schema([Job.self, TipOutRecipientTemplate.self, Shift.self, TipOutShareRecord.self])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("ShiftSlip could not open its local store: \(error)")
        }
        // Seeding runs HERE, before the first view is built, not from a
        // view's .onAppear. Seeding after the UI exists means the app renders
        // empty and then fills in, and @Query propagates those inserts screen
        // by screen while a UI test is already tapping -- elements go stale
        // mid-flight and the screenshot test fails at a different assertion
        // each run.
        if UITestMode.shouldSeedSampleData {
            let context = ModelContext(container)
            let existing = (try? context.fetch(FetchDescriptor<Job>()))?.isEmpty ?? true
            if existing {
                SampleDataFactory.insertSampleData(into: context)
                try? context.save()
                AppSettings.shared.hasCompletedFirstRun = true
                AppSettings.shared.savedShiftCount = AdFrequencyCapper.minimumSavedShiftsBeforeFirstAd
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(removeAdsStore)
                .environment(settings)
                .environment(interstitial)
                .task {
                    guard !UITestMode.isActive else { return }
                    // The tracking prompt is deliberately NOT requested here.
                    // It fires once, right after the first shift is saved (see
                    // ShiftSummaryView), so the user has already seen what the
                    // app does before being asked. Cold start only starts the
                    // ad SDK (no ad is shown yet) and reads the entitlement.
                    AdsBootstrap.start()
                    await removeAdsStore.refreshEntitlement()
                }
        }
        .modelContainer(container)
    }
}
