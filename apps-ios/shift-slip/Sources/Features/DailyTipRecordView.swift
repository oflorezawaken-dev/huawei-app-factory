import SwiftData
import SwiftUI

/// S006: the statutory record -- Publication 531's fields, day by day.
/// Carries no advertising at all.
struct DailyTipRecordView: View {
    let jobFilter: Job?

    @Query private var allShifts: [Shift]
    @Environment(AppSettings.self) private var settings
    @State private var rangeStart: Date
    @State private var rangeEnd: Date
    @State private var showingExport = false
    @State private var calendar = Calendar.current

    init(jobFilter: Job?) {
        self.jobFilter = jobFilter
        let now = Date.now
        let calendar = Calendar.current
        let monthWindow = PayPeriodEngine.window(containing: now, cycle: .monthly, calendar: calendar)
        _rangeStart = State(initialValue: monthWindow.start)
        _rangeEnd = State(initialValue: calendar.date(byAdding: .day, value: -1, to: monthWindow.end) ?? now)
    }

    private var shiftsInRange: [Shift] {
        allShifts.filter {
            $0.assignedDate >= calendar.startOfDay(for: rangeStart)
                && $0.assignedDate <= calendar.startOfDay(for: rangeEnd)
                && (jobFilter == nil || $0.job?.persistentModelID == jobFilter?.persistentModelID)
        }
    }

    private var lines: [DailyTipRecordLine] {
        let inputs = shiftsInRange.map { shift in
            DailyTipRecordInput(date: shift.assignedDate, jobID: shift.job?.id ?? UUID(),
                                 employerName: shift.job?.employerName ?? "", businessName: shift.job?.businessName ?? "",
                                 cashTips: shift.cashTips, chargeTips: shift.chargeTips, noncashTips: shift.noncashTips,
                                 tipOutTotal: shift.tipOutTotal, serviceCharges: shift.serviceCharges, isSample: shift.isSample)
        }
        return DailyTipRecordEngine.lines(from: inputs, calendar: calendar)
    }

    private var dueDate: Date? {
        DailyTipRecordEngine.employerReportDueDate(closingMonth: rangeStart, today: .now, calendar: calendar)
    }

    var body: some View {
        List {
            Section {
                DatePicker("dailytiprecord.start", selection: $rangeStart, displayedComponents: .date)
                    .accessibilityIdentifier("dailytiprecord.start")
                DatePicker("dailytiprecord.end", selection: $rangeEnd, displayedComponents: .date)
                    .accessibilityIdentifier("dailytiprecord.end")
            }

            if let dueDate {
                Section {
                    Text("dailytiprecord.duedate \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .accessibilityIdentifier("dailytiprecord.duedate")
                }
            }

            if lines.isEmpty {
                ContentUnavailableView("dailytiprecord.empty", systemImage: "doc.text")
                    .accessibilityIdentifier("dailytiprecord.empty")
            } else {
                Section("dailytiprecord.lines") {
                    ForEach(lines) { line in
                        DailyTipRecordRow(line: line, currencyCode: jobFilter?.currencyCode ?? "USD")
                            .accessibilityIdentifier("dailytiprecord.row.\(line.id)")
                    }
                }

                Section("dailytiprecord.total") {
                    let total = DailyTipRecordEngine.monthTotal(lines)
                    LabeledContent("dailytiprecord.total.tips",
                                    value: CurrencyFormatting.string(total.voluntaryTips, currencyCode: jobFilter?.currencyCode ?? "USD"))
                    LabeledContent("dailytiprecord.total.servicecharges",
                                    value: CurrencyFormatting.string(total.serviceCharges, currencyCode: jobFilter?.currencyCode ?? "USD"))
                }
                .accessibilityIdentifier("dailytiprecord.total")
            }

            Section {
                Button("dailytiprecord.export") { showingExport = true }
                    .accessibilityIdentifier("dailytiprecord.export")
            }

            Section {
                Text("common.recordsnotadvice")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("dailytiprecord.footer")
            }
        }
        .navigationTitle("dailytiprecord.title")
        .sheet(isPresented: $showingExport) {
            ExportView(jobFilter: jobFilter, initialStart: rangeStart, initialEnd: rangeEnd)
        }
    }
}

private struct DailyTipRecordRow: View {
    let line: DailyTipRecordLine
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(line.date, style: .date).font(.subheadline.bold())
                if line.isSample {
                    Text("common.sample.badge")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.yellow.opacity(0.3), in: Capsule())
                }
            }
            Text(line.employerName.isEmpty ? line.businessName : line.employerName)
                .font(.caption).foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 12) {
                GridRow {
                    Text("dailytiprecord.field.cash").font(.caption2).foregroundStyle(.secondary)
                    Text("dailytiprecord.field.charge").font(.caption2).foregroundStyle(.secondary)
                    Text("dailytiprecord.field.noncash").font(.caption2).foregroundStyle(.secondary)
                    Text("dailytiprecord.field.paidout").font(.caption2).foregroundStyle(.secondary)
                    Text("dailytiprecord.field.servicecharges").font(.caption2).foregroundStyle(.secondary)
                }
                GridRow {
                    Text(CurrencyFormatting.string(line.cashTips, currencyCode: currencyCode)).monospacedDigit()
                    Text(CurrencyFormatting.string(line.chargeTips, currencyCode: currencyCode)).monospacedDigit()
                    Text(CurrencyFormatting.string(line.noncashTips, currencyCode: currencyCode)).monospacedDigit()
                    Text(CurrencyFormatting.string(line.tipsPaidOut, currencyCode: currencyCode)).monospacedDigit()
                    Text(CurrencyFormatting.string(line.serviceCharges, currencyCode: currencyCode)).monospacedDigit()
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
