import SwiftData
import SwiftUI

@main
struct PriceJarApp: App {
    @State private var removeAdsStore = RemoveAdsStore()
    @State private var settings = AppSettings.shared
    @State private var interstitial = InterstitialAdController()
    private let container: ModelContainer

    init() {
        let schema = Schema([
            Item.self, Store.self, PriceEntry.self,
            ShoppingList.self, ShoppingListEntry.self,
            Trip.self, TripEntry.self,
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("PriceJar could not open its local store: \(error)")
        }
        // Seeding runs HERE, before the first view is built, not from a view's
        // .onAppear. Seeding after the UI exists means the app renders empty and
        // then fills in, and @Query propagates those inserts screen by screen
        // while a UI test is already tapping -- elements go stale mid-flight and
        // the screenshot test fails at a different assertion each run.
        if UITestMode.shouldSeedSampleData {
            let context = ModelContext(container)
            let existing = (try? context.fetch(FetchDescriptor<Item>()))?.isEmpty ?? true
            if existing {
                SampleDataFactory.load(into: context)
                try? context.save()
                AppSettings.shared.hasCompletedFirstRun = true
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
                    // It fires once, right after the first price entry is
                    // saved (see RecordPriceView / VerdictView), so the user
                    // has already seen what the app does before being asked.
                    // Cold start only starts the ad SDK (no ad is shown yet)
                    // and reads the purchase entitlement.
                    AdsBootstrap.start()
                    await removeAdsStore.refreshEntitlement()
                }
        }
        .modelContainer(container)
    }
}
