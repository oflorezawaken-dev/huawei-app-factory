import Foundation

/// One line of a planned basket: how many of an item's default package the
/// shopper wants, and the best (lowest) unit price found for it at a
/// candidate store, if any price has ever been recorded there.
struct BasketLine: Sendable {
    let quantity: Decimal
    let defaultPackageSize: Decimal
    let defaultUnit: MeasurementUnit
    let bestUnitPriceAtStore: Decimal?
}

/// Estimates what a basket costs at one store, and -- just as importantly --
/// how much of the basket that estimate is actually based on. Coverage is
/// never overstated: an item with no recorded price at the store simply does
/// not contribute to `pricedCount`, even though it still counts toward
/// `totalCount`.
enum BasketEstimator {
    struct Result: Equatable, Sendable {
        let estimatedTotal: Decimal
        let pricedCount: Int
        let totalCount: Int
    }

    static func estimate(lines: [BasketLine]) -> Result {
        var total: Decimal = 0
        var priced = 0
        for line in lines {
            guard let unitPrice = line.bestUnitPriceAtStore else { continue }
            let baseQuantity = UnitNormalization.baseQuantity(
                packageSize: line.quantity * line.defaultPackageSize, unit: line.defaultUnit)
            total += unitPrice * baseQuantity
            priced += 1
        }
        return Result(estimatedTotal: UnitNormalization.rounded(total, scale: 2),
                       pricedCount: priced, totalCount: lines.count)
    }
}
