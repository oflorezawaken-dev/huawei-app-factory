import SwiftData
import SwiftUI
import UIKit

/// S004: close the loop after the shift is already saved. The interstitial
/// (if any) only ever fires from here, after the write to disk has completed
/// -- never before.
struct ShiftSummaryView: View {
    let shift: Shift

    @Environment(AppSettings.self) private var settings
    @Environment(InterstitialAdController.self) private var interstitial
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    private var currencyCode: String { shift.job?.currencyCode ?? "USD" }

    private var averageEffectiveHourlyForJobAndWeekday: Decimal? {
        guard let job = shift.job else { return nil }
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: shift.assignedDate)
        let comparable = (job.shifts ?? []).filter {
            $0.id != shift.id && !$0.isSample
                && calendar.component(.weekday, from: $0.assignedDate) == weekday
        }
        guard !comparable.isEmpty else { return nil }
        let rollup = RollupEngine.total(comparable.map {
            RollupInput(jobID: job.id, assignedDate: $0.assignedDate, figures: $0.figures)
        })
        return rollup.effectiveHourly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("summary.effectivehourly")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatting.stringOrDash(shift.effectiveHourly, currencyCode: currencyCode))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .accessibilityIdentifier("summary.effectivehourly.value")
                    }

                    VStack(spacing: 12) {
                        SummaryRow(titleKey: "summary.tipskept",
                                   value: CurrencyFormatting.string(shift.tipsKept, currencyCode: currencyCode),
                                   identifier: "summary.tipskept")
                        SummaryRow(titleKey: "summary.basepay",
                                   value: CurrencyFormatting.string(shift.basePay, currencyCode: currencyCode),
                                   identifier: "summary.basepay")
                        SummaryRow(titleKey: "summary.totalpay",
                                   value: CurrencyFormatting.string(shift.totalPay, currencyCode: currencyCode),
                                   identifier: "summary.totalpay")
                        SummaryRow(titleKey: "summary.tipsperhour",
                                   value: CurrencyFormatting.stringOrDash(shift.tipsPerHour, currencyCode: currencyCode),
                                   identifier: "summary.tipsperhour")
                        if let tipPercentage = shift.tipPercentage {
                            SummaryRow(titleKey: "summary.tippercentage",
                                       value: CurrencyFormatting.percentage(tipPercentage),
                                       identifier: "summary.tippercentage")
                        }
                    }
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))

                    if let average = averageEffectiveHourlyForJobAndWeekday {
                        Text("summary.comparison \(CurrencyFormatting.string(average, currencyCode: currencyCode))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("summary.comparison")
                    }

                    if let fileName = shift.closeoutPhotoFileName,
                       let uiImage = UIImage(contentsOfFile: ClosoutPhotoStorage.url(for: fileName).path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityIdentifier("summary.closeoutphoto")
                    }
                }
                .padding()
            }
            .navigationTitle("summary.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("summary.edit") { showingEdit = true }
                        .accessibilityIdentifier("summary.edit")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("summary.done") { dismiss() }
                        .accessibilityIdentifier("summary.done")
                }
            }
            .sheet(isPresented: $showingEdit) {
                LogShiftView(existingShift: shift)
            }
            .task {
                guard !UITestMode.isActive else { return }
                await TrackingAuthorization.requestIfNeeded(settings: settings)
                await interstitial.load()
                await interstitial.presentIfAllowed(from: Self.rootViewController(),
                                                     savedShiftCount: settings.savedShiftCount)
            }
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

private struct SummaryRow: View {
    let titleKey: LocalizedStringKey
    let value: String
    let identifier: String

    var body: some View {
        HStack {
            Text(titleKey)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(.secondary)
        }
        .accessibilityIdentifier(identifier)
    }
}
