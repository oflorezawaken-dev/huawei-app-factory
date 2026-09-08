import XCTest
@testable import PriceJar

final class StatsEngineTests: XCTestCase {
    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testMonthlyBasketGroupsBySameMonth() {
        let trips: [(date: Date, total: Decimal)] = [
            (date(2026, 3, 2), 40), (date(2026, 3, 20), 25), (date(2026, 4, 1), 50),
        ]
        let points = StatsEngine.monthlyBasket(trips: trips, calendar: utc)
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].total, 65)
        XCTAssertEqual(points[1].total, 50)
    }

    func testMonthlyBasketWithNoTripsIsEmpty() {
        XCTAssertTrue(StatsEngine.monthlyBasket(trips: [], calendar: utc).isEmpty)
    }

    func testTotalSavedIgnoresItemsWithFewerThanThreeEntries() {
        let entriesByItem = [[
            StatsEngine.EntryPoint(unitPrice: 1, baseQuantity: 1),
            StatsEngine.EntryPoint(unitPrice: 2, baseQuantity: 1),
        ]]
        let result = StatsEngine.totalSaved(entriesByItem: entriesByItem)
        XCTAssertEqual(result.contributingEntryCount, 0)
        XCTAssertEqual(result.totalSaved, 0)
    }

    func testTotalSavedSumsPositiveAndNegativeContributions() {
        // Median of [1, 1, 1] is 1. Paying 0.50 (saved 0.50) and 1.50 (lost 0.50) nets to zero.
        let entriesByItem = [[
            StatsEngine.EntryPoint(unitPrice: 1, baseQuantity: 1),
            StatsEngine.EntryPoint(unitPrice: 1, baseQuantity: 1),
            StatsEngine.EntryPoint(unitPrice: 1, baseQuantity: 1),
            StatsEngine.EntryPoint(unitPrice: Decimal(string: "0.50")!, baseQuantity: 1),
            StatsEngine.EntryPoint(unitPrice: Decimal(string: "1.50")!, baseQuantity: 1),
        ]]
        let result = StatsEngine.totalSaved(entriesByItem: entriesByItem)
        XCTAssertEqual(result.totalSaved, 0)
        XCTAssertEqual(result.contributingEntryCount, 5)
    }

    func testBiggestRisersRequiresMinimumSpan() {
        let timelines = [
            StatsEngine.ItemTimeline(itemName: "Too recent", oldestUnitPrice: 1, oldestDate: date(2026, 8, 1),
                                      newestUnitPrice: 2, newestDate: date(2026, 8, 15)),
        ]
        XCTAssertTrue(StatsEngine.biggestRisers(timelines: timelines).isEmpty)
    }

    func testBiggestRisersSortsDescendingAndExcludesFallers() {
        let timelines = [
            StatsEngine.ItemTimeline(itemName: "Big riser", oldestUnitPrice: 1, oldestDate: date(2026, 1, 1),
                                      newestUnitPrice: 2, newestDate: date(2026, 9, 1)),
            StatsEngine.ItemTimeline(itemName: "Small riser", oldestUnitPrice: 1, oldestDate: date(2026, 1, 1),
                                      newestUnitPrice: Decimal(string: "1.10")!, newestDate: date(2026, 9, 1)),
            StatsEngine.ItemTimeline(itemName: "Faller", oldestUnitPrice: 2, oldestDate: date(2026, 1, 1),
                                      newestUnitPrice: 1, newestDate: date(2026, 9, 1)),
        ]
        let risers = StatsEngine.biggestRisers(timelines: timelines)
        XCTAssertEqual(risers.map(\.itemName), ["Big riser", "Small riser"])
        XCTAssertEqual(risers[0].percentChange, 100)
    }

    func testBiggestRisersRespectsLimit() {
        let timelines = (0..<10).map { index in
            StatsEngine.ItemTimeline(itemName: "Item \(index)", oldestUnitPrice: 1, oldestDate: date(2026, 1, 1),
                                      newestUnitPrice: Decimal(1 + index), newestDate: date(2026, 9, 1))
        }
        XCTAssertEqual(StatsEngine.biggestRisers(timelines: timelines, limit: 5).count, 5)
    }

    func testCheapestStoreRanksByIndexRelativeToItemMedian() {
        let prices = [
            StatsEngine.StoreItemPrice(storeName: "Aldi", itemMedianUnitPrice: 1, unitPriceAtStore: Decimal(string: "0.90")!),
            StatsEngine.StoreItemPrice(storeName: "Tesco", itemMedianUnitPrice: 1, unitPriceAtStore: Decimal(string: "1.20")!),
        ]
        let ranking = StatsEngine.cheapestStore(prices: prices)
        XCTAssertEqual(ranking.first?.storeName, "Aldi")
    }

    func testCheapestStoreIgnoresZeroMedianToAvoidDivideByZero() {
        let prices = [StatsEngine.StoreItemPrice(storeName: "Aldi", itemMedianUnitPrice: 0, unitPriceAtStore: 1)]
        XCTAssertTrue(StatsEngine.cheapestStore(prices: prices).isEmpty)
    }

    func testCheapestStoreAveragesAcrossMultipleItems() {
        let prices = [
            StatsEngine.StoreItemPrice(storeName: "Aldi", itemMedianUnitPrice: 1, unitPriceAtStore: 1),
            StatsEngine.StoreItemPrice(storeName: "Aldi", itemMedianUnitPrice: 1, unitPriceAtStore: Decimal(string: "0.50")!),
        ]
        let ranking = StatsEngine.cheapestStore(prices: prices)
        XCTAssertEqual(ranking.first?.averageIndex, Decimal(string: "0.75"))
    }
}
