import Foundation
import SwiftData

@Model
final class PriceEntry {
    var item: Item?
    var store: Store?
    var price: Decimal
    var packageSize: Decimal
    var unitRaw: String
    var date: Date
    var isSale: Bool
    var isLoyalty: Bool
    var isSample: Bool
    var createdAt: Date

    init(item: Item?, store: Store?, price: Decimal, packageSize: Decimal, unit: MeasurementUnit,
         date: Date = .now, isSale: Bool = false, isLoyalty: Bool = false, isSample: Bool = false,
         createdAt: Date = .now) {
        self.item = item
        self.store = store
        self.price = price
        self.packageSize = packageSize
        self.unitRaw = unit.rawValue
        self.date = date
        self.isSale = isSale
        self.isLoyalty = isLoyalty
        self.isSample = isSample
        self.createdAt = createdAt
    }

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .item }
        set { unitRaw = newValue.rawValue }
    }

    /// The base-unit price (per gram / per millilitre / per item), computed
    /// through the normalisation engine every time it is read rather than
    /// cached, so it can never drift from the recorded price and size.
    var unitPrice: Decimal {
        (try? UnitNormalization.unitPrice(price: price, packageSize: packageSize, unit: unit)) ?? 0
    }

    /// This entry's unit price expressed in the item's preferred display unit.
    var displayUnitPrice: Decimal {
        guard let item else { return unitPrice }
        return UnitNormalization.displayUnitPrice(baseUnitPrice: unitPrice, displayUnit: item.preferredDisplayUnit)
    }

    /// Whether this entry counts toward the "typical price" baseline, honouring
    /// the settings toggle for sale/loyalty prices.
    func countsTowardTypical(includeSaleAndLoyalty: Bool) -> Bool {
        includeSaleAndLoyalty || (!isSale && !isLoyalty)
    }
}
