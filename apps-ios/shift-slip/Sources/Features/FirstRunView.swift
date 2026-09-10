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
                    settings.hasCompletedFirstRun = true
                    isPresented = false
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
                    settings.hasCompletedFirstRun = true
                    isPresented = false
                }
                .accessibilityIdentifier("firstrun.startempty")
            }
            .padding()
            .navigationTitle("firstrun.title")
            .sheet(isPresented: $showingJobEditor, onDismiss: {
                settings.hasCompletedFirstRun = true
                isPresented = false
            }) {
                JobEditView(job: nil)
            }
        }
    }
}
