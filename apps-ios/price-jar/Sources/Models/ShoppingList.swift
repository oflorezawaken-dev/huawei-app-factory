import Foundation
import SwiftData

/// PriceJar keeps exactly one active shopping list at a time (a new trip
/// starts from it and it is cleared afterwards), but it is still its own
/// model so entries have somewhere stable to hang off and so a future
/// version could support more than one without a migration.
@Model
final class ShoppingList {
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ShoppingListEntry.list)
    var entries: [ShoppingListEntry] = []

    init(createdAt: Date = .now) {
        self.createdAt = createdAt
    }
}

@Model
final class ShoppingListEntry {
    var list: ShoppingList?
    var item: Item?
    /// Set when the row was typed in free-text rather than picked from the
    /// price book; such rows never contribute to the priced estimate.
    var freeTextName: String
    var quantity: Decimal
    var createdAt: Date

    init(list: ShoppingList?, item: Item?, freeTextName: String = "", quantity: Decimal = 1,
         createdAt: Date = .now) {
        self.list = list
        self.item = item
        self.freeTextName = freeTextName
        self.quantity = quantity
        self.createdAt = createdAt
    }

    var displayName: String {
        item?.name ?? freeTextName
    }
}
