import SwiftUI

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @State private var showingFirstRun = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("tab.dashboard", systemImage: "gauge.medium") }
                .accessibilityIdentifier("tab.dashboard")
            ShiftHistoryView()
                .tabItem { Label("tab.history", systemImage: "clock.arrow.circlepath") }
                .accessibilityIdentifier("tab.history")
            ReportsView()
                .tabItem { Label("tab.reports", systemImage: "chart.bar") }
                .accessibilityIdentifier("tab.reports")
            JobsView()
                .tabItem { Label("tab.jobs", systemImage: "briefcase") }
                .accessibilityIdentifier("tab.jobs")
        }
        .fullScreenCover(isPresented: $showingFirstRun) {
            FirstRunView(isPresented: $showingFirstRun)
        }
        .onAppear {
            if !settings.hasCompletedFirstRun && !UITestMode.isActive {
                showingFirstRun = true
            }
        }
    }
}

/// Shared bottom banner block used by each of the four tab-root screens
/// (F013's banner_screens). Deliberately not hoisted above the TabView: a
/// view placed there would still be on screen while a child screen like Log
/// Shift is pushed, and F013 requires no ad there at all.
struct TabRootBanner: View {
    @Environment(RemoveAdsStore.self) private var store

    var body: some View {
        if !store.adsRemoved && !UITestMode.isActive {
            BannerAdView()
                .frame(height: 50)
                .accessibilityIdentifier("ad.banner")
        }
    }
}
