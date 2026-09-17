import XCTest
@testable import SiteCalc

/// F006/F007/F016: every acceptance-criteria number for area, volume and
/// material estimating, including the exactness regression (180 * 1.1 must
/// be exactly 198, never 198.00000000000003).
final class AreaVolumeMaterialTests: XCTestCase {
    /// The assertions in this file pin en_US_POSIX so they can compare against
    /// literals from the spec. That is a testing convenience, not the product:
    /// the listing ships in nine languages and a Spanish or German user must
    /// see 7,41. Pinned here so the next person whose test fails on "7,41"
    /// fixes the test rather than hard-coding a dot into the formatter.
    func testTheDecimalSeparatorFollowsTheViewersLocale() {
        let value = Rational(741, 100)
        XCTAssertEqual(LengthFormatting.decimalString(value, decimalPlaces: 2,
                                                       locale: Locale(identifier: "en_US_POSIX")), "7.41")
        XCTAssertEqual(LengthFormatting.decimalString(value, decimalPlaces: 2,
                                                       locale: Locale(identifier: "es_ES")), "7,41")
        XCTAssertEqual(LengthFormatting.decimalString(value, decimalPlaces: 2,
                                                       locale: Locale(identifier: "de_DE")), "7,41")
    }

    // qa: "a 20 ft by 30 ft slab at 4 in thick is 200.00 cubic feet and 7.41
    // cubic yards, needing 334 bags at a 0.60 cubic foot yield; with a 10 per
    // cent waste the same slab is 8.15 cubic yards and 367 bags."
    func testSlabVolumeAndConcreteBags() {
        let volume = AreaVolumeSolver.slabVolume(length: Length(20, .feet), width: Length(30, .feet),
                                                  thickness: Length(4, .inches))
        XCTAssertEqual(volume.converted(to: .feet), Rational(200))

        let yards = MaterialEstimator.cubicYards(volume)
        XCTAssertEqual(LengthFormatting.decimalString(yards, decimalPlaces: 2, locale: Locale(identifier: "en_US_POSIX")), "7.41")

        let bags = MaterialEstimator.concreteBags(volume: volume, bagYieldCubicFeet: Rational(3, 5))
        XCTAssertEqual(bags.roundedUp, 334)

        let yardsWithWaste = MaterialEstimator.cubicYards(volume, wastePercent: Rational(10))
        XCTAssertEqual(LengthFormatting.decimalString(yardsWithWaste, decimalPlaces: 2, locale: Locale(identifier: "en_US_POSIX")), "8.15")
        let bagsWithWaste = MaterialEstimator.concreteBags(volume: volume, bagYieldCubicFeet: Rational(3, 5),
                                                            wastePercent: Rational(10))
        XCTAssertEqual(bagsWithWaste.roundedUp, 367)
    }

    // qa: "40 ft of wall at 8 ft is 320 square feet, 10 sheets of 4 ft by 8
    // ft exactly and 11 sheets at 10 per cent waste."
    func testWallSheets() {
        let area = AreaVolumeSolver.rectangleArea(width: Length(40, .feet), height: Length(8, .feet))
        XCTAssertEqual(area.converted(to: .feet), Rational(320))

        let sheets = MaterialEstimator.sheets(area: area, sheetWidth: Length(4, .feet), sheetHeight: Length(8, .feet))
        XCTAssertEqual(sheets.roundedUp, 10)
        XCTAssertEqual(sheets.exact, Rational(10))

        let sheetsWithWaste = MaterialEstimator.sheets(area: area, sheetWidth: Length(4, .feet),
                                                        sheetHeight: Length(8, .feet), wastePercent: Rational(10))
        XCTAssertEqual(sheetsWithWaste.roundedUp, 11)
        XCTAssertEqual(sheetsWithWaste.exact, Rational(11)) // exact, not a float artifact
    }

    // qa: "A 12 ft by 15 ft floor in 12 in tile at 10 per cent waste is
    // exactly 198 tiles - and this case is a regression test for the
    // exactness rule as much as for the estimator, because 180 times 1.1 in
    // binary floating point is 198.00000000000003, which rounds up to 199."
    func testTileExactnessRegression() {
        let area = AreaVolumeSolver.rectangleArea(width: Length(12, .feet), height: Length(15, .feet))
        XCTAssertEqual(area.converted(to: .feet), Rational(180))

        let tiles = MaterialEstimator.pieces(area: area, pieceWidth: Length(12, .inches),
                                              pieceHeight: Length(12, .inches), wastePercent: Rational(10))
        XCTAssertEqual(tiles.exact, Rational(198)) // exactly 198, not 198.000...03
        XCTAssertEqual(tiles.roundedUp, 198)

        // Prove the point directly: binary Double really does misround this.
        let doubleArtifact = 180.0 * 1.1
        XCTAssertNotEqual(doubleArtifact, 198.0, "if this ever becomes equal, the regression case is moot")
        XCTAssertEqual(Int(doubleArtifact.rounded(.up)), 199, "confirms the float trap this test guards against")
    }

    // qa: "1,200 square feet at a user-entered 350 square feet per container
    // is 3.43 containers and 4 to buy."
    func testPaintContainers() {
        let area = Area(squareInches: Length(1, .feet).inches * Length(1200, .feet).inches)
        let containers = MaterialEstimator.paintContainers(area: area, coverageSquareFeetPerContainer: Rational(350))
        XCTAssertEqual(LengthFormatting.decimalString(containers.exact, decimalPlaces: 2, locale: Locale(identifier: "en_US_POSIX")), "3.43")
        XCTAssertEqual(containers.roundedUp, 4)
    }

    func testWallAreaSubtractsOpenings() {
        let area = AreaVolumeSolver.wallArea(width: Length(20, .feet), height: Length(8, .feet),
                                              openings: [(width: Length(3, .feet), height: Length(7, .feet))])
        XCTAssertEqual(area.converted(to: .feet), Rational(160 - 21))
    }

    func testCircleAreaAndCircumference() {
        let radius = Length(7, .feet)
        let area = AreaVolumeSolver.circleArea(radius: radius)
        assertNear(area.converted(to: .feet).doubleValue, Double.pi * 49, tolerance: 0.001)
        let circumference = AreaVolumeSolver.circleCircumference(radius: radius)
        assertNear(circumference.converted(to: .feet).doubleValue, 2 * Double.pi * 7, tolerance: 0.001)
    }

    func testFramingOnCentreMatchesSharedCalculator() {
        let total = Length(291, .inches) + Length(Rational(3, 8), .inches)
        let result = MaterialEstimator.framing(total: total, spacing: Length(16, .inches))
        XCTAssertEqual(result.spaces, 19)
        XCTAssertEqual(result.pieces, 20)
    }

    func testDeckingBoardCount() {
        // 10 ft coverage, 5.5 in boards with a 1/4 in gap -> effective 5.75 in.
        let boards = MaterialEstimator.deckingBoards(coverageWidth: Length(10, .feet),
                                                      boardWidth: Length(Rational(11, 2), .inches),
                                                      gap: Length(Rational(1, 4), .inches))
        // 120 in / 5.75 in = 20.869..., rounds up to 21.
        XCTAssertEqual(boards.roundedUp, 21)
    }

    func testRoofingSquares() {
        let area = AreaVolumeSolver.rectangleArea(width: Length(30, .feet), height: Length(40, .feet))
        let squares = MaterialEstimator.roofingSquares(area: area)
        XCTAssertEqual(squares.exact, Rational(12)) // 1200 sqft / 100 = 12 exactly
        XCTAssertEqual(squares.roundedUp, 12)
    }
}
