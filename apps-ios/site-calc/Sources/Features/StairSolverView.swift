import SwiftData
import SwiftUI

/// S005: total rise in, full layout out, using only the limits the user
/// typed in. `settings.maxRiserHeight` and `settings.minTreadDepth` start nil
/// on a fresh install and stay nil until the user fills them in here (or in
/// Settings) -- this screen never supplies a default for either, and Solve
/// is disabled until both are present (qa acceptance: "ships no limit of its
/// own").
struct StairSolverView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CalculatorViewModel.self) private var calculator
    @Environment(\.modelContext) private var context

    @State private var totalRiseText = ""
    @State private var maxRiserText = ""
    @State private var minTreadText = ""
    @State private var showingSaveSheet = false

    private var maxRiserHeight: Length? { InputParsing.length(maxRiserText, settings: settings, defaultUnit: .inches) }
    private var minTreadDepth: Length? { InputParsing.length(minTreadText, settings: settings, defaultUnit: .inches) }
    private var totalRise: Length? { InputParsing.length(totalRiseText, settings: settings, defaultUnit: .inches) }

    private var canSolve: Bool { totalRise != nil && maxRiserHeight != nil && minTreadDepth != nil }

    private var result: StairSolver.Result? {
        guard let totalRise, let maxRiserHeight, let minTreadDepth else { return nil }
        return try? StairSolver.solve(totalRise: totalRise, maxRiserHeight: maxRiserHeight,
                                       minTreadDepth: minTreadDepth)
    }

    private var shortfall: Length? {
        guard let result, let totalRise else { return nil }
        return StairSolver.shortfall(totalRise: totalRise, riserCount: result.riserCount,
                                      riserHeight: result.riserHeight, precision: settings.fractionPrecision)
    }

    var body: some View {
        Form {
            Section("stair.inputs") {
                TextField(fieldLabel("stair.totalRise", .inches), text: $totalRiseText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("stair.totalRise")
                TextField(fieldLabel("stair.maxRiser", .inches), text: $maxRiserText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("stair.maxRiser")
                    .onChange(of: maxRiserText) { _, _ in settings.maxRiserHeight = maxRiserHeight }
                TextField(fieldLabel("stair.minTread", .inches), text: $minTreadText).keyboardType(.decimalPad)
                    .accessibilityIdentifier("stair.minTread")
                    .onChange(of: minTreadText) { _, _ in settings.minTreadDepth = minTreadDepth }
                Text("stair.statement.yourLimits").font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("stair.statement.yourLimits")
                Button("stair.solve") { }
                    .disabled(!canSolve)
                    .accessibilityIdentifier("stair.solve")
            }

            if let result {
                Section("stair.result") {
                    LabeledContent("stair.riserCount", value: "\(result.riserCount)")
                        .accessibilityIdentifier("stair.result.riserCount")
                    resultRow("stair.riserHeight", .length(result.riserHeight))
                        .accessibilityIdentifier("stair.result.riserHeight")
                    LabeledContent("stair.treadCount", value: "\(result.treadCount)")
                        .accessibilityIdentifier("stair.result.treadCount")
                    resultRow("stair.totalRun", .length(result.totalRun))
                    resultRow("stair.stringerLength", .length(result.stringerLength))
                    if let shortfall {
                        Text(localized("stair.shortfallStatement", displayText(.length(shortfall))))
                            .font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("stair.result.shortfall")
                    }
                    Text(localized("solver.fromWhatYouEntered",
                                    "\(totalRiseText), \(maxRiserText), \(minTreadText)"))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("solver.sendToTape") {
                        calculator.appendExternal(.length(result.stringerLength), label: "stair.stringerLength".localized)
                    }
                    .accessibilityIdentifier("stair.sendToTape")
                    Button("solver.saveToJob") { showingSaveSheet = true }
                        .accessibilityIdentifier("stair.saveToJob")
                }
            }
        }
        .keyboardDoneToolbar()
        .navigationTitle("solvers.stair")
        .onAppear {
            if maxRiserText.isEmpty, let existing = settings.maxRiserHeight {
                maxRiserText = LengthFormatting.decimal(existing, unit: .inches, decimalPlaces: 3)
            }
            if minTreadText.isEmpty, let existing = settings.minTreadDepth {
                minTreadText = LengthFormatting.decimal(existing, unit: .inches, decimalPlaces: 3)
            }
        }
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
        LabeledContent(LocalizedStringKey(titleKey), value: displayText(quantity))
    }

    private func displayText(_ quantity: Quantity) -> String {
        QuantityFormatting.display(quantity, precision: settings.fractionPrecision, system: settings.preferredSystem,
                                    metricUnit: settings.preferredMetricUnit)
    }

    private func savedResult(_ result: StairSolver.Result) -> SavedSolverResult {
        SavedSolverResult(kind: .stair, title: "solvers.stair".localized,
                           inputsSummary: localized("solver.fromWhatYouEntered",
                                                     "\(totalRiseText), \(maxRiserText), \(minTreadText)"),
                           values: [
                               LabeledQuantity(label: "stair.riserCount".localized, quantity: .count(Rational(result.riserCount))),
                               LabeledQuantity(label: "stair.riserHeight".localized, quantity: .length(result.riserHeight)),
                               LabeledQuantity(label: "stair.totalRun".localized, quantity: .length(result.totalRun)),
                               LabeledQuantity(label: "stair.stringerLength".localized, quantity: .length(result.stringerLength)),
                           ])
    }
}
