import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var showFirstRun = false

    var body: some View {
        TabView {
            PriceBookView()
                .tabItem { Label("tab.priceBook", systemImage: "book.closed") }
                .accessibilityIdentifier("tab.priceBook")
            ShoppingListView()
                .tabItem { Label("tab.shoppingList", systemImage: "cart") }
                .accessibilityIdentifier("tab.shoppingList")
            StatsView()
                .tabItem { Label("tab.stats", systemImage: "chart.bar") }
                .accessibilityIdentifier("tab.stats")
            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
                .accessibilityIdentifier("tab.settings")
        }
        .onAppear {
            if UITestMode.isActive {
                showFirstRun = false
                // Sample data is seeded in PriceJarApp.init(), before any view
                // exists, so the app is never observed in an unseeded state.
            } else {
                showFirstRun = !settings.hasCompletedFirstRun
            }
        }
        .fullScreenCover(isPresented: $showFirstRun) {
            FirstRunView(isPresented: $showFirstRun)
        }
    }
}
