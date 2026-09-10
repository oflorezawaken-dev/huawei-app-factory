import SwiftData
import SwiftUI

/// S001: this week and this pay period at a glance, and the one button that
/// starts the whole loop.
struct DashboardView: View {
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @Query(sort: \Shift.assignedDate, order: .reverse) private var allShifts: [Shift]
    @Environment(AppSettings.self) private var settings
    @State private var showingLogShift = false
    @State private var showingSettings = false
    @State private var savedShift: Shift?
    @State private var calendar = Calendar.current

    private var hasSampleData: Bool { jobs.contains { $0.isSample } }

    private var thisWeekRollup: Rollup {
        let window = PayPeriodEngine.window(containing: .now, cycle: .weekly(startWeekday: settings.firstDayOfWeek),
                                             calendar: calendar)
        let inputs = allShifts.filter { window.contains($0.assignedDate) }
            .map { RollupInput(jobID: $0.job?.id ?? UUID(), assignedDate: $0.assignedDate, figures: $0.figures) }
        return RollupEngine.total(inputs)
    }

    private var lastShift: Shift? { allShifts.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if jobs.isEmpty {
                        ContentUnavailableView {
                            Label("dashboard.empty.title", systemImage: "briefcase")
                        } description: {
                            Text("dashboard.empty.body")
                        }
                        .accessibilityIdentifier("dashboard.empty")
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if hasSampleData {
                                    SampleDataBanner()
                                }

                                Button {
                                    showingLogShift = true
                                } label: {
                                    Label("dashboard.logshift", systemImage: "plus.circle.fill")
                                        .font(.title3.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("dashboard.logshift")

                                CardSection(titleKey: "dashboard.thisweek") {
                                    StatGrid(rollup: thisWeekRollup, currencyCode: jobs.first?.currencyCode ?? "USD")
                                }
                                .accessibilityIdentifier("dashboard.thisweek.card")

                                if let lastShift, let job = lastShift.job {
                                    CardSection(titleKey: "dashboard.lastshift") {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(job.name).font(.subheadline.bold())
                                                Text(lastShift.assignedDate, style: .date)
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text(CurrencyFormatting.stringOrDash(lastShift.effectiveHourly,
                                                                                  currencyCode: job.currencyCode))
                                                .font(.headline).monospacedDigit()
                                        }
                                    }
                                    .accessibilityIdentifier("dashboard.lastshift.card")
                                }

                                if settings.monthlyExportReminderEnabled,
                                   DailyTipRecordEngine.employerReportDueDate(closingMonth: calendar.date(byAdding: .month, value: -1, to: .now)!, today: .now, calendar: calendar) != nil {
                                    Text("dashboard.exportnudge")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .accessibilityIdentifier("dashboard.exportnudge")
                                }
                            }
                            .padding()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                TabRootBanner()
            }
            .navigationTitle("tab.dashboard")
            .toolbar {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .accessibilityIdentifier("dashboard.settings")
            }
            .navigationDestination(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingLogShift) {
                LogShiftView { shift in savedShift = shift }
            }
            .sheet(item: $savedShift) { shift in
                ShiftSummaryView(shift: shift)
            }
        }
    }
}

struct SampleDataBanner: View {
    var body: some View {
        HStack {
            Image(systemName: "info.circle")
            Text("common.sampledata.notice")
        }
        .font(.footnote)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("common.sampledata.notice")
    }
}

struct CardSection<Content: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey).font(.headline)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatGrid: View {
    let rollup: Rollup
    let currencyCode: String

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            GridRow {
                StatCell(titleKey: "stat.hours", value: CurrencyFormatting.hours(rollup.hours))
                StatCell(titleKey: "stat.tipskept", value: CurrencyFormatting.string(rollup.tipsKept, currencyCode: currencyCode))
            }
            GridRow {
                StatCell(titleKey: "stat.totalpay", value: CurrencyFormatting.string(rollup.totalPay, currencyCode: currencyCode))
                StatCell(titleKey: "stat.effectivehourly",
                         value: CurrencyFormatting.stringOrDash(rollup.effectiveHourly, currencyCode: currencyCode))
            }
        }
    }
}

struct StatCell: View {
    let titleKey: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titleKey).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold()).monospacedDigit()
        }
    }
}
