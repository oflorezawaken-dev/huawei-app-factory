import XCTest
@testable import PriceJar

final class BasketEstimatorTests: XCTestCase {
    func testCoverageIsNeverOverstatedWhenSomeItemsHaveNoPrice() {
        let lines = [
            BasketLine(quantity: 1, defaultPackageSize: 1, defaultUnit: .kilogram, bestUnitPriceAtStore: Decimal(string: "0.002")),
            BasketLine(quantity: 2, defaultPackageSize: 1, defaultUnit: .liter, bestUnitPriceAtStore: nil),
            BasketLine(quantity: 1, defaultPackageSize: 1, defaultUnit: .item, bestUnitPriceAtStore: Decimal(string: "1.50")),
        ]
        let result = BasketEstimator.estimate(lines: lines)
        XCTAssertEqual(result.totalCount, 3)
        XCTAssertEqual(result.pricedCount, 2, "the item with no recorded price must not be counted as priced")
    }

    func testEstimateOnlySumsPricedLines() {
        let lines = [
            BasketLine(quantity: 2, defaultPackageSize: 1, defaultUnit: .kilogram, bestUnitPriceAtStore: Decimal(string: "0.002")),
            BasketLine(quantity: 1, defaultPackageSize: 500, defaultUnit: .gram, bestUnitPriceAtStore: nil),
        ]
        let result = BasketEstimator.estimate(lines: lines)
        // 2 kg at 0.002/g base price = 2000g * 0.002 = 4.00
        XCTAssertEqual(result.estimatedTotal, Decimal(string: "4.00"))
    }

    func testEmptyBasketHasZeroTotalAndZeroCounts() {
        let result = BasketEstimator.estimate(lines: [])
        XCTAssertEqual(result.estimatedTotal, 0)
        XCTAssertEqual(result.pricedCount, 0)
        XCTAssertEqual(result.totalCount, 0)
    }

    func testFullyPricedBasketReportsFullCoverage() {
        let lines = [
            BasketLine(quantity: 1, defaultPackageSize: 1, defaultUnit: .item, bestUnitPriceAtStore: 1),
            BasketLine(quantity: 1, defaultPackageSize: 1, defaultUnit: .item, bestUnitPriceAtStore: 2),
        ]
        let result = BasketEstimator.estimate(lines: lines)
        XCTAssertEqual(result.pricedCount, result.totalCount)
    }

    func testQuantityMultipliesThePackageSize() {
        let lines = [BasketLine(quantity: 3, defaultPackageSize: 2, defaultUnit: .item, bestUnitPriceAtStore: 1)]
        let result = BasketEstimator.estimate(lines: lines)
        // 3 x 2 items at 1/item = 6.00
        XCTAssertEqual(result.estimatedTotal, 6)
    }
}
