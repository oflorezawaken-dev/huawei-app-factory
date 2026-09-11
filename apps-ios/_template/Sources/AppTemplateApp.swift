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
                    // Prompt first, ad SDK second, and keep it that way: Apple
                    // wants the request before anything trackable is collected,
                    // and starting the SDK is collection. An app with a First Run
                    // screen should gate this on its completion and call it from
                    // there too -- what it must NOT do is move the prompt behind
                    // some later action, which is what got PriceJar 1.0.0
                    // rejected under guideline 2.1 as "unable to locate" it.
                    guard !UITestMode.isActive else { return }
                    await TrackingAuthorization.requestIfNeeded()
                    AdsBootstrap.start()
                    await store.refreshEntitlement()
                }
        }
        .modelContainer(for: Item.self)
    }
}
