import SwiftUI

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RemoveAdsStore.self) private var adsStore
    @State private var finishedFirstRunThisLaunch = false

    /// Normally: the app once First Run is behind us, and a plain UI-test run
    /// skips First Run entirely so a walk starts inside the app.
    ///
    /// With `-FactoryUITestFirstRun` the screenshot walk wants First Run every
    /// launch, whatever is stored -- that is where the sample job is offered,
    /// and a Jobs list with the sample in it is what a new user and an App
    /// Store reviewer see. Keying that off this launch's own state rather than
    /// the stored flag makes it deterministic: the walk does not depend on
    /// whether a previous run on the same simulator left First Run completed,
    /// which is exactly what made it pass here and fail on CI.
    private var showsTheApp: Bool {
        if UITestMode.startsAtFirstRun { return finishedFirstRunThisLaunch }
        return settings.firstRunCompleted || UITestMode.isActive
    }

    var body: some View {
        if showsTheApp {
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
                finishedFirstRunThisLaunch = true
                Task { await AppLaunchSequence.run(adsStore: adsStore) }
            }
        }
    }
}
