import SwiftUI

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RemoveAdsStore.self) private var adsStore

    var body: some View {
        if settings.firstRunCompleted || UITestMode.isActive {
            TabView {
                CalculatorView()
                    .tabItem { Label("tab.calculator", systemImage: "plusminus.circle") }
                    .accessibilityIdentifier("tab.calculator")
                SolversHubView()
                    .tabItem { Label("tab.solvers", systemImage: "function") }
                    .accessibilityIdentifier("tab.solvers")
                JobsListView()
                    .tabItem { Label("tab.jobs", systemImage: "folder") }
                    .accessibilityIdentifier("tab.jobs")
                SettingsView()
                    .tabItem { Label("tab.settings", systemImage: "gearshape") }
                    .accessibilityIdentifier("tab.settings")
            }
        } else {
            FirstRunView {
                settings.firstRunCompleted = true
                Task { await AppLaunchSequence.run(adsStore: adsStore) }
            }
        }
    }
}
