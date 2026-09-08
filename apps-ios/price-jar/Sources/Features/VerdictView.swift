import SwiftData
import SwiftUI

/// S005 Good Price? -- answers the aisle question. No advertising of any kind.
/// This is also where the pending entry from Record Price actually gets
/// written to SwiftData, one tap away (F005).
struct VerdictView: View {
    let item: Item
    let pending: RecordPriceView.PendingVerdict
    var onSaved: () -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @State private var didSave = false

    private var candidateUnitPrice: Decimal {
        (try? UnitNormalization.unitPrice(price: pending.price, packageSize: pending.packageSize, unit: pending.unit)) ?? 0
    }

    // All entries, including sample rows -- a sample item's Price Book row
    // already shows a price via `bestEntry` (also unfiltered), so the
    // verdict must not claim "not enough data" for the same item. Sample
    // exclusion is a Stats/CSV rule (F011), not a screen-visibility rule.
    private var history: [VerdictHistoryPoint] {
        item.priceEntries
            .filter { $0.countsTowardTypical(includeSaleAndLoyalty: settings.includeSaleAndLoyaltyInTypical) }
            .map { VerdictHistoryPoint(unitPrice: $0.unitPrice, storeName: $0.store?.name ?? "", date: $0.date) }
    }

    private var result: VerdictResult {
        let packageBaseQuantity = UnitNormalization.baseQuantity(packageSize: pending.packageSize, unit: pending.unit)
        return VerdictEngine.evaluate(candidateUnitPrice: candidateUnitPrice,
                                       packageBaseQuantity: packageBaseQuantity, history: history)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    badge
                    Text(PriceFormatting.string(displayPrice(candidateUnitPrice), symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit))
                        .font(.system(.largeTitle, design: .monospaced))
                        .accessibilityIdentifier("verdict.candidatePrice")

                    if result.verdict == .notEnoughData {
                        Text("verdict.notEnoughData \(history.count)")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("verdict.notEnoughData")
                        if let best = result.bestUnitPrice, let storeName = result.bestStoreName {
                            Text("verdict.bestSoFar \(PriceFormatting.string(displayPrice(best), symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit)) \(storeName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        detail
                    }

                    Button(didSave ? "verdict.saved" : "verdict.save", action: save)
                        .buttonStyle(.borderedProminent)
                        .disabled(didSave)
                        .accessibilityIdentifier("verdict.save")
                }
                .padding()
            }
            .navigationTitle("verdict.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                        .accessibilityIdentifier("verdict.cancel")
                }
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        let (key, color, systemImage): (String, Color, String) = {
            switch result.verdict {
            case .best: return ("verdict.best", .green, "star.fill")
            case .typical: return ("verdict.typical", .yellow, "checkmark.circle.fill")
            case .aboveYourUsual: return ("verdict.aboveUsual", .red, "arrow.up.circle.fill")
            case .notEnoughData: return ("verdict.notEnoughDataBadge", .secondary, "questionmark.circle")
            }
        }()
        Label(LocalizedStringKey(key), systemImage: systemImage)
            .font(.title2.bold())
            .foregroundStyle(color)
            .accessibilityIdentifier("verdict.badge")
    }

    @ViewBuilder
    private var detail: some View {
        VStack(spacing: 8) {
            if let best = result.bestUnitPrice, let storeName = result.bestStoreName {
                LabeledContent("verdict.best.label") {
                    Text(PriceFormatting.string(displayPrice(best), symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit) + " " + storeName)
                }
                .accessibilityIdentifier("verdict.bestDetail")
            }
            if let median = result.medianUnitPrice {
                LabeledContent("verdict.median.label") {
                    Text(PriceFormatting.string(displayPrice(median), symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit))
                }
                .accessibilityIdentifier("verdict.medianDetail")
            }
            if let percent = result.differencePercent, let amount = result.differenceAmount {
                LabeledContent("verdict.difference.label") {
                    Text("\(PriceFormatting.percent(percent)) (\(PriceFormatting.currencyAmount(amount, symbol: settings.currencySymbol)))")
                }
                .accessibilityIdentifier("verdict.differenceDetail")
            }
        }
        .font(.subheadline)
    }

    private func displayPrice(_ baseUnitPrice: Decimal) -> Decimal {
        UnitNormalization.displayUnitPrice(baseUnitPrice: baseUnitPrice, displayUnit: item.preferredDisplayUnit)
    }

    private func save() {
        let entry = PriceEntry(item: item, store: pending.store, price: pending.price,
                                packageSize: pending.packageSize, unit: pending.unit, date: pending.date,
                                isSale: pending.isSale, isLoyalty: pending.isLoyalty)
        context.insert(entry)
        didSave = true

        let wasFirstEntry = !settings.hasSavedFirstPriceEntry
        settings.hasSavedFirstPriceEntry = true
        dismiss()
        if wasFirstEntry, !settings.hasRequestedTracking {
            settings.hasRequestedTracking = true
            Task {
                await TrackingAuthorization.requestIfNeeded()
                await MainActor.run { onSaved() }
            }
        } else {
            onSaved()
        }
    }
}
