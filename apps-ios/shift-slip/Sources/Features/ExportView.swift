import SwiftData
import SwiftUI

/// S010: get the records out, in CSV for a spreadsheet and PDF for a person.
/// Free forever, behind no purchase, and carries no advertising.
struct ExportView: View {
    let jobFilter: Job?
    let initialStart: Date
    let initialEnd: Date

    private enum Format: String, CaseIterable, Identifiable {
        case csv, pdf, both
        var id: String { rawValue }
        var localizationKey: String { "export.format.\(rawValue)" }
    }

    @Query private var allShifts: [Shift]
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var start: Date
    @State private var end: Date
    @State private var format: Format = .both
    @State private var shareItems: [Any]?
    @State private var calendar = Calendar.current

    init(jobFilter: Job?, initialStart: Date, initialEnd: Date) {
        self.jobFilter = jobFilter
        self.initialStart = initialStart
        self.initialEnd = initialEnd
        _start = State(initialValue: initialStart)
        _end = State(initialValue: initialEnd)
    }

    private var shiftsInRange: [Shift] {
        allShifts.filter {
            $0.assignedDate >= calendar.startOfDay(for: start) && $0.assignedDate <= calendar.startOfDay(for: end)
                && (jobFilter == nil || $0.job?.persistentModelID == jobFilter?.persistentModelID)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("export.start", selection: $start, displayedComponents: .date)
                        .accessibilityIdentifier("export.start")
                    DatePicker("export.end", selection: $end, displayedComponents: .date)
                        .accessibilityIdentifier("export.end")
                }
                Section {
                    Picker("export.format", selection: $format) {
                        ForEach(Format.allCases) { f in
                            Text(LocalizedStringKey(f.localizationKey)).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("export.format")
                }
                Section {
                    Text("export.preview \(String(shiftsInRange.count))")
                        .accessibilityIdentifier("export.preview")
                }
                Section {
                    Text("export.free")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section {
                    Button("export.share") { share() }
                        .disabled(shiftsInRange.isEmpty)
                        .accessibilityIdentifier("export.share")
                }
            }
            .navigationTitle("export.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") { dismiss() }
                        .accessibilityIdentifier("export.done")
                }
            }
            .sheet(isPresented: Binding(get: { shareItems != nil }, set: { if !$0 { shareItems = nil } })) {
                if let shareItems {
                    ActivityView(activityItems: shareItems)
                }
            }
        }
    }

    private func share() {
        var items: [Any] = []
        if format == .csv || format == .both {
            let rows = shiftsInRange.map { shift in
                CSVShiftRow(date: shift.assignedDate, jobName: shift.job?.name ?? "",
                            employerName: shift.job?.employerName ?? "", businessName: shift.job?.businessName ?? "",
                            hours: shift.hours, baseRate: shift.job?.baseRate ?? 0, basePay: shift.basePay,
                            cashTips: shift.cashTips, chargeTips: shift.chargeTips, noncashTips: shift.noncashTips,
                            serviceCharges: shift.serviceCharges, tipOutTotal: shift.tipOutTotal,
                            recipientShares: shift.tipOutShares, tipsKept: shift.tipsKept, totalPay: shift.totalPay,
                            effectiveHourly: shift.effectiveHourly, sales: shift.sales, isSample: shift.isSample)
            }
            let data = CSVExport.data(rows: rows)
            let url = FileManager.default.temporaryDirectory.appending(path: "ShiftSlip-\(UUID().uuidString).csv")
            try? data.write(to: url)
            items.append(url)
        }
        if format == .pdf || format == .both {
            let inputs = shiftsInRange.map { shift in
                DailyTipRecordInput(date: shift.assignedDate, jobID: shift.job?.id ?? UUID(),
                                     employerName: shift.job?.employerName ?? "", businessName: shift.job?.businessName ?? "",
                                     cashTips: shift.cashTips, chargeTips: shift.chargeTips, noncashTips: shift.noncashTips,
                                     tipOutTotal: shift.tipOutTotal, serviceCharges: shift.serviceCharges, isSample: shift.isSample)
            }
            let lines = DailyTipRecordEngine.lines(from: inputs, calendar: calendar)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let rangeTitle = "\(formatter.string(from: start)) - \(formatter.string(from: end))"
            let pdfData = DailyTipRecordPDF.render(lines: lines, rangeTitle: rangeTitle,
                                                    employeeName: settings.employeeName,
                                                    currencyCode: jobFilter?.currencyCode ?? "USD",
                                                    footerText: String(localized: "common.recordsnotadvice"))
            let url = FileManager.default.temporaryDirectory.appending(path: "ShiftSlip-\(UUID().uuidString).pdf")
            try? pdfData.write(to: url)
            items.append(url)
        }
        shareItems = items
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
