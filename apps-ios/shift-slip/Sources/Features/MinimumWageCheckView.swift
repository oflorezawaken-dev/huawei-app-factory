import SwiftData
import SwiftUI

/// S008: informational only (F008). Shows only the user's own arithmetic --
/// hours, total pay, average hourly and the figure they entered themselves.
/// No state named, no statute cited, no allegation, no suggested action.
struct MinimumWageCheckView: View {
    @Query(sort: \Shift.assignedDate, order: .reverse) private var allShifts: [Shift]
    @Environment(AppSettings.self) private var settings
    @State private var showingEditWage = false
    @State private var wageText = ""
    @State private var calendar = Calendar.current

    private var currentPeriodRollup: Rollup {
        let window = PayPeriodEngine.window(containing: .now, cycle: .weekly(startWeekday: settings.firstDayOfWeek),
                                             calendar: calendar)
        let inputs = allShifts.filter { window.contains($0.assignedDate) && !$0.isSample }
            .map { RollupInput(jobID: $0.job?.id ?? UUID(), assignedDate: $0.assignedDate, figures: $0.figures) }
        return RollupEngine.total(inputs)
    }

    private var currencyCode: String { allShifts.first?.job?.currencyCode ?? "USD" }

    var body: some View {
        Group {
            if let minimumWage = settings.minimumWage {
                List {
                    Section("minwage.period") {
                        LabeledContent("minwage.hours", value: CurrencyFormatting.hours(currentPeriodRollup.hours))
                        LabeledContent("minwage.totalpay",
                                        value: CurrencyFormatting.string(currentPeriodRollup.totalPay, currencyCode: currencyCode))
                        LabeledContent("minwage.averagehourly",
                                        value: CurrencyFormatting.stringOrDash(currentPeriodRollup.effectiveHourly, currencyCode: currencyCode))
                            .accessibilityIdentifier("minwage.averagehourly")
                        LabeledContent("minwage.enteredfigure",
                                        value: CurrencyFormatting.string(minimumWage, currencyCode: currencyCode))
                            .accessibilityIdentifier("minwage.enteredfigure")
                    }

                    if let average = currentPeriodRollup.effectiveHourly, average < minimumWage {
                        Section {
                            Text("minwage.worthasking")
                                .accessibilityIdentifier("minwage.worthasking")
                        }
                    }

                    Section {
                        Button("minwage.editfigure") {
                            wageText = minimumWage.fixedPointString
                            showingEditWage = true
                        }
                        .accessibilityIdentifier("minwage.editfigure")
                    }
                }
            } else {
                ContentUnavailableView("minwage.notset.title", systemImage: "questionmark.circle",
                                        description: Text("minwage.notset.body"))
                    .accessibilityIdentifier("minwage.notset")
            }
        }
        .navigationTitle("minwage.title")
        .alert("minwage.editfigure", isPresented: $showingEditWage) {
            TextField("minwage.enteredfigure", text: $wageText)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("minwage.editfigure.field")
            Button("common.save") {
                settings.minimumWage = DecimalParsing.parse(wageText)
            }
            Button("common.cancel", role: .cancel) {}
        }
    }
}
