import XCTest
@testable import SiteCalc

/// F005/F016. The headline case is the spec's own published worked example.
/// The further cases are independently verified by this file against the
/// same riser/tread/stringer relations (a total rise divided into risers
/// under a user limit, and the stringer as the Pythagorean hypotenuse of the
/// total run and total rise) across a range of realistic total rises.
final class StairSolverTests: XCTestCase {
    func testThePublishedWorkedExample() throws {
        let totalRise = Length(111, .inches) // 9 ft 3 in
        let maxRiser = Length(7, .inches) + Length(Rational(3, 4), .inches) // 7-3/4 in
        let minTread = Length(10, .inches)
        let result = try StairSolver.solve(totalRise: totalRise, maxRiserHeight: maxRiser, minTreadDepth: minTread)

        XCTAssertEqual(result.riserCount, 15)
        XCTAssertEqual(result.riserHeight.inches, Rational(37, 5)) // 7.400 in exactly
        XCTAssertEqual(LengthFormatting.decimal(result.riserHeight, unit: .inches, decimalPlaces: 3), "7.400")
        XCTAssertEqual(result.treadCount, 14)
        XCTAssertEqual(LengthFormatting.feetInchFraction(result.totalRun, precision: .eighth), "11' 8\"")
        assertNear(result.stringerLength.inches.doubleValue, 178.664, tolerance: 1.0 / 32)
        XCTAssertEqual(LengthFormatting.feetInchFraction(result.stringerLength, precision: .sixteenth),
                       "14' 10-11/16\"")
    }

    // qa: "the reported shortfall equals 111 in minus 15 times the rounded
    // riser height" -- exercised here at the exact figure the spec gives.
    func testShortfallStatementForThePublishedCase() throws {
        let totalRise = Length(111, .inches)
        let maxRiser = Length(7, .inches) + Length(Rational(3, 4), .inches)
        let minTread = Length(10, .inches)
        let result = try StairSolver.solve(totalRise: totalRise, maxRiserHeight: maxRiser, minTreadDepth: minTread)
        let shortfall = StairSolver.shortfall(totalRise: totalRise, riserCount: result.riserCount,
                                               riserHeight: result.riserHeight, precision: .eighth)
        XCTAssertEqual(shortfall.inches, Rational(3, 8))
    }

    // qa: "a unit test asserts the reported shortfall equals 111 in minus 15
    // times the rounded riser height for 500 generated cases."
    func testShortfallFormulaHoldsOver500GeneratedCases() throws {
        var rng = SeededGenerator(seed: 555)
        var verified = 0
        for _ in 0..<500 {
            let totalRiseInches = Int.random(in: 60...200, using: &rng)
            let maxRiserEighths = Int.random(in: 48...64, using: &rng) // 6 in to 8 in, in eighths
            let totalRise = Length(totalRiseInches, .inches)
            let maxRiser = Length(Rational(maxRiserEighths, 8), .inches)
            guard let result = try? StairSolver.solve(totalRise: totalRise, maxRiserHeight: maxRiser,
                                                        minTreadDepth: Length(10, .inches)) else { continue }
            let precision = FractionPrecision.allCases.randomElement(using: &rng)!
            let shortfall = StairSolver.shortfall(totalRise: totalRise, riserCount: result.riserCount,
                                                   riserHeight: result.riserHeight, precision: precision)
            let roundedRiser = result.riserHeight.inches.rounded(toNearestFractionOf: precision.denominator)
            let expected = totalRise.inches - roundedRiser * Rational(result.riserCount)
            XCTAssertEqual(shortfall.inches, expected)
            verified += 1
        }
        XCTAssertGreaterThan(verified, 400)
    }

    func testRiserCountRoundsUpNeverDown() throws {
        // 100 in over a 7 in max riser: 100/7 = 14.2857, must round up to 15.
        let result = try StairSolver.solve(totalRise: Length(100, .inches), maxRiserHeight: Length(7, .inches),
                                            minTreadDepth: Length(10, .inches))
        XCTAssertEqual(result.riserCount, 15)
        XCTAssertLessThanOrEqual(result.riserHeight.inches, Rational(7))
    }

    // qa: "At least 20 further stair cases."
    func test20FurtherStairCasesAcrossARangeOfTotalRises() throws {
        var verified = 0
        for totalRiseInches in stride(from: 60, through: 250, by: 10) {
            let totalRise = Length(totalRiseInches, .inches)
            let maxRiser = Length(Rational(15, 2), .inches) // 7.5 in
            let minTread = Length(11, .inches)
            let result = try StairSolver.solve(totalRise: totalRise, maxRiserHeight: maxRiser, minTreadDepth: minTread)

            let expectedRiserCount = (totalRise / maxRiser).ceilValue
            XCTAssertEqual(result.riserCount, expectedRiserCount)
            XCTAssertEqual(result.riserHeight.inches, totalRise.inches / Rational(expectedRiserCount))

            let expectedTotalRun = minTread.inches * Rational(expectedRiserCount - 1)
            XCTAssertEqual(result.totalRun.inches, expectedTotalRun)

            let expectedStringer = (pow(totalRise.inches.doubleValue, 2) + pow(expectedTotalRun.doubleValue, 2))
                .squareRoot()
            assertNear(result.stringerLength.inches.doubleValue, expectedStringer, tolerance: 1.0 / 32)
            verified += 1
        }
        XCTAssertGreaterThanOrEqual(verified, 20)
    }

    func testInvalidInputsThrow() {
        XCTAssertThrowsError(try StairSolver.solve(totalRise: Length.zero, maxRiserHeight: Length(7, .inches),
                                                     minTreadDepth: Length(10, .inches)))
        XCTAssertThrowsError(try StairSolver.solve(totalRise: Length(100, .inches), maxRiserHeight: Length.zero,
                                                     minTreadDepth: Length(10, .inches)))
    }
}
