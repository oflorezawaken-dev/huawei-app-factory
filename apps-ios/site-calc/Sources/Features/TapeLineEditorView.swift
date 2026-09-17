import SwiftUI

/// S002: label or correct one tape entry after the fact without losing the
/// rest of the tape. A correction recomputes every line below it -- that is
/// `TapeEngine.recompute`, called by the view model on save.
struct TapeLineEditorView: View {
    let line: TapeLine
    let viewModel: CalculatorViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var label: String
    @State private var operatorChoice: TapeOperator
    @State private var entry: EntryBuilder

    init(line: TapeLine, viewModel: CalculatorViewModel) {
        self.line = line
        self.viewModel = viewModel
        _label = State(initialValue: line.label)
        _operatorChoice = State(initialValue: line.operatorApplied ?? .add)
        _entry = State(initialValue: EntryBuilder())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("editLine.value") {
                    Text(QuantityFormatting.display(line.operand, precision: .sixteenth,
                                                     system: .imperial, metricUnit: .centimeter))
                        .accessibilityIdentifier("editLine.currentValue")
                }
                if line.operatorApplied != nil {
                    Section("editLine.operator") {
                        Picker("editLine.operator", selection: $operatorChoice) {
                            Text("op.add").tag(TapeOperator.add)
                            Text("op.subtract").tag(TapeOperator.subtract)
                            Text("op.multiply").tag(TapeOperator.multiply)
                            Text("op.divide").tag(TapeOperator.divide)
                            Text("op.onCentre").tag(TapeOperator.onCentre)
                        }
                        .accessibilityIdentifier("editLine.operatorPicker")
                    }
                }
                Section("editLine.label") {
                    TextField("editLine.label", text: $label)
                        .accessibilityIdentifier("editLine.labelField")
                }
                Section {
                    Button("editLine.delete", role: .destructive) {
                        viewModel.deleteLine(line.id)
                        dismiss()
                    }
                    .accessibilityIdentifier("editLine.delete")
                }
            }
            .navigationTitle("editLine.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                        .accessibilityIdentifier("editLine.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("edit.save") {
                        viewModel.label(label, forLineID: line.id)
                        if line.operatorApplied != nil {
                            viewModel.correct(lineID: line.id, newOperator: operatorChoice, newOperand: line.operand)
                        }
                        dismiss()
                    }
                    .accessibilityIdentifier("editLine.save")
                }
            }
        }
    }
}
