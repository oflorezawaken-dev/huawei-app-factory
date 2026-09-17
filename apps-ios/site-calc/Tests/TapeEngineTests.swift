import XCTest
@testable import SiteCalc

final class TapeEngineTests: XCTestCase {
    func testRunningResultAccumulates() {
        let lines = [
            TapeLine(operatorApplied: nil, operand: .length(Length(10, .feet))),
            TapeLine(operatorApplied: .add, operand: .length(Length(5, .feet))),
            TapeLine(operatorApplied: .subtract, operand: .length(Length(3, .feet))),
        ]
        let result = TapeEngine.recompute(lines)
        guard case .length(let final) = result.last!.runningResult! else { return XCTFail("expected a length") }
        XCTAssertEqual(final.converted(to: .feet), Rational(12))
    }

    // F002: "correction recomputes everything below it and shows that it was
    // corrected" -- editing an early line must ripple through every later one.
    func testCorrectingAnEarlyLineRecomputesEverythingBelow() {
        var lines = [
            TapeLine(operatorApplied: nil, operand: .length(Length(10, .feet))),
            TapeLine(operatorApplied: .add, operand: .length(Length(5, .feet))),
            TapeLine(operatorApplied: .add, operand: .length(Length(1, .feet))),
        ]
        lines = TapeEngine.recompute(lines)
        guard case .length(let before) = lines.last!.runningResult! else { return XCTFail() }
        XCTAssertEqual(before.converted(to: .feet), Rational(16))

        lines[0].operand = .length(Length(20, .feet))
        lines = TapeEngine.recompute(lines)
        guard case .length(let after) = lines.last!.runningResult! else { return XCTFail() }
        XCTAssertEqual(after.converted(to: .feet), Rational(26))
    }

    func testIncompatibleOperandsFailWithoutCrashing() {
        let lines = [
            TapeLine(operatorApplied: nil, operand: .length(Length(10, .feet))),
            TapeLine(operatorApplied: .add, operand: .area(Area(squareInches: Rational(100)))),
        ]
        let result = TapeEngine.recompute(lines)
        XCTAssertTrue(result.last!.failed)
        XCTAssertNil(result.last!.runningResult)
    }

    func testFailureBreaksTheChainForEverythingAfterIt() {
        let lines = [
            TapeLine(operatorApplied: nil, operand: .length(Length(10, .feet))),
            TapeLine(operatorApplied: .add, operand: .area(Area(squareInches: Rational(100)))),
            TapeLine(operatorApplied: .add, operand: .length(Length(5, .feet))),
        ]
        let result = TapeEngine.recompute(lines)
        XCTAssertTrue(result[1].failed)
        XCTAssertTrue(result[2].failed)
        XCTAssertNil(result[2].runningResult)
    }

    func testOnCentreOperatorProducesACountAndSnapshot() {
        let total = Length(291, .inches) + Length(Rational(3, 8), .inches)
        let lines = [
            TapeLine(operatorApplied: nil, operand: .length(total)),
            TapeLine(operatorApplied: .onCentre, operand: .length(Length(16, .inches))),
        ]
        let result = TapeEngine.recompute(lines)
        guard case .count(let spaces) = result.last!.runningResult! else { return XCTFail("expected a count") }
        XCTAssertEqual(spaces, Rational(2331, 128))
        XCTAssertEqual(result.last!.onCentreResult?.spaces, 19)
        XCTAssertEqual(result.last!.onCentreResult?.pieces, 20)
    }

    func testDivisionByZeroFailsGracefully() {
        let lines = [
            TapeLine(operatorApplied: nil, operand: .length(Length(10, .feet))),
            TapeLine(operatorApplied: .divide, operand: .length(Length.zero)),
        ]
        let result = TapeEngine.recompute(lines)
        XCTAssertTrue(result.last!.failed)
    }
}
