import SwiftData
import SwiftUI

struct JobEditView: View {
    let job: Job?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var payType: PayType = .hourlyPlusTips
    @State private var baseRateText = ""
    @State private var employerName = ""
    @State private var businessName = ""
    @State private var occupationLabel = ""
    @State private var currencyCode = AppSettings.defaultCurrencyCode
    @State private var currencySymbol = AppSettings.defaultCurrencySymbol
    @State private var cycleKind = CycleKind.weekly
    @State private var startWeekday = 1
    @State private var anchorDate = Date.now
    @State private var recipients: [TipOutRecipientRule] = []

    private enum CycleKind: String, CaseIterable, Identifiable {
        case weekly, biweekly, semimonthly, monthly
        var id: String { rawValue }
        var localizationKey: String { "cycle.\(rawValue)" }
    }

    private var baseRate: Decimal? { DecimalParsing.parse(baseRateText) }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && baseRate != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("jobedit.section.basics") {
                    TextField("jobedit.name", text: $name)
                        .accessibilityIdentifier("jobedit.name")
                    Picker("jobedit.paytype", selection: $payType) {
                        ForEach(PayType.allCases) { type in
                            Text(LocalizedStringKey(type.localizationKey)).tag(type)
                        }
                    }
                    .accessibilityIdentifier("jobedit.paytype")
                    TextField("jobedit.baserate", text: $baseRateText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("jobedit.baserate")
                }

                Section("jobedit.section.record") {
                    TextField("jobedit.employer", text: $employerName)
                        .accessibilityIdentifier("jobedit.employer")
                    TextField("jobedit.business", text: $businessName)
                        .accessibilityIdentifier("jobedit.business")
                    TextField("jobedit.occupation", text: $occupationLabel)
                        .accessibilityIdentifier("jobedit.occupation")
                }

                Section("jobedit.section.currency") {
                    TextField("jobedit.currencycode", text: $currencyCode)
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier("jobedit.currencycode")
                    TextField("jobedit.currencysymbol", text: $currencySymbol)
                        .accessibilityIdentifier("jobedit.currencysymbol")
                }

                Section("jobedit.section.cycle") {
                    Picker("jobedit.cycle", selection: $cycleKind) {
                        ForEach(CycleKind.allCases) { kind in
                            Text(LocalizedStringKey(kind.localizationKey)).tag(kind)
                        }
                    }
                    .accessibilityIdentifier("jobedit.cycle")
                    if cycleKind == .weekly {
                        Picker("jobedit.startweekday", selection: $startWeekday) {
                            ForEach(1...7, id: \.self) { weekday in
                                Text(weekdaySymbol(weekday)).tag(weekday)
                            }
                        }
                        .accessibilityIdentifier("jobedit.startweekday")
                    } else if cycleKind == .biweekly {
                        DatePicker("jobedit.anchordate", selection: $anchorDate, displayedComponents: .date)
                            .accessibilityIdentifier("jobedit.anchordate")
                    }
                }

                Section {
                    NavigationLink {
                        TipOutRuleEditorView(recipients: $recipients)
                    } label: {
                        HStack {
                            Text("jobedit.tipout.rule")
                            Spacer()
                            Text("jobedit.tipout.count \(String(recipients.count))").foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("jobedit.tipout.link")
                } header: {
                    Text("jobedit.section.tipout")
                } footer: {
                    Text("jobedit.section.tipout.footer")
                }
            }
            .navigationTitle(job == nil ? "jobedit.new" : "jobedit.existing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                        .accessibilityIdentifier("jobedit.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", action: save)
                        .disabled(!isValid)
                        .accessibilityIdentifier("jobedit.save")
                }
            }
            .onAppear(perform: load)
        }
    }

    private func weekdaySymbol(_ weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        return symbols[(weekday - 1) % 7]
    }

    private func load() {
        guard let job else { return }
        name = job.name
        payType = job.payType
        baseRateText = job.baseRate.fixedPointString
        employerName = job.employerName
        businessName = job.businessName
        occupationLabel = job.occupationLabel
        currencyCode = job.currencyCode
        currencySymbol = job.currencySymbol
        recipients = job.defaultTipOutRule
        switch job.payPeriodCycle {
        case .weekly(let weekday): cycleKind = .weekly; startWeekday = weekday
        case .biweekly(let anchor): cycleKind = .biweekly; anchorDate = anchor
        case .semimonthly: cycleKind = .semimonthly
        case .monthly: cycleKind = .monthly
        }
    }

    private func save() {
        guard let baseRate else { return }
        let cycle: PayPeriodCycle
        switch cycleKind {
        case .weekly: cycle = .weekly(startWeekday: startWeekday)
        case .biweekly: cycle = .biweekly(anchorDate: anchorDate)
        case .semimonthly: cycle = .semimonthly
        case .monthly: cycle = .monthly
        }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let job {
            job.name = trimmedName
            job.payType = payType
            job.baseRate = baseRate
            job.employerName = employerName
            job.businessName = businessName
            job.occupationLabel = occupationLabel
            job.currencyCode = currencyCode
            job.currencySymbol = currencySymbol
            job.payPeriodCycle = cycle
            job.defaultTipOutRule = recipients
        } else {
            let newJob = Job(name: trimmedName, payType: payType, baseRate: baseRate,
                              employerName: employerName, businessName: businessName,
                              occupationLabel: occupationLabel, currencyCode: currencyCode,
                              currencySymbol: currencySymbol, payPeriodCycle: cycle)
            newJob.defaultTipOutRule = recipients
            context.insert(newJob)
        }
        dismiss()
    }
}
