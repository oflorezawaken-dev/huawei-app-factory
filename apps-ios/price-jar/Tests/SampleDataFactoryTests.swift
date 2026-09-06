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
}
