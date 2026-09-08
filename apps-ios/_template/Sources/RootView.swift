import SwiftUI

struct RootView: View {
    @Environment(RemoveAdsStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                TodayView()
                    .tabItem { Label("tab.today", systemImage: "sun.max") }
                    .accessibilityIdentifier("tab.today")
                ItemListView()
                    .tabItem { Label("tab.all", systemImage: "list.bullet") }
                    .accessibilityIdentifier("tab.all")
                SettingsView()
                    .tabItem { Label("tab.settings", systemImage: "gearshape") }
                    .accessibilityIdentifier("tab.settings")
            }
            if !store.adsRemoved && !UITestMode.isActive {
                BannerAdView()
                    .frame(height: 50)
                    .accessibilityIdentifier("ad.banner")
            }
        }
    }
}
