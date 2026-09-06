import SwiftData
import SwiftUI

@main
struct PriceJarApp: App {
    @State private var removeAdsStore = RemoveAdsStore()
    @State private var settings = AppSettings.shared
    @State private var interstitial = InterstitialAdController()

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
        .modelContainer(for: [
            Item.self, Store.self, PriceEntry.self,
            ShoppingList.self, ShoppingListEntry.self,
            Trip.self, TripEntry.self,
        ])
    }
}
