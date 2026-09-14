import SwiftUI

/// S003: show and adjust how the tip-out was resolved, recipient by
/// recipient, for one specific shift. Percentages always apply to this
/// shift's gross voluntary tips or sales -- never a running remainder --
/// which the explanation at the foot states plainly.
struct TipOutSplitView: View {
    @Binding var recipients: [TipOutRecipientRule]
    @Binding var tipOutIsManual: Bool
    @Binding var manualAmountText: String
    @Binding var saveAsJobDefault: Bool
    let voluntaryTips: Decimal
    let sales: Decimal
    let currencyCode: String

    @Environment(\.dismiss) private var dismiss

    private var resolvedShares: [TipOutRecipientShare] {
        TipOutEngine.resolve(recipients: recipients, voluntaryTips: voluntaryTips, sales: sales)
    }

    private var total: Decimal {
        tipOutIsManual ? (DecimalParsing.parse(manualAmountText) ?? 0)
                        : resolvedShares.reduce(Decimal(0)) { $0 + $1.resolvedAmount }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("tipoutsplit.manual.toggle", isOn: $tipOutIsManual)
                        .accessibilityIdentifier("tipoutsplit.manual.toggle")
                }

                if tipOutIsManual {
                    Section("tipoutsplit.manual.section") {
                        TextField("tipoutsplit.manual.amount", text: $manualAmountText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("tipoutsplit.manual.amount")
                    }
                } else {
                    Section("tipoutsplit.recipients") {
                        ForEach($recipients) { $recipient in
                            VStack(alignment: .leading, spacing: 6) {
                                RecipientRuleRow(recipient: $recipient)
                                let amount = TipOutEngine.resolve(recipients: [recipient], voluntaryTips: voluntaryTips,
                                                                   sales: sales).first?.resolvedAmount ?? 0
                                Text("tipoutsplit.resolved \(CurrencyFormatting.string(amount, currencyCode: currencyCode))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("tipoutsplit.resolved.\(recipient.id)")
                            }
                        }
                        .onDelete { offsets in recipients.remove(atOffsets: offsets) }

                        Button {
                            recipients.append(TipOutRecipientRule(name: "", type: .percentOfTips, value: 0))
                        } label: {
                            Label("tipoutrule.add", systemImage: "plus")
                        }
                        .accessibilityIdentifier("tipoutsplit.add")
                    }

                    Toggle("tipoutsplit.savedefault", isOn: $saveAsJobDefault)
                        .accessibilityIdentifier("tipoutsplit.savedefault")
                }

                Section {
                    LabeledContent("tipoutsplit.total", value: CurrencyFormatting.string(total, currencyCode: currencyCode))
                        .accessibilityIdentifier("tipoutsplit.total")
                } footer: {
                    Text("tipoutsplit.explanation")
                }
            }
            .navigationTitle("tipoutsplit.title")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                        .accessibilityIdentifier("tipoutsplit.done")
                }
            }
        }
    }
}
