import XCTest
@testable import PriceJar

final class VerdictEngineTests: XCTestCase {
    private func d(_ s: String) -> Decimal { Decimal(string: s)! }

    private func point(_ price: String, store: String = "Store", daysAgo: Int = 0) -> VerdictHistoryPoint {
        VerdictHistoryPoint(unitPrice: d(price), storeName: store, date: Date(timeIntervalSince1970: TimeInterval(-daysAgo * 86400)))
    }

    // MARK: - Not enough data

    func testFewerThanThreeEntriesIsNotEnoughData() {
        let history = [point("1.00"), point("1.10")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.00"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .notEnoughData)
        XCTAssertEqual(result.historyCount, 2)
        XCTAssertNil(result.medianUnitPrice)
    }

    func testZeroHistoryIsNotEnoughDataAndReportsNoBest() {
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.00"), packageBaseQuantity: 1, history: [])
        XCTAssertEqual(result.verdict, .notEnoughData)
        XCTAssertNil(result.bestUnitPrice)
    }

    func testExactlyThreeEntriesIsEnoughData() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.00"), packageBaseQuantity: 1, history: history)
        XCTAssertNotEqual(result.verdict, .notEnoughData)
    }

    // MARK: - BEST boundary: at or within 0.5% of the lowest recorded

    func testCandidateEqualToBestIsBest() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.00"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .best)
    }

    func testCandidateAtExactlyHalfPercentAboveBestIsBest() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        // 1.00 * 1.005 = 1.005, exactly at the tolerance boundary.
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.005"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .best)
    }

    func testCandidateJustAboveHalfPercentToleranceIsNotBest() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.0051"), packageBaseQuantity: 1, history: history)
        XCTAssertNotEqual(result.verdict, .best)
    }

    func testCandidateBelowBestIsStillBest() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("0.50"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .best)
    }

    // MARK: - TYPICAL boundary: at or below median x 1.10

    func testCandidateAtMedianIsTypical() {
        // History 1.00, 1.10, 1.20 -> median 1.10. Use a candidate clearly
        // above the best tolerance but at the median itself.
        let history = [point("1.00"), point("1.10"), point("1.20")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.10"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .typical)
        XCTAssertEqual(result.medianUnitPrice, d("1.10"))
    }

    func testCandidateAtExactlyMedianTimes110IsTypical() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        // median 1.10 * 1.10 = 1.21 exactly.
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.21"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .typical)
    }

    func testCandidateJustAboveMedianTimes110IsAboveUsual() {
        let history = [point("1.00"), point("1.10"), point("1.20")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.2101"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.verdict, .aboveYourUsual)
    }

    func testMedianOfEvenCountAveragesTheMiddleTwo() {
        let history = [point("1.00"), point("2.00"), point("3.00"), point("4.00")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("2.50"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.medianUnitPrice, d("2.50"))
    }

    func testMedianHelperOddCount() {
        XCTAssertEqual(VerdictEngine.median(of: [d("3"), d("1"), d("2")]), d("2"))
    }
    func testMedianHelperEvenCount() {
        XCTAssertEqual(VerdictEngine.median(of: [d("1"), d("2"), d("3"), d("4")]), d("2.5"))
    }
    func testMedianHelperEmpty() {
        XCTAssertNil(VerdictEngine.median(of: []))
    }

    // MARK: - Difference reporting

    func testDifferenceAmountScalesToThePackageInHand() {
        let history = [point("1.00"), point("1.00"), point("1.00")]
        // Candidate 2.00/unit, package is 2 base units -> paying 4.00 for
        // something whose median cost would have been 2.00: a 2.00 difference.
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("2.00"), packageBaseQuantity: 2, history: history)
        XCTAssertEqual(result.differenceAmount, 2)
    }

    func testDifferencePercentIsPositiveWhenAboveMedian() {
        let history = [point("1.00"), point("1.00"), point("1.00")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.50"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.differencePercent, 50)
    }

    func testDifferencePercentIsNegativeWhenBelowMedian() {
        let history = [point("2.00"), point("2.00"), point("2.00")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.00"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.differencePercent, -50)
    }

    func testBestStoreNameAndDateAreReported() {
        let history = [point("1.00", store: "Aldi", daysAgo: 10), point("1.10", store: "Lidl"), point("1.20", store: "Tesco")]
        let result = VerdictEngine.evaluate(candidateUnitPrice: d("1.00"), packageBaseQuantity: 1, history: history)
        XCTAssertEqual(result.bestStoreName, "Aldi")
        XCTAssertNotNil(result.bestDate)
    }
}
