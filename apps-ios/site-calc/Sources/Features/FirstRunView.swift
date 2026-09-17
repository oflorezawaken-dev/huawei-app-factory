import SwiftData
import SwiftUI

/// S013: say what the app is in three lines, take the two settings that
/// matter, and offer the sample job. No advertising, and no tracking prompt
/// on this screen -- `onDone` is what triggers the ATT request, after this
/// screen has finished.
struct FirstRunView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    let onDone: () -> Void

    @State private var precision: FractionPrecision = .sixteenth
    @State private var system: MeasurementSystem = .imperial

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("firstRun.line1").font(.title3)
                Text("firstRun.line2").font(.title3)
                Text("firstRun.line3").font(.title3)
                Text("firstRun.honestNote").font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("firstRun.honestNote")

                Picker("settings.system", selection: $system) {
                    Text("settings.system.imperial").tag(MeasurementSystem.imperial)
                    Text("settings.system.metric").tag(MeasurementSystem.metric)
                }
                .accessibilityIdentifier("firstRun.system")

                Picker("settings.precision", selection: $precision) {
                    ForEach(FractionPrecision.allCases, id: \.self) { p in
                        Text(verbatim: "1/\(p.denominator)").tag(p)
                    }
                }
                .accessibilityIdentifier("firstRun.precision")

                Spacer()

                Button("firstRun.loadSample") {
                    apply()
                    context.insert(SampleJobFactory.makeSampleJob())
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("firstRun.loadSample")

                Button("firstRun.startEmpty") {
                    apply()
                    onDone()
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("firstRun.startEmpty")
            }
            .padding()
            .navigationTitle("firstRun.title")
        }
    }

    private func apply() {
        settings.preferredSystem = system
        settings.fractionPrecision = precision
    }
}
