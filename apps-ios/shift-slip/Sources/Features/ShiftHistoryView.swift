import SwiftData
import SwiftUI

/// S005: every shift, newest first, grouped the way the user gets paid.
struct ShiftHistoryView: View {
    private enum Grouping: String, CaseIterable, Identifiable {
        case week, period, month
        var id: String { rawValue }
        var localizationKey: String { "history.grouping.\(rawValue)" }
    }

    @Query(sort: \Shift.assignedDate, order: .reverse) private var allShifts: [Shift]
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @State private var grouping: Grouping = .week
    @State private var jobFilter: Job?
    @State private var editingShift: Shift?
    @State private var calendar = Calendar.current

    private var filteredShifts: [Shift] {
        guard let jobFilter else { return allShifts }
        return allShifts.filter { $0.job?.persistentModelID == jobFilter.persistentModelID }
    }

    private var groups: [(key: Date, title: String, shifts: [Shift], rollup: Rollup)] {
        let cycle: PayPeriodCycle = jobFilter?.payPeriodCycle ?? .weekly(startWeekday: settings.firstDayOfWeek)
        var buckets: [Date: [Shift]] = [:]
        for shift in filteredShifts {
            let key: Date
            switch grouping {
            case .week:
                key = PayPeriodEngine.window(containing: shift.assignedDate,
                                              cycle: .weekly(startWeekday: settings.firstDayOfWeek),
                                              calendar: calendar).start
            case .period:
                key = PayPeriodEngine.window(containing: shift.assignedDate, cycle: cycle, calendar: calendar).start
            case .month:
                key = PayPeriodEngine.window(containing: shift.assignedDate, cycle: .monthly, calendar: calendar).start
            }
            buckets[key, default: []].append(shift)
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return buckets.map { key, shifts in
            let rollup = RollupEngine.total(shifts.map {
                RollupInput(jobID: $0.job?.id ?? UUID(), assignedDate: $0.assignedDate, figures: $0.figures)
            })
            return (key, formatter.string(from: key), shifts.sorted { $0.assignedDate > $1.assignedDate }, rollup)
        }.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if allShifts.isEmpty {
                        ContentUnavailableView("history.empty.title", systemImage: "clock",
                                                description: Text("history.empty.body"))
                            .accessibilityIdentifier("history.empty")
                    } else {
                        List {
                            Picker("history.grouping", selection: $grouping) {
                                ForEach(Grouping.allCases) { g in
                                    Text(LocalizedStringKey(g.localizationKey)).tag(g)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("history.grouping")
                            .listRowSeparator(.hidden)

                            if !jobs.isEmpty {
                                Picker("history.jobfilter", selection: $jobFilter) {
                                    Text("history.jobfilter.all").tag(Job?.none)
                                    ForEach(jobs) { job in Text(job.name).tag(Optional(job)) }
                                }
                                .accessibilityIdentifier("history.jobfilter")
                            }

                            ForEach(groups, id: \.key) { group in
                                Section {
                                    ForEach(group.shifts) { shift in
                                        Button { editingShift = shift } label: {
                                            ShiftRow(shift: shift)
                                        }
                                        .accessibilityIdentifier("history.row.\(shift.persistentModelID)")
                                    }
                                    .onDelete { offsets in
                                        for index in offsets {
                                            let shift = group.shifts[index]
                                            ClosoutPhotoStorage.delete(fileName: shift.closeoutPhotoFileName)
                                            context.delete(shift)
                                        }
                                    }
                                } header: {
                                    HStack {
                                        Text(group.title)
                                        Spacer()
                                        Text(CurrencyFormatting.stringOrDash(group.rollup.effectiveHourly,
                                                                              currencyCode: jobFilter?.currencyCode ?? "USD"))
                                    }
                                }
                            }

                            NavigationLink("history.dailytiprecord") {
                                DailyTipRecordView(jobFilter: jobFilter)
                            }
                            .accessibilityIdentifier("history.dailytiprecord.link")
                        }
                        .accessibilityIdentifier("history.list")
                    }
                }
                .frame(maxHeight: .infinity)
                TabRootBanner()
            }
            .navigationTitle("tab.history")
            .sheet(item: $editingShift) { shift in
                LogShiftView(existingShift: shift)
            }
        }
    }
}

private struct ShiftRow: View {
    let shift: Shift

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(shift.job?.name ?? "").font(.subheadline.bold())
                    if shift.isSample {
                        Text("common.sample.badge")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.yellow.opacity(0.3), in: Capsule())
                    }
                }
                Text(shift.assignedDate, style: .date).font(.caption).foregroundStyle(.secondary)
                Text(CurrencyFormatting.hours(shift.hours) + " h").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(CurrencyFormatting.string(shift.tipsKept, currencyCode: shift.job?.currencyCode ?? "USD"))
                    .font(.subheadline).monospacedDigit()
                Text(CurrencyFormatting.stringOrDash(shift.effectiveHourly, currencyCode: shift.job?.currencyCode ?? "USD"))
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
        }
    }
}
