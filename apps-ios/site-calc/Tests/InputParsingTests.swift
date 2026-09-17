import XCTest
@testable import SiteCalc

/// The gap these close: every other test in this suite builds its input with
/// `Length(111, .inches)` and never touches the parser the screens actually
/// use. The engine was right and the screen fed it something else -- "111"
/// typed into the stair solver's total rise meant 111 *feet*, and the app
/// answered a 34-metre staircase with complete confidence.
///
/// So these tests drive the published worked examples **through the parser**,
/// exactly as the fields do.
final class InputParsingTests: XCTestCase {
    private var settings: AppSettings!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "InputParsingTests")!
        defaults.removePersistentDomain(forName: "InputParsingTests")
        settings = AppSettings(defaults: defaults)
    }

    // MARK: - the unit a bare number means

    func testABareNumberMeansTheUnitTheFieldDeclares() {
        XCTAssertEqual(InputParsing.length("111", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(111))
        XCTAssertEqual(InputParsing.length("15", settings: settings, defaultUnit: .feet)?.inches,
                       Rational(180))
        XCTAssertEqual(InputParsing.length("40", settings: settings, defaultUnit: .centimeter)?
                        .converted(to: .centimeter), Rational(40))
    }

    func testAnExplicitMarkBeatsTheFieldsDefault() {
        // A field that means feet must still accept 4 inches when asked.
        XCTAssertEqual(InputParsing.length("4\"", settings: settings, defaultUnit: .feet)?.inches, Rational(4))
        XCTAssertEqual(InputParsing.length("4 in", settings: settings, defaultUnit: .feet)?.inches, Rational(4))
        XCTAssertEqual(InputParsing.length("15'", settings: settings, defaultUnit: .inches)?.inches, Rational(180))
        XCTAssertEqual(InputParsing.length("15 ft", settings: settings, defaultUnit: .inches)?.inches, Rational(180))
    }

    // MARK: - the notation the spec's own examples are written in

    func testFeetAndInchesTogether() {
        XCTAssertEqual(InputParsing.length("9' 3\"", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(111))
        XCTAssertEqual(InputParsing.length("9'3\"", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(111))
        XCTAssertEqual(InputParsing.length("9 ft 3 in", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(111))
    }

    func testFractions() {
        // "a user-entered maximum riser of 7-3/4 in" -- the spec's own wording,
        // which the first parser could not accept at all.
        XCTAssertEqual(InputParsing.length("7-3/4", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(31, 4))
        XCTAssertEqual(InputParsing.length("7 3/4", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(31, 4))
        XCTAssertEqual(InputParsing.length("3/4", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(3, 4))
        XCTAssertEqual(InputParsing.length("14' 3-5/8\"", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(1373, 8))
    }

    func testBothDecimalSeparators() {
        XCTAssertEqual(InputParsing.length("7.75", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(31, 4))
        XCTAssertEqual(InputParsing.length("7,75", settings: settings, defaultUnit: .inches)?.inches,
                       Rational(31, 4))
    }

    func testRubbishIsRejectedRatherThanGuessed() {
        for text in ["", "   ", "abc", "-5", "7/0", "1.2.3"] {
            XCTAssertNil(InputParsing.length(text, settings: settings, defaultUnit: .inches),
                         "'\(text)' should not parse")
        }
    }

    // MARK: - the worked examples, through the parser and the solvers

    func testTheStairExampleAsAUserWouldTypeIt() throws {
        let rise = try XCTUnwrap(InputParsing.length("111", settings: settings, defaultUnit: .inches))
        let maxRiser = try XCTUnwrap(InputParsing.length("7-3/4", settings: settings, defaultUnit: .inches))
        let minTread = try XCTUnwrap(InputParsing.length("10", settings: settings, defaultUnit: .inches))
        let result = try StairSolver.solve(totalRise: rise, maxRiserHeight: maxRiser, minTreadDepth: minTread)
        XCTAssertEqual(result.riserCount, 15)
        XCTAssertEqual(result.riserHeight.inches, Rational(37, 5))
        XCTAssertEqual(LengthFormatting.feetInchFraction(result.stringerLength, precision: .sixteenth),
                       "14' 10-11/16\"")
    }

    func testTheRoofExampleAsAUserWouldTypeIt() throws {
        let run = try XCTUnwrap(InputParsing.length("15", settings: settings, defaultUnit: .feet))
        let result = try RoofSolver.solve(rise: nil, run: run, diagonal: nil, pitchPer12: Rational(7))
        XCTAssertEqual(LengthFormatting.feetInchFraction(result.rise, precision: .eighth), "8' 9\"")
        XCTAssertEqual(LengthFormatting.feetInchFraction(result.commonRafter, precision: .sixteenth),
                       "17' 4-3/8\"")
    }

    /// The label a field shows must name the unit that field assumes, or the
    /// default is a guess the user cannot see.
    func testEveryFieldLabelNamesItsUnit() {
        XCTAssertTrue(fieldLabel("stair.totalRise", .inches).hasSuffix("(in)"))
        XCTAssertTrue(fieldLabel("roof.run", .feet).hasSuffix("(ft)"))
        XCTAssertTrue(fieldLabel("roof.run", .centimeter).hasSuffix("(cm)"))
    }
}
