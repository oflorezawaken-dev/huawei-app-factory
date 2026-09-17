import SwiftUI

/// One key: a label, an accessibility identifier, and its action. Plain data
/// so `KeypadRow` can lay out any group of keys the same way.
struct KeypadKey: Identifiable {
    let id: String
    let label: String
    /// A String Catalog key spoken by VoiceOver, since the visual label is
    /// often a symbol ("÷", "O.C.") that reads poorly on its own (F015).
    let accessibilityLabelKey: String
    let action: () -> Void

    init(_ label: String, identifier: String, accessibilityLabelKey: String? = nil, action: @escaping () -> Void) {
        self.id = identifier
        self.label = label
        self.accessibilityLabelKey = accessibilityLabelKey ?? identifier
        self.action = action
    }
}

/// Lays out one group of keys using `KeypadLayout.arrange`: it measures the
/// width it is offered before drawing anything, then wraps to more rows
/// rather than ever shrinking a key below 44x44pt (factory rule 8 / F010).
struct KeypadRow: View {
    let keys: [KeypadKey]
    let preferredColumns: Int
    let availableWidth: CGFloat

    var body: some View {
        let metrics = KeypadLayout.arrange(keyCount: keys.count, preferredColumns: preferredColumns,
                                            availableWidth: availableWidth)
        let rows = stride(from: 0, to: keys.count, by: metrics.columns).map { start in
            Array(keys[start..<min(start + metrics.columns, keys.count)])
        }
        VStack(spacing: metrics.spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, rowKeys in
                HStack(spacing: metrics.spacing) {
                    ForEach(rowKeys) { key in
                        Button(action: key.action) {
                            Text(key.label)
                                .font(.system(.body, design: .monospaced))
                                .frame(width: metrics.keySize, height: metrics.keySize)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier(key.id)
                        .accessibilityLabel(LocalizedStringKey(key.accessibilityLabelKey))
                    }
                }
            }
        }
    }
}

/// The whole keypad (S001 component list): a unit row, a utility row, the
/// digit-and-operator grid, and an equals bar. Every row measures the same
/// `availableWidth`, supplied by the caller's GeometryReader -- never assumed.
struct KeypadView: View {
    let viewModel: CalculatorViewModel
    let availableWidth: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            KeypadRow(keys: unitKeys, preferredColumns: 6, availableWidth: availableWidth)
            KeypadRow(keys: utilityKeys, preferredColumns: 6, availableWidth: availableWidth)
            KeypadRow(keys: digitKeys, preferredColumns: 4, availableWidth: availableWidth)
            Button(action: viewModel.equals) {
                Text("keypad.equals")
                    .frame(maxWidth: .infinity, minHeight: KeypadLayout.minKeySize)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("keypad.equals")
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private var unitKeys: [KeypadKey] {
        [
            KeypadKey("FT", identifier: "keypad.unit.feet") { viewModel.unit(.feet) },
            KeypadKey("IN", identifier: "keypad.unit.inches") { viewModel.unit(.inches) },
            KeypadKey("YD", identifier: "keypad.unit.yard") { viewModel.unit(.yard) },
            KeypadKey("M", identifier: "keypad.unit.meter") { viewModel.unit(.meter) },
            KeypadKey("CM", identifier: "keypad.unit.centimeter") { viewModel.unit(.centimeter) },
            KeypadKey("MM", identifier: "keypad.unit.millimeter") { viewModel.unit(.millimeter) },
        ]
    }

    private var utilityKeys: [KeypadKey] {
        [
            KeypadKey("C", identifier: "keypad.clear") { viewModel.clearEntry() },
            KeypadKey("⌫", identifier: "keypad.backspace") { viewModel.backspace() },
            KeypadKey("%", identifier: "keypad.percent") { viewModel.percent() },
            KeypadKey("O.C.", identifier: "keypad.onCentre") { viewModel.onCentreKey() },
            KeypadKey("+", identifier: "keypad.add") { viewModel.applyOperator(.add) },
            KeypadKey("−", identifier: "keypad.subtract") { viewModel.applyOperator(.subtract) },
        ]
    }

    private var digitKeys: [KeypadKey] {
        (0...9).map { d in
            KeypadKey("\(d)", identifier: "keypad.digit.\(d)") { viewModel.digit(d) }
        } + [
            KeypadKey(".", identifier: "keypad.decimal") { viewModel.decimalPoint() },
            KeypadKey("/", identifier: "keypad.fraction") { viewModel.fractionSlash() },
            KeypadKey("×", identifier: "keypad.multiply") { viewModel.applyOperator(.multiply) },
            KeypadKey("÷", identifier: "keypad.divide") { viewModel.applyOperator(.divide) },
        ]
    }
}
