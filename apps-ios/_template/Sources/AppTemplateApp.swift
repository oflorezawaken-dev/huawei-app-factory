import SwiftData
import SwiftUI

@main
struct AppTemplateApp: App {
    @State private var store = RemoveAdsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    // Asked after the first screen is on-screen, never at launch:
                    // Apple rejects a tracking prompt shown before any context.
                    guard !UITestMode.isActive else { return }
                    await TrackingAuthorization.requestIfNeeded()
                    AdsBootstrap.start()
                    await store.refreshEntitlement()
                }
        }
        .modelContainer(for: Item.self)
    }
}
