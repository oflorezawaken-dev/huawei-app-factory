import Charts
import SwiftData
import SwiftUI

/// S010 Stats -- the evidence: what the basket costs over time and where the
/// money goes. Every figure comes from the user's own entries.
struct StatsView: View {
    @Query private var items: [Item]
    @Query private var trips: [Trip]
    @Environment(AppSettings.self) private var settings

    private var monthlyBasket: [StatsEngine.MonthlyBasketPoint] {
        let savedTrips = trips.filter { $0.isSaved && !$0.isSample }
        return StatsEngine.monthlyBasket(trips: savedTrips.map { (date: $0.date, total: $0.total) })
    }

    private var savings: StatsEngine.SavingsResult {
        let entriesByItem = items.map { item in
            item.recordedEntries.map {
                StatsEngine.EntryPoint(unitPrice: $0.unitPrice,
                                        baseQuantity: UnitNormalization.baseQuantity(packageSize: $0.packageSize, unit: $0.unit))
            }
        }
        return StatsEngine.totalSaved(entriesByItem: entriesByItem)
    }

    private var risers: [StatsEngine.RiserResult] {
        let timelines: [StatsEngine.ItemTimeline] = items.compactMap { item in
            let sorted = item.recordedEntries.sorted { $0.date < $1.date }
            guard let oldest = sorted.first, let newest = sorted.last, oldest.date != newest.date else { return nil }
            return StatsEngine.ItemTimeline(itemName: item.name, oldestUnitPrice: oldest.unitPrice, oldestDate: oldest.date,
                                             newestUnitPrice: newest.unitPrice, newestDate: newest.date)
        }
        return StatsEngine.biggestRisers(timelines: timelines)
    }

    private var storeRanking: [StatsEngine.StoreRankingResult] {
        var prices: [StatsEngine.StoreItemPrice] = []
        for item in items {
            let entries = item.recordedEntries
            guard let median = VerdictEngine.median(of: entries.map(\.unitPrice)) else { continue }
            let byStore = Dictionary(grouping: entries, by: { $0.store?.name ?? "" })
            for (storeName, storeEntries) in byStore where !storeName.isEmpty {
                if let best = storeEntries.map(\.unitPrice).min() {
                    prices.append(StatsEngine.StoreItemPrice(storeName: storeName, itemMedianUnitPrice: median, unitPriceAtStore: best))
                }
            }
        }
        return StatsEngine.cheapestStore(prices: prices)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("stats.monthlyBasket") {
                    if monthlyBasket.isEmpty {
                        notEnoughData("stats.monthlyBasket.empty")
                    } else {
                        Chart(monthlyBasket) { point in
                            BarMark(x: .value("stats.monthlyBasket.month", point.month, unit: .month),
                                    y: .value("stats.monthlyBasket.total", NSDecimalNumber(decimal: point.total).doubleValue))
                        }
                        .frame(height: 160)
                        .accessibilityIdentifier("stats.monthlyBasket.chart")
                    }
                }

                Section("stats.totalSaved") {
                    if savings.contributingEntryCount == 0 {
                        notEnoughData("stats.totalSaved.empty")
                    } else {
                        Text(PriceFormatting.currencyAmount(savings.totalSaved, symbol: settings.currencySymbol))
                            .font(.system(.title, design: .monospaced))
                            .foregroundStyle(savings.totalSaved >= 0 ? .green : .red)
                            .accessibilityIdentifier("stats.totalSaved.value")
                    }
                }

                Section("stats.biggestRisers") {
                    if risers.isEmpty {
                        notEnoughData("stats.biggestRisers.empty")
                    } else {
                        ForEach(risers) { riser in
                            HStack {
                                Text(riser.itemName)
                                Spacer()
                                Text(PriceFormatting.percent(riser.percentChange)).foregroundStyle(.red)
                            }
                            .accessibilityIdentifier("stats.risers.\(riser.itemName)")
                        }
                    }
                }

                Section("stats.cheapestStore") {
                    if storeRanking.isEmpty {
                        notEnoughData("stats.cheapestStore.empty")
                    } else if let cheapest = storeRanking.first {
                        Text(cheapest.storeName)
                            .font(.headline)
                            .accessibilityIdentifier("stats.cheapestStore.name")
                    }
                }
            }
            .navigationTitle("tab.stats")
            .accessibilityIdentifier("stats.list")
        }
        .pjBannerFooter()
    }

    private func notEnoughData(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("\(key).notEnoughData")
    }
}
