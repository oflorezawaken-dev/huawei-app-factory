import XCTest
@testable import SiteCalc

/// F004/F016. The headline case is the spec's own published worked example.
/// The further cases below are independently verified against the
/// Pythagorean theorem and arctangent by this test file itself (run 15 ft at
/// 7-in-12 giving a 30.26-degree pitch is a standard framing-square relation,
/// not a citation this sandbox can fetch a named trade manual for) -- each
/// asserts to the nearest 1/16 in and 0.01 degrees, per qa's tolerance.
final class RoofSolverTests: XCTestCase {
    func testRunAndPitchReproduceThePublishedWorkedExample() throws {
        let result = try RoofSolver.solve(rise: nil, run: Length(15, .feet), diagonal: nil, pitchPer12: Rational(7))
        XCTAssertEqual(LengthFormatting.feetInchFraction(result.rise, precision: .eighth), "8' 9\"")
        assertNear(result.commonRafter.inches.doubleValue, 208.387, tolerance: 1.0 / 32)
        assertNear(result.pitchDegrees, 30.26, tolerance: 0.01)
        assertNear(result.hipOrValley.inches.doubleValue, 275.363, tolerance: 1.0 / 32)
    }

    func testRiseAndRunGiveTheDiagonal() throws {
        let result = try RoofSolver.solve(rise: Length(6, .feet), run: Length(12, .feet), diagonal: nil,
                                           pitchPer12: nil)
        assertNear(result.commonRafter.inches.doubleValue, (72.0 * 72 + 144.0 * 144).squareRoot(), tolerance: 0.001)
        assertNear(result.pitchPer12, 6.0, tolerance: 0.001)
    }

    func testRunAndDiagonalGiveTheRise() throws {
        // A 3-4-5 right triangle scaled to feet: run 4 ft (48 in), rafter 5 ft (60 in) -> rise 3 ft (36 in).
        let result = try RoofSolver.solve(rise: nil, run: Length(4, .feet), diagonal: Length(5, .feet),
                                           pitchPer12: nil)
        assertNear(result.rise.inches.doubleValue, 36, tolerance: 0.01)
    }

    func testRiseAndDiagonalGiveTheRun() throws {
        let result = try RoofSolver.solve(rise: Length(3, .feet), run: nil, diagonal: Length(5, .feet),
                                           pitchPer12: nil)
        assertNear(result.run.inches.doubleValue, 48, tolerance: 0.01)
    }

    func testInsufficientInputsThrows() {
        XCTAssertThrowsError(try RoofSolver.solve(rise: nil, run: nil, diagonal: nil, pitchPer12: nil))
    }

    // qa: "At least 30 further solver cases ... each asserted to the nearest
    // 1/16 in and to 0.01 degrees." Standard framing pitches (rise per 12 in
    // of run) at a range of run lengths, each independently verified here by
    // straight Pythagorean / arctangent computation.
    func testStandardPitchesAcrossARangeOfRunLengths() throws {
        let pitches = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 18]
        let runsInFeet = [8, 10, 12, 16, 20]
        var verified = 0
        for pitch in pitches {
            for runFeet in runsInFeet {
                let runInches = Double(runFeet * 12)
                let ratio = Double(pitch) / 12.0
                let expectedRiseInches = runInches * ratio
                let expectedRafter = (runInches * runInches + expectedRiseInches * expectedRiseInches).squareRoot()
                let expectedDegrees = atan(ratio) * 180 / .pi
                let expectedHip = (2 * runInches * runInches + expectedRiseInches * expectedRiseInches).squareRoot()

                let result = try RoofSolver.solve(rise: nil, run: Length(runFeet, .feet), diagonal: nil,
                                                   pitchPer12: Rational(pitch))
                assertNear(result.rise.inches.doubleValue, expectedRiseInches, tolerance: 1.0 / 32)
                assertNear(result.commonRafter.inches.doubleValue, expectedRafter, tolerance: 1.0 / 32)
                assertNear(result.pitchDegrees, expectedDegrees, tolerance: 0.01)
                assertNear(result.hipOrValley.inches.doubleValue, expectedHip, tolerance: 1.0 / 32)
                verified += 1
            }
        }
        XCTAssertGreaterThanOrEqual(verified, 30)
    }
}

func assertNear(_ actual: Double, _ expected: Double, tolerance: Double, file: StaticString = #filePath,
                 line: UInt = #line) {
    XCTAssertEqual(actual, expected, accuracy: tolerance, file: file, line: line)
}
