import SwiftData
import SwiftUI

/// S001, the home tab. No advertising of any kind is drawn on this screen in
/// any state -- it is in `ads_never_on` and stays that way even while a
/// result is on screen.
struct CalculatorView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CalculatorViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @State private var editingLine: TapeLine?
    @State private var showingSaveSheet = false
    @State private var jobName = ""

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Text(viewModel.runningResultText)
                        .font(.system(.largeTitle, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                        .accessibilityIdentifier("calculator.result")

                    if let error = viewModel.errorMessage {
                        Text(LocalizedStringKey(error))
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("calculator.error")
                    }

                    List {
                        ForEach(viewModel.lines) { line in
                            Button {
                                editingLine = line
                            } label: {
                                TapeLineRow(line: line, settings: settings)
                            }
                            .accessibilityIdentifier("calculator.tape.row.\(line.id)")
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: .infinity)
                    .frame(minHeight: 120)
                    .accessibilityIdentifier("calculator.tape")

                    KeypadView(viewModel: viewModel, availableWidth: geo.size.width - 16)
                }
            }
            .navigationTitle("tab.calculator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("calculator.clearTape") { viewModel.clearTape() }
                        .accessibilityIdentifier("calculator.clearTape")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("calculator.save") { showingSaveSheet = true }
                        .disabled(viewModel.lines.isEmpty)
                        .accessibilityIdentifier("calculator.save")
                }
            }
            .sheet(item: $editingLine) { line in
                TapeLineEditorView(line: line, viewModel: viewModel)
            }
            .sheet(isPresented: $showingSaveSheet) {
                SaveTapeSheet(jobName: $jobName) {
                    viewModel.saveTape(intoNewJobNamed: jobName.isEmpty ? "job.untitled".localized : jobName,
                                        context: context)
                    jobName = ""
                    showingSaveSheet = false
                }
            }
        }
    }
}

private struct TapeLineRow: View {
    let line: TapeLine
    let settings: AppSettings

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if !line.label.isEmpty {
                    Text(line.label).font(.caption).foregroundStyle(.secondary)
                }
                Text(operatorSymbol + " " + operandText)
                    .font(.system(.body, design: .monospaced))
            }
            Spacer()
            if let result = line.runningResult {
                Text(QuantityFormatting.display(result, precision: settings.fractionPrecision,
                                                 system: settings.preferredSystem,
                                                 metricUnit: settings.preferredMetricUnit))
                    .font(.system(.body, design: .monospaced).bold())
            } else if line.failed {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.red)
            }
        }
    }

    private var operatorSymbol: String {
        switch line.operatorApplied {
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "x"
        case .divide: return "/"
        case .onCentre: return "o.c."
        case nil: return ""
        }
    }

    private var operandText: String {
        QuantityFormatting.display(line.operand, precision: settings.fractionPrecision,
                                    system: settings.preferredSystem, metricUnit: settings.preferredMetricUnit)
    }
}

private struct SaveTapeSheet: View {
    @Binding var jobName: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("job.name", text: $jobName)
                    .accessibilityIdentifier("saveTape.name")
            }
            .navigationTitle("calculator.save")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("calculator.save") { onSave() }
                        .accessibilityIdentifier("saveTape.confirm")
                }
            }
        }
    }
}

extension String {
    /// Small convenience so non-View code (like a default job name) can pull
    /// a localized string the same way SwiftUI's `Text` does.
    var localized: String { NSLocalizedString(self, comment: "") }
}
