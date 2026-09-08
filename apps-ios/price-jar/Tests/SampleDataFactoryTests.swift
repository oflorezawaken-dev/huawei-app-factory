import SwiftData
import XCTest
@testable import PriceJar

@MainActor
final class SampleDataFactoryTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Item.self, Store.self, PriceEntry.self, ShoppingList.self, ShoppingListEntry.self, Trip.self, TripEntry.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    func testLoadsExactlyTwelveItemsInOneDemoStore() throws {
        let context = try makeContext()
        SampleDataFactory.load(into: context)

        let items = try context.fetch(FetchDescriptor<Item>())
        let stores = try context.fetch(FetchDescriptor<Store>())
        XCTAssertEqual(items.count, 12)
        XCTAssertEqual(stores.count, 1)
        XCTAssertTrue(items.allSatisfy(\.isSample))
        XCTAssertTrue(stores.allSatisfy(\.isSample))
    }

    func testEveryPriceEntryIsFlaggedSample() throws {
        let context = try makeContext()
        SampleDataFactory.load(into: context)
        let entries = try context.fetch(FetchDescriptor<PriceEntry>())
        XCTAssertFalse(entries.isEmpty)
        XCTAssertTrue(entries.allSatisfy(\.isSample))
    }

    func testRemoveSampleDataDeletesExactlyTheSampleRowsAndKeepsUserRows() throws {
        let context = try makeContext()
        SampleDataFactory.load(into: context)

        let userStore = Store(name: "My Corner Shop")
        context.insert(userStore)
        let userItem = Item(name: "My Own Item", defaultUnit: .item)
        context.insert(userItem)
        let userEntry = PriceEntry(item: userItem, store: userStore, price: 5, packageSize: 1, unit: .item)
        context.insert(userEntry)

        SampleDataFactory.removeAll(from: context)

        let items = try context.fetch(FetchDescriptor<Item>())
        let stores = try context.fetch(FetchDescriptor<Store>())
        let entries = try context.fetch(FetchDescriptor<PriceEntry>())

        XCTAssertEqual(items.map(\.name), ["My Own Item"])
        XCTAssertEqual(stores.map(\.name), ["My Corner Shop"])
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.price, 5)
    }

    func testRemoveSampleDataIsSafeToCallWithNoSampleDataPresent() throws {
        let context = try makeContext()
        XCTAssertNoThrow(SampleDataFactory.removeAll(from: context))
    }

    /// The seeded history must be in the PAST. It was inserted with
    /// `byAdding: .day, value: point.daysAgo`, which dates every sample price
    /// into the future: the verdict then saw one entry instead of three, the
    /// chart plotted dates that had not happened, and the screenshot test
    /// failed at a different assertion on every run depending on which
    /// entries fell inside the window.
    @MainActor
    func testSeededHistoryIsAlwaysInThePast() throws {
        let container = try ModelContainer(
            for: Schema([Item.self, Store.self, PriceEntry.self,
                         ShoppingList.self, ShoppingListEntry.self, Trip.self, TripEntry.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let now = Date()
        SampleDataFactory.load(into: context, now: now)

        let entries = try context.fetch(FetchDescriptor<PriceEntry>())
        XCTAssertFalse(entries.isEmpty, "seeding produced no price entries at all")
        for entry in entries {
            XCTAssertLessThanOrEqual(entry.date, now,
                                     "sample price dated in the future: \(entry.date) > \(now)")
        }
    }

    /// Each sample item keeps its full seeded history, which is what the
    /// verdict and the trend chart are demonstrated with.
    @MainActor
    func testEachSampleItemKeepsEveryHistoryPoint() throws {
        let container = try ModelContainer(
            for: Schema([Item.self, Store.self, PriceEntry.self,
                         ShoppingList.self, ShoppingListEntry.self, Trip.self, TripEntry.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        SampleDataFactory.load(into: context)

        let bananas = try context.fetch(FetchDescriptor<Item>(
            predicate: #Predicate { $0.name == "Bananas" })).first
        let item = try XCTUnwrap(bananas, "the sample set should contain Bananas")
        XCTAssertEqual(item.priceEntries.count, 3,
                       "Bananas is seeded with three prices; a lower count means entries were dropped")
    }
}
