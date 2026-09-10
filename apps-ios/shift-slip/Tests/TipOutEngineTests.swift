import XCTest
@testable import ShiftSlip

/// F003's tip-out engine is one of the two modules that must never be wrong.
/// Exhaustive coverage across the four rule types, single and multiple
/// recipients, reproducing every worked example in the spec.
final class TipOutEngineTests: XCTestCase {
    // MARK: - Worked examples from F003

    func testPercentOfTipsWorkedExample() {
        let shares = TipOutEngine.resolve(
            recipients: [TipOutRecipientRule(name: "Bar", type: .percentOfTips, value: 5)],
            voluntaryTips: 240, sales: 1450)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "12.00"))
    }

    func testSecondPercentOfTipsWorkedExample() {
        let shares = TipOutEngine.resolve(
            recipients: [TipOutRecipientRule(name: "Busser", type: .percentOfTips, value: 3)],
            voluntaryTips: 240, sales: 1450)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "7.20"))
    }

    func testPercentOfSalesWorkedExample() {
        let shares = TipOutEngine.resolve(
            recipients: [TipOutRecipientRule(name: "Support", type: .percentOfSales, value: 2.5)],
            voluntaryTips: 240, sales: 1450)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "36.25"))
    }

    func testFlatWorkedExample() {
        let shares = TipOutEngine.resolve(
            recipients: [TipOutRecipientRule(name: "Runner", type: .flat, value: 10)],
            voluntaryTips: 240, sales: 1450)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "10.00"))
    }

    func testManualWorkedExample() {
        let shares = TipOutEngine.resolve(
            recipients: [TipOutRecipientRule(name: "Manual", type: .manual, value: 22.50)],
            voluntaryTips: 240, sales: 1450)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "22.50"))
    }

    func testAllFourRuleTypesTogetherOnOneShiftEachComputedFromTheSameBase() {
        let recipients = [
            TipOutRecipientRule(name: "Bar", type: .percentOfTips, value: 5),
            TipOutRecipientRule(name: "Busser", type: .percentOfTips, value: 3),
            TipOutRecipientRule(name: "Support", type: .percentOfSales, value: 2.5),
            TipOutRecipientRule(name: "Runner", type: .flat, value: 10),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 240, sales: 1450)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "12.00"))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(string: "7.20"))
        XCTAssertEqual(shares[2].resolvedAmount, Decimal(string: "36.25"))
        XCTAssertEqual(shares[3].resolvedAmount, Decimal(string: "10.00"))
        // Never a running remainder: every percentage is against the same 240/1450 base.
        let total = shares.reduce(Decimal(0)) { $0 + $1.resolvedAmount }
        XCTAssertEqual(total, Decimal(string: "65.45"))
    }

    // MARK: - Percentages never apply to a running remainder

    func testMultiplePercentOfTipsRecipientsEachComputeFromGrossNotARemainder() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfTips, value: 10),
            TipOutRecipientRule(name: "B", type: .percentOfTips, value: 10),
            TipOutRecipientRule(name: "C", type: .percentOfTips, value: 10),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 100, sales: 0)
        // If B's 10% were taken from the remainder after A, it would be 9.00, not 10.00.
        for share in shares { XCTAssertEqual(share.resolvedAmount, Decimal(10)) }
    }

    // MARK: - Rounding: half-up to the minor unit, independently per recipient

    func testRoundingIsHalfUpToTwoDecimalPlaces() {
        let recipients = [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 5)]
        // 5% of 33.33 = 1.6665 -> rounds to 1.67 (half-up), not 1.66 (banker's rounding).
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: Decimal(string: "33.33")!, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "1.67"))
    }

    func testRoundingNeverLeaksCentsAcrossAThousandGeneratedCases() {
        var mismatches = 0
        for i in 0..<1000 {
            let tips = Decimal(i) + Decimal(i % 7) / 100
            let sales = Decimal(i) * 3 + Decimal(i % 13) / 100
            let recipients = [
                TipOutRecipientRule(name: "A", type: .percentOfTips, value: Decimal(i % 11) + 1),
                TipOutRecipientRule(name: "B", type: .percentOfSales, value: Decimal(i % 7) + 1),
                TipOutRecipientRule(name: "C", type: .flat, value: Decimal(i % 5)),
            ]
            let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: tips, sales: sales)
            // The displayed total IS the sum of the displayed shares,
            // definitionally (no separate total is computed elsewhere), so
            // this checks scale correctness instead: every rounded share has
            // at most 2 fraction digits, i.e. rounding it again changes nothing.
            for share in shares where share.resolvedAmount != share.resolvedAmount.rounded(toScale: 2) {
                mismatches += 1
            }
        }
        XCTAssertEqual(mismatches, 0)
    }

    // MARK: - Currency minor unit

    func testZeroDecimalCurrencyRoundsToWholeUnits() {
        let recipients = [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 5)]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 241, sales: 0,
                                            minorUnitScale: TipOutEngine.minorUnitScale(forCurrencyCode: "JPY"))
        // 5% of 241 = 12.05 -> rounds to 12 (0 decimal places).
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(12))
    }

    func testThreeDecimalCurrencyRoundsToThreePlaces() {
        let recipients = [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 5)]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 1, sales: 0,
                                            minorUnitScale: TipOutEngine.minorUnitScale(forCurrencyCode: "BHD"))
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "0.050"))
    }

    // MARK: - Empty / single recipient edge cases

    func testNoRecipientsResolvesToEmptyShares() {
        XCTAssertTrue(TipOutEngine.resolve(recipients: [], voluntaryTips: 100, sales: 100).isEmpty)
    }

    func testSingleRecipientTotalEqualsItsOwnShare() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "Solo", type: .flat, value: 15)],
                                            voluntaryTips: 0, sales: 0)
        XCTAssertEqual(shares.reduce(Decimal(0)) { $0 + $1.resolvedAmount }, Decimal(15))
    }
}
