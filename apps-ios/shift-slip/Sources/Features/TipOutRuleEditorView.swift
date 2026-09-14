import SwiftUI

/// Edits a list of tip-out recipient rules (name, rule type, value) with no
/// resolved amounts -- used for a Job's default rule, which has no specific
/// shift's tips or sales to resolve against yet.
struct TipOutRuleEditorView: View {
    @Binding var recipients: [TipOutRecipientRule]

    var body: some View {
        Form {
            ForEach($recipients) { $recipient in
                RecipientRuleRow(recipient: $recipient)
            }
            .onDelete { offsets in recipients.remove(atOffsets: offsets) }

            Button {
                recipients.append(TipOutRecipientRule(name: "", type: .percentOfTips, value: 0))
            } label: {
                Label("tipoutrule.add", systemImage: "plus")
            }
            .accessibilityIdentifier("tipoutrule.add")
        }
        .navigationTitle("tipoutrule.title")
        .toolbar { EditButton() }
    }
}

struct RecipientRuleRow: View {
    @Binding var recipient: TipOutRecipientRule
    @State private var valueText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("tipoutrule.recipient.name", text: $recipient.name)
                .accessibilityIdentifier("tipoutrule.name.\(recipient.id)")
            Picker("tipoutrule.recipient.type", selection: $recipient.type) {
                ForEach(TipOutRuleType.allCases) { type in
                    Text(LocalizedStringKey(type.localizationKey)).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("tipoutrule.type.\(recipient.id)")
            TextField(valuePlaceholder, text: $valueText)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("tipoutrule.value.\(recipient.id)")
                .onAppear { valueText = recipient.value == 0 ? "" : recipient.value.fixedPointString }
                .onChange(of: valueText) { _, newValue in
                    recipient.value = DecimalParsing.parse(newValue) ?? 0
                }
        }
        .padding(.vertical, 4)
    }

    private var valuePlaceholder: LocalizedStringKey {
        switch recipient.type {
        case .percentOfTips, .percentOfSales: return "tipoutrule.value.percent"
        case .flat, .manual: return "tipoutrule.value.amount"
        }
    }
}

extension TipOutRuleType {
    var localizationKey: String { "tipouttype.\(rawValue)" }
}
