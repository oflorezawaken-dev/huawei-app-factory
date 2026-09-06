import Foundation

/// The three answers to "is this a good price?", plus the honest fourth
/// state for when there is not enough history to answer at all.
enum Verdict: String, Equatable, Sendable {
    case best
    case typical
    case aboveYourUsual
    case notEnoughData
}

/// One prior recorded price, reduced to what the verdict engine needs: its
/// base unit price and where/when it happened.
struct VerdictHistoryPoint: Equatable, Sendable {
    let unitPrice: Decimal
    let storeName: String
    let date: Date
}

/// The full result the "Good Price?" sheet renders.
struct VerdictResult: Equatable, Sendable {
    let verdict: Verdict
    let candidateUnitPrice: Decimal
    let historyCount: Int
    let bestUnitPrice: Decimal?
    let bestStoreName: String?
    let bestDate: Date?
    let medianUnitPrice: Decimal?
    /// Positive means the candidate is more expensive than the median; money
    /// figure is scaled to the whole package in hand, not just one base unit.
    let differenceAmount: Decimal?
    let differencePercent: Decimal?
}

/// Deterministic, pure-Swift verdict logic, isolated from SwiftData so every
/// threshold can be unit tested exactly at its boundary.
enum VerdictEngine {
    /// Fewer than this many prior entries and the engine refuses to invent a verdict.
    static let minimumHistoryCount = 3
    /// "At or within 0.5% of the lowest unit price ever recorded" counts as BEST.
    static let bestTolerance = Decimal(string: "0.005")!
    /// "At or below median x 1.10" counts as TYPICAL.
    static let typicalMultiplier = Decimal(string: "1.10")!

    static func median(of prices: [Decimal]) -> Decimal? {
        guard !prices.isEmpty else { return nil }
        let sorted = prices.sorted()
        let count = sorted.count
        if count % 2 == 1 {
            return sorted[count / 2]
        }
        return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
    }

    /// - Parameters:
    ///   - candidateUnitPrice: the base unit price of the entry being judged.
    ///   - packageBaseQuantity: the size of the package in hand, in base
    ///     units, so the money difference reflects what this package costs,
    ///     not just a per-unit rate.
    ///   - history: every other recorded unit price for this item (the
    ///     candidate itself is not included).
    static func evaluate(candidateUnitPrice: Decimal, packageBaseQuantity: Decimal,
                         history: [VerdictHistoryPoint]) -> VerdictResult {
        guard history.count >= minimumHistoryCount,
              let best = history.min(by: { $0.unitPrice < $1.unitPrice }),
              let medianPrice = median(of: history.map(\.unitPrice)) else {
            let best = history.min(by: { $0.unitPrice < $1.unitPrice })
            return VerdictResult(verdict: .notEnoughData, candidateUnitPrice: candidateUnitPrice,
                                  historyCount: history.count,
                                  bestUnitPrice: best?.unitPrice, bestStoreName: best?.storeName,
                                  bestDate: best?.date, medianUnitPrice: nil,
                                  differenceAmount: nil, differencePercent: nil)
        }

        let bestThreshold = UnitNormalization.rounded(best.unitPrice * (1 + bestTolerance), scale: 6)
        let typicalThreshold = UnitNormalization.rounded(medianPrice * typicalMultiplier, scale: 6)

        let verdict: Verdict
        if candidateUnitPrice <= bestThreshold {
            verdict = .best
        } else if candidateUnitPrice <= typicalThreshold {
            verdict = .typical
        } else {
            verdict = .aboveYourUsual
        }

        let diffAmount = (candidateUnitPrice - medianPrice) * packageBaseQuantity
        let diffPercent: Decimal = medianPrice == 0 ? 0
            : UnitNormalization.rounded(((candidateUnitPrice - medianPrice) / medianPrice) * 100, scale: 2)

        return VerdictResult(verdict: verdict, candidateUnitPrice: candidateUnitPrice,
                              historyCount: history.count,
                              bestUnitPrice: best.unitPrice, bestStoreName: best.storeName, bestDate: best.date,
                              medianUnitPrice: medianPrice,
                              differenceAmount: UnitNormalization.rounded(diffAmount, scale: 4),
                              differencePercent: diffPercent)
    }
}
