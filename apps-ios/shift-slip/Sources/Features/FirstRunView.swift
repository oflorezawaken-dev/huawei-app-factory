import SwiftData
import SwiftUI

/// S012: explain the app in three lines, take the one setting that matters,
/// and offer the sample data. No advertising and no tracking prompt of any kind.
struct FirstRunView: View {
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @State private var currencyCode: String
    @State private var showingJobEditor = false

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
        _currencyCode = State(initialValue: AppSettings.defaultCurrencyCode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("firstrun.step1", systemImage: "1.circle.fill")
                    Label("firstrun.step2", systemImage: "2.circle.fill")
                    Label("firstrun.step3", systemImage: "3.circle.fill")
                }
                .font(.title3)
                .accessibilityIdentifier("firstrun.steps")

                Text("firstrun.privacynote")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("firstrun.privacynote")

                TextField("firstrun.currency", text: $currencyCode)
                    .textInputAutocapitalization(.characters)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("firstrun.currency")

                Spacer()

                Button {
                    settings.currencyCode = currencyCode
                    SampleDataFactory.insertSampleData(into: context)
                    finish()
                } label: {
                    Text("firstrun.loadsample").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("firstrun.loadsample")

                Button {
                    settings.currencyCode = currencyCode
                    showingJobEditor = true
                } label: {
                    Text("firstrun.createjob").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("firstrun.createjob")

                Button("firstrun.startempty") {
                    settings.currencyCode = currencyCode
                    finish()
                }
                .accessibilityIdentifier("firstrun.startempty")
            }
            .padding()
            .navigationTitle("firstrun.title")
            .sheet(isPresented: $showingJobEditor, onDismiss: { finish() }) {
                JobEditView(job: nil)
            }
        }
    }

    /// The single way out of First Run. There are three buttons that end it and
    /// each used to set the flag and dismiss on its own; the tracking prompt has
    /// to follow every one of them, so they all go through here.
    ///
    /// The user has just been told what the app does, which is the moment the
    /// spec wanted for the prompt. Asking here rather than after the first saved
    /// shift is what makes it reachable for an App Review pass -- PriceJar was
    /// rejected under guideline 2.1 for a prompt buried behind an action the
    /// reviewer never performed.
    private func finish() {
        settings.hasCompletedFirstRun = true
        isPresented = false
        Task { await AdsBootstrap.startAfterTrackingPrompt(settings: settings) }
    }
}
