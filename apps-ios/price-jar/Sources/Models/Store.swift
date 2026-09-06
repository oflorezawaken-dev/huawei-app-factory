import Foundation
import SwiftData

@Model
final class Store {
    var name: String
    var note: String
    /// The one demo store sample data lives in; excluded the same way sample
    /// items and entries are.
    var isSample: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \PriceEntry.store)
    var priceEntries: [PriceEntry] = []

    init(name: String, note: String = "", isSample: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.note = note
        self.isSample = isSample
        self.createdAt = createdAt
    }

    var recordedEntryCount: Int {
        priceEntries.filter { !$0.isSample }.count
    }
}
