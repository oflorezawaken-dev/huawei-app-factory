import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var allItems: [Item]
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
                if UITestMode.shouldSeedSampleData && allItems.isEmpty {
                    SampleDataFactory.load(into: context)
                    settings.hasCompletedFirstRun = true
                }
            } else {
                showFirstRun = !settings.hasCompletedFirstRun
            }
        }
        .fullScreenCover(isPresented: $showFirstRun) {
            FirstRunView(isPresented: $showFirstRun)
        }
    }
}
