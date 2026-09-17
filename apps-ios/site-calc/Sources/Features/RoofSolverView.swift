import SwiftData
import SwiftUI

/// S004: any two of rise, run, diagonal, or a pitch plus one length, in;
/// everything else, out. No advertising of any kind, and no limit or
/// allowance of its own -- the geometry is all it answers.
struct RoofSolverView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CalculatorViewModel.self) private var calculator
    @Environment(\.modelContext) private var context

    @State private var riseText = ""
    @State private var runText = ""
    @State private var diagonalText = ""
    @State private var pitchText = ""
    @State private var showingSaveSheet = false

    private var result: RoofSolver.Result? {
        let rise = InputParsing.length(riseText, settings: settings)
        let run = InputParsing.length(runText, settings: settings)
        let diagonal = InputParsing.length(diagonalText, settings: settings)
        let pitch = InputParsing.rational(pitchText)
        return try? RoofSolver.solve(rise: rise, run: run, diagonal: diagonal, pitchPer12: pitch)
    }

    var body: some View {
        Form {
            Section("roof.inputs") {
                TextField("roof.rise", text: $riseText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("roof.rise")
                TextField("roof.run", text: $runText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("roof.run")
                TextField("roof.diagonal", text: $diagonalText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("roof.diagonal")
                TextField("roof.pitchPer12", text: $pitchText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("roof.pitch")
                Text("roof.statement.noLimit").font(.footnote).foregroundStyle(.secondary)
            }

            if let result {
                Section("roof.result") {
                    resultRow("roof.rise", .length(result.rise))
                    resultRow("roof.run", .length(result.run))
                    resultRow("roof.commonRafter", .length(result.commonRafter))
                    resultRow("roof.hipValley", .length(result.hipOrValley))
                    LabeledContent("roof.pitchPer12", value: String(format: "%.2f", result.pitchPer12))
                        .accessibilityIdentifier("roof.result.pitchPer12")
                    LabeledContent("roof.pitchDegrees", value: String(format: "%.2f\u{00B0}", result.pitchDegrees))
                        .accessibilityIdentifier("roof.result.pitchDegrees")
                    Text(localized("solver.fromWhatYouEntered", inputsSummary))
                        .font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("roof.result.summary")
                }
                Section {
                    Button("solver.sendToTape") { sendToTape(result) }
                        .accessibilityIdentifier("roof.sendToTape")
                    Button("solver.saveToJob") { showingSaveSheet = true }
                        .accessibilityIdentifier("roof.saveToJob")
                }
            }
        }
        .navigationTitle("solvers.roof")
        .sheet(isPresented: $showingSaveSheet) {
            if let result {
                SaveResultSheet(onSaveNew: { name in
                    let job = SiteJob(name: name, solverResults: [savedResult(result)])
                    context.insert(job)
                }, onSaveExisting: { job in
                    job.solverResults.append(savedResult(result))
                })
            }
        }
    }

    private func resultRow(_ titleKey: String, _ quantity: Quantity) -> some View {
        LabeledContent(LocalizedStringKey(titleKey),
                       value: QuantityFormatting.display(quantity, precision: settings.fractionPrecision,
                                                          system: settings.preferredSystem,
                                                          metricUnit: settings.preferredMetricUnit))
    }

    private var inputsSummary: String {
        [riseText, runText, diagonalText, pitchText].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func sendToTape(_ result: RoofSolver.Result) {
        calculator.appendExternal(.length(result.commonRafter), label: "roof.commonRafter".localized)
    }

    private func savedResult(_ result: RoofSolver.Result) -> SavedSolverResult {
        SavedSolverResult(kind: .roof, title: "solvers.roof".localized,
                           inputsSummary: localized("solver.fromWhatYouEntered", inputsSummary),
                           values: [
                               LabeledQuantity(label: "roof.rise".localized, quantity: .length(result.rise)),
                               LabeledQuantity(label: "roof.run".localized, quantity: .length(result.run)),
                               LabeledQuantity(label: "roof.commonRafter".localized,
                                               quantity: .length(result.commonRafter)),
                               LabeledQuantity(label: "roof.hipValley".localized,
                                               quantity: .length(result.hipOrValley)),
                           ])
    }
}
