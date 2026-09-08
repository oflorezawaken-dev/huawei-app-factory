import Foundation
import SwiftData

/// Builds the twelve sample items in one demo store that First Run can offer,
/// so the app is a populated tool within ten seconds instead of five empty
/// tabs. Every row it creates is flagged `isSample`, which is what lets
/// "Remove sample data" delete exactly these rows and nothing the user typed.
enum SampleDataFactory {
    /// Inserts the sample store, twelve items and a few months of price
    /// history for each into the given context. Safe to call at most once;
    /// callers check `hasCompletedFirstRun`/existing sample rows first.
    @MainActor
    static func load(into context: ModelContext, now: Date = .now) {
        let calendar = Calendar(identifier: .gregorian)
        let store = Store(name: String(localized: "sample.store.name"), note: String(localized: "sample.store.note"), isSample: true)
        context.insert(store)

        for spec in itemSpecs {
            let item = Item(name: spec.name, brand: spec.brand, category: spec.category,
                             defaultPackageSize: spec.packageSize, defaultUnit: spec.unit,
                             preferredDisplayUnit: spec.displayUnit, isSample: true)
            context.insert(item)
            for point in spec.history {
                guard let date = calendar.date(byAdding: .day, value: point.daysAgo, to: now) else { continue }
                let entry = PriceEntry(item: item, store: store, price: point.price,
                                        packageSize: spec.packageSize, unit: spec.unit,
                                        date: date, isSale: point.isSale, isLoyalty: false, isSample: true)
                context.insert(entry)
            }
        }
    }

    /// Removes every sample-flagged row (items cascade their entries; the
    /// store nullifies any reference and is then removed) without touching a
    /// single user-entered row.
    @MainActor
    static func removeAll(from context: ModelContext) {
        if let items = try? context.fetch(FetchDescriptor<Item>(predicate: #Predicate { $0.isSample })) {
            for item in items { context.delete(item) }
        }
        if let entries = try? context.fetch(FetchDescriptor<PriceEntry>(predicate: #Predicate { $0.isSample })) {
            for entry in entries { context.delete(entry) }
        }
        if let stores = try? context.fetch(FetchDescriptor<Store>(predicate: #Predicate { $0.isSample })) {
            for store in stores { context.delete(store) }
        }
    }

    private struct HistoryPoint {
        let daysAgo: Int
        let price: Decimal
        let isSale: Bool
    }

    private struct ItemSpec {
        let name: String
        let brand: String
        let category: ItemCategory
        let packageSize: Decimal
        let unit: MeasurementUnit
        let displayUnit: DisplayUnit
        let history: [HistoryPoint]
    }

    private static var itemSpecs: [ItemSpec] {
        [
            ItemSpec(name: "Whole milk", brand: "Meadow Farm", category: .dairy,
                     packageSize: 1, unit: .liter, displayUnit: .perLiter,
                     history: [.init(daysAgo: 5, price: 1.05, isSale: false),
                               .init(daysAgo: 40, price: 1.15, isSale: false),
                               .init(daysAgo: 80, price: 0.99, isSale: true)]),
            ItemSpec(name: "Free-range eggs", brand: "Sunrise", category: .dairy,
                     packageSize: 12, unit: .item, displayUnit: .perItem,
                     history: [.init(daysAgo: 3, price: 3.60, isSale: false),
                               .init(daysAgo: 35, price: 3.90, isSale: false),
                               .init(daysAgo: 70, price: 3.49, isSale: true)]),
            ItemSpec(name: "Basmati rice", brand: "Golden Fields", category: .pantry,
                     packageSize: 1, unit: .kilogram, displayUnit: .perKilogram,
                     history: [.init(daysAgo: 10, price: 2.30, isSale: false),
                               .init(daysAgo: 55, price: 2.15, isSale: false),
                               .init(daysAgo: 100, price: 2.50, isSale: false)]),
            ItemSpec(name: "Rolled oats", brand: "Golden Fields", category: .pantry,
                     packageSize: 500, unit: .gram, displayUnit: .per100Grams,
                     history: [.init(daysAgo: 8, price: 1.40, isSale: false),
                               .init(daysAgo: 60, price: 1.35, isSale: false)]),
            ItemSpec(name: "Bananas", brand: "", category: .produce,
                     packageSize: 1, unit: .kilogram, displayUnit: .perKilogram,
                     history: [.init(daysAgo: 2, price: 1.10, isSale: false),
                               .init(daysAgo: 20, price: 1.25, isSale: false),
                               .init(daysAgo: 50, price: 0.95, isSale: true)]),
            ItemSpec(name: "Tomatoes", brand: "", category: .produce,
                     packageSize: 1, unit: .kilogram, displayUnit: .perKilogram,
                     history: [.init(daysAgo: 4, price: 2.80, isSale: false),
                               .init(daysAgo: 45, price: 2.20, isSale: false)]),
            ItemSpec(name: "Chicken breast", brand: "", category: .meatAndFish,
                     packageSize: 1, unit: .kilogram, displayUnit: .perKilogram,
                     history: [.init(daysAgo: 6, price: 7.50, isSale: false),
                               .init(daysAgo: 42, price: 8.10, isSale: false),
                               .init(daysAgo: 90, price: 6.99, isSale: true)]),
            ItemSpec(name: "Sourdough loaf", brand: "Corner Bakery", category: .bakery,
                     packageSize: 800, unit: .gram, displayUnit: .per100Grams,
                     history: [.init(daysAgo: 7, price: 3.20, isSale: false),
                               .init(daysAgo: 38, price: 3.00, isSale: false)]),
            ItemSpec(name: "Ground coffee", brand: "Cusco Peak", category: .beverages,
                     packageSize: 250, unit: .gram, displayUnit: .per100Grams,
                     history: [.init(daysAgo: 12, price: 4.80, isSale: false),
                               .init(daysAgo: 65, price: 5.20, isSale: false),
                               .init(daysAgo: 110, price: 4.50, isSale: true)]),
            ItemSpec(name: "Orange juice", brand: "Sunrise", category: .beverages,
                     packageSize: 1, unit: .liter, displayUnit: .perLiter,
                     history: [.init(daysAgo: 9, price: 2.10, isSale: false),
                               .init(daysAgo: 48, price: 1.95, isSale: false)]),
            ItemSpec(name: "Dish soap", brand: "CleanHome", category: .household,
                     packageSize: 750, unit: .milliliter, displayUnit: .per100Milliliters,
                     history: [.init(daysAgo: 15, price: 2.40, isSale: false),
                               .init(daysAgo: 75, price: 2.60, isSale: false)]),
            ItemSpec(name: "Shampoo", brand: "Meadow", category: .personalCare,
                     packageSize: 400, unit: .milliliter, displayUnit: .per100Milliliters,
                     history: [.init(daysAgo: 18, price: 4.20, isSale: false),
                               .init(daysAgo: 90, price: 4.60, isSale: false),
                               .init(daysAgo: 130, price: 3.99, isSale: true)]),
        ]
    }
}
