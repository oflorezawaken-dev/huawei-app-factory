import Charts
import SwiftData
import SwiftUI

/// S007: which shifts are worth picking up, which are worth trading away.
/// Every figure derives from entered shifts -- no benchmarks, no predictions.
struct ReportsView: View {
    @Query(sort: \Shift.assignedDate) private var allShifts: [Shift]
    @Query(sort: \Job.createdAt) private var jobs: [Job]
    @Environment(AppSettings.self) private var settings
    @State private var calendar = Calendar.current

    // Sample rows stay in every aggregate until the user removes them in
    // Settings (F011) -- that is what makes the app look like a populated
    // tool rather than four empty tabs. They are flagged with a notice
    // banner here and badged individually in History, never silently
    // excluded just because a real shift now also exists.
    private var shiftsForCharts: [Shift] { allShifts }
    private var hasSampleData: Bool { jobs.contains { $0.isSample } }
    private var currencyCode: String { jobs.first?.currencyCode ?? "USD" }

    private var byWeek: [(week: Date, total: Decimal)] {
        var buckets: [Date: Decimal] = [:]
        for shift in shiftsForCharts {
            let window = PayPeriodEngine.window(containing: shift.assignedDate,
                                                 cycle: .weekly(startWeekday: settings.firstDayOfWeek), calendar: calendar)
            buckets[window.start, default: 0] += shift.totalPay
        }
        return buckets.map { ($0.key, $0.value) }.sorted { $0.week < $1.week }
    }

    private var byWeekday: [(weekday: Int, averageHourly: Decimal)] {
        var sums: [Int: Decimal] = [:], counts: [Int: Int] = [:]
        for shift in shiftsForCharts {
            guard let hourly = shift.effectiveHourly else { continue }
            let weekday = calendar.component(.weekday, from: shift.assignedDate)
            sums[weekday, default: 0] += hourly
            counts[weekday, default: 0] += 1
        }
        return (1...7).compactMap { weekday in
            guard let count = counts[weekday], count > 0 else { return nil }
            return (weekday, sums[weekday]! / Decimal(count))
        }
    }

    private var byJob: [(name: String, total: Decimal)] {
        Dictionary(grouping: shiftsForCharts) { $0.job?.name ?? "" }
            .map { ($0.key, $0.value.reduce(Decimal(0)) { $0 + $1.totalPay }) }
            .sorted { $0.total > $1.total }
    }

    private var bestAndWorst: (best: Shift?, worst: Shift?) {
        let withHourly = shiftsForCharts.filter { $0.effectiveHourly != nil }
        return (withHourly.max { $0.effectiveHourly! < $1.effectiveHourly! },
                withHourly.min { $0.effectiveHourly! < $1.effectiveHourly! })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if allShifts.isEmpty {
                        ContentUnavailableView("reports.empty.title", systemImage: "chart.bar",
                                                description: Text("reports.empty.body"))
                            .accessibilityIdentifier("reports.empty")
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if hasSampleData { SampleDataBanner() }

                                CardSection(titleKey: "reports.byweek") {
                                    if byWeek.count >= 2 {
                                        Chart(byWeek, id: \.week) { point in
                                            BarMark(x: .value("reports.week", point.week, unit: .weekOfYear),
                                                    y: .value("reports.total", (point.total as NSDecimalNumber).doubleValue))
                                        }
                                        .frame(height: 160)
                                        .accessibilityIdentifier("reports.byweek.chart")
                                    } else {
                                        NotEnoughData()
                                    }
                                }

                                CardSection(titleKey: "reports.byweekday") {
                                    if byWeekday.count >= 2 {
                                        Chart(byWeekday, id: \.weekday) { point in
                                            BarMark(x: .value("reports.weekday", calendar.shortWeekdaySymbols[point.weekday - 1]),
                                                    y: .value("reports.hourly", (point.averageHourly as NSDecimalNumber).doubleValue))
                                        }
                                        .frame(height: 160)
                                        .accessibilityIdentifier("reports.byweekday.chart")
                                    } else {
                                        NotEnoughData()
                                    }
                                }

                                if byJob.count > 1 {
                                    CardSection(titleKey: "reports.byjob") {
                                        Chart(byJob, id: \.name) { point in
                                            BarMark(x: .value("reports.job", point.name),
                                                    y: .value("reports.total", (point.total as NSDecimalNumber).doubleValue))
                                        }
                                        .frame(height: 160)
                                        .accessibilityIdentifier("reports.byjob.chart")
                                    }
                                }

                                CardSection(titleKey: "reports.bestworst") {
                                    if let best = bestAndWorst.best, let worst = bestAndWorst.worst {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("reports.best \(CurrencyFormatting.stringOrDash(best.effectiveHourly, currencyCode: currencyCode))")
                                            Text("reports.worst \(CurrencyFormatting.stringOrDash(worst.effectiveHourly, currencyCode: currencyCode))")
                                        }
                                        .accessibilityIdentifier("reports.bestworst.values")
                                    } else {
                                        NotEnoughData()
                                    }
                                }

                                if settings.minimumWage != nil {
                                    NavigationLink("reports.minwage") {
                                        MinimumWageCheckView()
                                    }
                                    .accessibilityIdentifier("reports.minwage.link")
                                }
                            }
                            .padding()
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                TabRootBanner()
            }
            .navigationTitle("tab.reports")
        }
    }
}

struct NotEnoughData: View {
    var body: some View {
        Text("reports.notenoughdata")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("reports.notenoughdata")
    }
}
