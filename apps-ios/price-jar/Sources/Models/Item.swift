import Foundation
import SwiftData

@Model
final class Item {
    var name: String
    var brand: String
    var categoryRaw: String
    var defaultPackageSize: Decimal
    var defaultUnitRaw: String
    var preferredDisplayUnitRaw: String
    var barcode: String?
    @Attribute(.externalStorage) var photoData: Data?
    /// Sample-data items are badged "Sample", excluded from Stats and CSV,
    /// and removable in one Settings action that never touches user rows.
    var isSample: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PriceEntry.item)
    var priceEntries: [PriceEntry] = []

    init(name: String, brand: String = "", category: ItemCategory = .other,
         defaultPackageSize: Decimal = 1, defaultUnit: MeasurementUnit = .item,
         preferredDisplayUnit: DisplayUnit = .perItem, barcode: String? = nil,
         photoData: Data? = nil, isSample: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.defaultPackageSize = defaultPackageSize
        self.defaultUnitRaw = defaultUnit.rawValue
        self.preferredDisplayUnitRaw = preferredDisplayUnit.rawValue
        self.barcode = barcode
        self.photoData = photoData
        self.isSample = isSample
        self.createdAt = createdAt
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var defaultUnit: MeasurementUnit {
        get { MeasurementUnit(rawValue: defaultUnitRaw) ?? .item }
        set { defaultUnitRaw = newValue.rawValue }
    }

    var preferredDisplayUnit: DisplayUnit {
        get { DisplayUnit(rawValue: preferredDisplayUnitRaw) ?? .perItem }
        set { preferredDisplayUnitRaw = newValue.rawValue }
    }

    /// The dimension (mass / volume / count) every price entry for this item
    /// must share. Entries in a different dimension are rejected at entry time.
    var dimension: MeasurementUnit.Dimension { defaultUnit.dimension }

    /// Non-sample entries only, newest first -- the list most screens want.
    var recordedEntries: [PriceEntry] {
        priceEntries.filter { !$0.isSample }.sorted { $0.date > $1.date }
    }

    /// The lowest unit price ever recorded for this item, and where.
    var bestEntry: PriceEntry? {
        priceEntries.min { $0.unitPrice < $1.unitPrice }
    }
}
