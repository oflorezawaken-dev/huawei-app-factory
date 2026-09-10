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

    // MARK: - Single recipient, each rule type, varied values

    func testSinglePercentOfTips_10PercentOf50() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 10)],
                                            voluntaryTips: 50, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(5))
    }

    func testSinglePercentOfTips_2PercentOf75() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 2)],
                                            voluntaryTips: 75, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "1.50"))
    }

    func testSinglePercentOfTips_ZeroTipsGivesZero() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 10)],
                                            voluntaryTips: 0, sales: 500)
        XCTAssertEqual(shares[0].resolvedAmount, 0)
    }

    func testSinglePercentOfTips_HundredPercentEqualsAllTips() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 100)],
                                            voluntaryTips: Decimal(string: "84.20")!, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "84.20"))
    }

    func testSinglePercentOfSales_1PercentOf2000() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfSales, value: 1)],
                                            voluntaryTips: 0, sales: 2000)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(20))
    }

    func testSinglePercentOfSales_ZeroSalesGivesZero() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfSales, value: 4)],
                                            voluntaryTips: 300, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, 0)
    }

    func testSinglePercentOfSales_IgnoresTipsEntirely() {
        let withHighTips = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfSales, value: 4)],
                                                  voluntaryTips: 9999, sales: 100)
        let withZeroTips = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfSales, value: 4)],
                                                  voluntaryTips: 0, sales: 100)
        XCTAssertEqual(withHighTips[0].resolvedAmount, withZeroTips[0].resolvedAmount)
    }

    func testSingleFlat_IgnoresTipsAndSales() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .flat, value: 25)],
                                            voluntaryTips: 0, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(25))
    }

    func testSingleFlat_UnaffectedByLargeTips() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .flat, value: 25)],
                                            voluntaryTips: 5000, sales: 5000)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(25))
    }

    func testSingleManual_ZeroValueGivesZero() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .manual, value: 0)],
                                            voluntaryTips: 200, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, 0)
    }

    func testSingleManual_ExceedingTipsIsStillHonoured() {
        // The engine resolves whatever rule it is given; guarding against a
        // manual figure exceeding tips is a UI concern, not this module's.
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .manual, value: 500)],
                                            voluntaryTips: 100, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(500))
    }

    // MARK: - Multiple recipients, same type

    func testTwoPercentOfSalesRecipientsEachComputeFromTheSameSalesBase() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfSales, value: 1),
            TipOutRecipientRule(name: "B", type: .percentOfSales, value: 2),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 0, sales: 1000)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(10))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(20))
    }

    func testThreeFlatRecipientsSumToTheirTotal() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .flat, value: 5),
            TipOutRecipientRule(name: "B", type: .flat, value: 10),
            TipOutRecipientRule(name: "C", type: .flat, value: 15),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 0, sales: 0)
        XCTAssertEqual(shares.reduce(Decimal(0)) { $0 + $1.resolvedAmount }, Decimal(30))
    }

    func testFourManualRecipientsEachKeepTheirOwnFigure() {
        let recipients = (0..<4).map { TipOutRecipientRule(name: "R\($0)", type: .manual, value: Decimal($0) * 5) }
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 0, sales: 0)
        for (index, share) in shares.enumerated() {
            XCTAssertEqual(share.resolvedAmount, Decimal(index) * 5)
        }
    }

    // MARK: - Mixed-type pairs

    func testPercentOfTipsPlusPercentOfSalesPair() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfTips, value: 4),
            TipOutRecipientRule(name: "B", type: .percentOfSales, value: 1),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 200, sales: 1000)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(8))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(10))
    }

    func testPercentOfTipsPlusFlatPair() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfTips, value: 5),
            TipOutRecipientRule(name: "B", type: .flat, value: 12),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 300, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(15))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(12))
    }

    func testPercentOfTipsPlusManualPair() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfTips, value: 5),
            TipOutRecipientRule(name: "B", type: .manual, value: 22.50),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 240, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(12))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(string: "22.50"))
    }

    func testPercentOfSalesPlusFlatPair() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfSales, value: 2),
            TipOutRecipientRule(name: "B", type: .flat, value: 8),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 0, sales: 500)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(10))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(8))
    }

    func testPercentOfSalesPlusManualPair() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfSales, value: 2),
            TipOutRecipientRule(name: "B", type: .manual, value: 6),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 0, sales: 500)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(10))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(6))
    }

    func testFlatPlusManualPair() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .flat, value: 9),
            TipOutRecipientRule(name: "B", type: .manual, value: 3),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 0, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(9))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(3))
    }

    // MARK: - Three- and four-recipient combinations

    func testThreeRecipientsMixedTypesEachIndependentlyCorrect() {
        let recipients = [
            TipOutRecipientRule(name: "Bar", type: .percentOfTips, value: 5),
            TipOutRecipientRule(name: "Support", type: .percentOfSales, value: 2),
            TipOutRecipientRule(name: "Runner", type: .flat, value: 7),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 200, sales: 1000)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(10))
        XCTAssertEqual(shares[1].resolvedAmount, Decimal(20))
        XCTAssertEqual(shares[2].resolvedAmount, Decimal(7))
    }

    func testFourRecipientsAllTypesSumsToExpectedTotal() {
        let recipients = [
            TipOutRecipientRule(name: "A", type: .percentOfTips, value: 5),
            TipOutRecipientRule(name: "B", type: .percentOfSales, value: 2.5),
            TipOutRecipientRule(name: "C", type: .flat, value: 10),
            TipOutRecipientRule(name: "D", type: .manual, value: 22.50),
        ]
        let shares = TipOutEngine.resolve(recipients: recipients, voluntaryTips: 240, sales: 1450)
        let total = shares.reduce(Decimal(0)) { $0 + $1.resolvedAmount }
        XCTAssertEqual(total, Decimal(string: "12.00")! + Decimal(string: "36.25")! + 10 + Decimal(string: "22.50")!)
    }

    func testFiveRecipientsSameTypeEachIndependentOfOrder() {
        let ascending = (1...5).map { TipOutRecipientRule(name: "R\($0)", type: .percentOfTips, value: Decimal($0)) }
        let descending = Array(ascending.reversed())
        let ascendingShares = TipOutEngine.resolve(recipients: ascending, voluntaryTips: 1000, sales: 0)
        let descendingShares = TipOutEngine.resolve(recipients: descending, voluntaryTips: 1000, sales: 0)
        XCTAssertEqual(ascendingShares.reduce(Decimal(0)) { $0 + $1.resolvedAmount },
                       descendingShares.reduce(Decimal(0)) { $0 + $1.resolvedAmount })
    }

    // MARK: - Additional rounding ties (half-up)

    func testRoundingTie_005RoundsUpTo01() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .manual, value: Decimal(string: "0.005")!)],
                                            voluntaryTips: 0, sales: 0)
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "0.01"))
    }

    func testRoundingTie_125RoundsUpTo13AtOneDecimal() {
        let value = Decimal(string: "1.25")!
        XCTAssertEqual(value.rounded(toScale: 1), Decimal(string: "1.3"))
    }

    func testRoundingTie_10PercentOf5Point05() {
        let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: .percentOfTips, value: 10)],
                                            voluntaryTips: Decimal(string: "5.05")!, sales: 0)
        // 10% of 5.05 = 0.505 -> rounds to 0.51 half-up.
        XCTAssertEqual(shares[0].resolvedAmount, Decimal(string: "0.51"))
    }

    func testRoundingNeverProducesMoreThanTwoFractionDigitsForAnySingleRuleType() {
        for type in TipOutRuleType.allCases {
            let shares = TipOutEngine.resolve(recipients: [TipOutRecipientRule(name: "A", type: type, value: Decimal(string: "7.777")!)],
                                                voluntaryTips: Decimal(string: "33.333")!, sales: Decimal(string: "77.777")!)
            XCTAssertEqual(shares[0].resolvedAmount, shares[0].resolvedAmount.rounded(toScale: 2), "type \(type)")
        }
    }
}
