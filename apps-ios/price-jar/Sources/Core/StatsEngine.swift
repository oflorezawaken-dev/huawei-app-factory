import Foundation

/// Pure statistics derived only from the user's own recorded entries -- no
/// benchmarks, no external data, no predictions (F009). Kept separate from
/// SwiftData so every figure can be unit tested against a fixed fixture.
enum StatsEngine {
    struct MonthlyBasketPoint: Identifiable, Equatable, Sendable {
        let month: Date
        let total: Decimal
        var id: Date { month }
    }

    static func monthlyBasket(trips: [(date: Date, total: Decimal)],
                               calendar: Calendar = Calendar(identifier: .gregorian)) -> [MonthlyBasketPoint] {
        var totals: [DateComponents: Decimal] = [:]
        for trip in trips {
            let comps = calendar.dateComponents([.year, .month], from: trip.date)
            totals[comps, default: 0] += trip.total
        }
        return totals.compactMap { comps, total in
            calendar.date(from: comps).map { MonthlyBasketPoint(month: $0, total: total) }
        }.sorted { $0.month < $1.month }
    }

    struct EntryPoint {
        let unitPrice: Decimal
        let baseQuantity: Decimal
    }

    struct SavingsResult: Equatable, Sendable {
        let totalSaved: Decimal
        let contributingEntryCount: Int
    }

    /// Sum, across every item with at least three recorded entries, of
    /// (that item's median unit price - the price actually paid) x the
    /// quantity bought, for every entry. Positive means money saved against
    /// the item's own typical price; negative contributions are not dropped.
    static func totalSaved(entriesByItem: [[EntryPoint]]) -> SavingsResult {
        var total: Decimal = 0
        var count = 0
        for entries in entriesByItem {
            guard entries.count >= 3, let median = VerdictEngine.median(of: entries.map(\.unitPrice)) else { continue }
            for entry in entries {
                total += (median - entry.unitPrice) * entry.baseQuantity
                count += 1
            }
        }
        return SavingsResult(totalSaved: UnitNormalization.rounded(total, scale: 2), contributingEntryCount: count)
    }

    struct ItemTimeline {
        let itemName: String
        let oldestUnitPrice: Decimal
        let oldestDate: Date
        let newestUnitPrice: Decimal
        let newestDate: Date
    }

    struct RiserResult: Identifiable, Equatable, Sendable {
        let itemName: String
        let percentChange: Decimal
        var id: String { itemName }
    }

    /// Items whose unit price rose most over at least `minimumDays` of
    /// history, highest riser first.
    static func biggestRisers(timelines: [ItemTimeline], minimumDays: Int = 150, limit: Int = 5) -> [RiserResult] {
        let minimumSpan = TimeInterval(minimumDays) * 86400
        let risers: [RiserResult] = timelines.compactMap { timeline in
            guard timeline.oldestUnitPrice > 0,
                  timeline.newestDate.timeIntervalSince(timeline.oldestDate) >= minimumSpan else { return nil }
            let percent = UnitNormalization.rounded(
                ((timeline.newestUnitPrice - timeline.oldestUnitPrice) / timeline.oldestUnitPrice) * 100, scale: 1)
            return RiserResult(itemName: timeline.itemName, percentChange: percent)
        }
        return risers.filter { $0.percentChange > 0 }
            .sorted { $0.percentChange > $1.percentChange }
            .prefix(limit)
            .map { $0 }
    }

    struct StoreItemPrice {
        let storeName: String
        let itemMedianUnitPrice: Decimal
        let unitPriceAtStore: Decimal
    }

    struct StoreRankingResult: Identifiable, Equatable, Sendable {
        let storeName: String
        /// Average of (price at this store / item's own median price) across
        /// every item with a recorded price there; below 1 means "usually
        /// cheaper than typical for what you buy here".
        let averageIndex: Decimal
        var id: String { storeName }
    }

    /// Ranks stores by how they compare to each item's own median price, so a
    /// store is not penalised just for stocking pricier items -- it is judged
    /// on whether it beats the user's own typical price for what they buy.
    static func cheapestStore(prices: [StoreItemPrice]) -> [StoreRankingResult] {
        var sums: [String: (total: Decimal, count: Int)] = [:]
        for price in prices where price.itemMedianUnitPrice > 0 {
            let index = price.unitPriceAtStore / price.itemMedianUnitPrice
            let existing = sums[price.storeName] ?? (0, 0)
            sums[price.storeName] = (existing.total + index, existing.count + 1)
        }
        return sums.map { name, aggregate in
            StoreRankingResult(storeName: name,
                                averageIndex: UnitNormalization.rounded(aggregate.total / Decimal(aggregate.count), scale: 4))
        }.sorted { $0.averageIndex < $1.averageIndex }
    }
}
