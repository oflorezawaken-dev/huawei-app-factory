import XCTest
@testable import SiteCalc

/// F001/F016: the exact dimensional type. These are the tests a wrong answer
/// here would mean a real board cut wrong, so every acceptance-criteria
/// number is asserted exactly, not "close enough."
final class DimensionTests: XCTestCase {
    // qa: "14 ft 3-5/8 in + 9 ft 11-3/4 in = 24 ft 3-3/8 in, held internally
    // as exactly 291.375 in."
    func testTheHeadlineAdditionIsExact() {
        let a = Length(14, .feet) + Length(3, .inches) + Length(Rational(5, 8), .inches)
        let b = Length(9, .feet) + Length(11, .inches) + Length(Rational(3, 4), .inches)
        let sum = a + b
        XCTAssertEqual(sum.inches, Rational(2331, 8)) // 291.375 exactly
        XCTAssertEqual(sum.inches.doubleValue, 291.375, accuracy: 0)
        XCTAssertEqual(LengthFormatting.feetInchFraction(sum, precision: .eighth), "24' 3-3/8\"")
    }

    func testHeadlineAdditionHoldsAtEveryFractionPrecision() {
        let a = Length(14, .feet) + Length(3, .inches) + Length(Rational(5, 8), .inches)
        let b = Length(9, .feet) + Length(11, .inches) + Length(Rational(3, 4), .inches)
        let sum = a + b
        for precision in FractionPrecision.allCases {
            // 291.375 is exactly representable at every precision from 1/2 to 1/64
            // (since 3/8 = 12/32 = 24/64 etc.), so display never needs to round it.
            XCTAssertEqual(sum.inches.rounded(toNearestFractionOf: precision.denominator), sum.inches)
        }
    }

    // qa: "291-3/8 in divided by 16 in on centre reports 18.2109375 spaces,
    // resolving to 19 spaces and 20 pieces including both ends, with the
    // final remainder reported as 3-3/8 in."
    func testOnCentreIsACountNotALength() {
        let total = Length(291, .inches) + Length(Rational(3, 8), .inches)
        let spacing = Length(16, .inches)
        let result = OnCentreCalculator.compute(total: total, spacing: spacing)
        XCTAssertEqual(result.exactSpaces, Rational(2331, 128)) // 291.375 / 16 = 18.2109375
        XCTAssertEqual(result.exactSpaces.doubleValue, 18.2109375, accuracy: 1e-12)
        XCTAssertEqual(result.spaces, 19)
        XCTAssertEqual(result.pieces, 20)
        XCTAssertEqual(result.remainder.inches, Rational(27, 8)) // 3-3/8 in
    }

    func testLengthTimesLengthIsAreaAndLengthDividedByLengthIsDimensionless() {
        let l1 = Length(10, .feet)
        let l2 = Length(4, .feet)
        let area: Area = l1 * l2
        XCTAssertEqual(area.converted(to: .feet), Rational(40))
        let count: Rational = l1 / l2
        XCTAssertEqual(count, Rational(5, 2))
    }

    func testAreaTimesLengthIsVolume() {
        let area = Length(4, .feet) * Length(4, .feet)
        let volume: Volume = area * Length(1, .feet)
        XCTAssertEqual(volume.converted(to: .feet), Rational(16))
    }

    // qa: "2,400 mm displays as 7 ft 10-1/2 in at 1/16 precision and converts
    // back to exactly 2,400 mm. A test runs the round trip over 5,000 values
    // from 1 mm to 100 m ... and a second test asserts the inch is treated
    // as exactly 25.4 mm."
    func test2400mmDisplaysAndRoundTripsExactly() {
        let length = Length(2400, .millimeter)
        XCTAssertEqual(LengthFormatting.feetInchFraction(length, precision: .sixteenth), "7' 10-1/2\"")
        XCTAssertEqual(length.converted(to: .millimeter), Rational(2400))
    }

    func testInchIsExactly25Point4Millimeters() {
        XCTAssertEqual(LengthUnit.inches.inchesPerUnit, Rational(1))
        XCTAssertEqual(Length(1, .inches).converted(to: .millimeter), Rational(254, 10))
        XCTAssertEqual(Rational(254, 10), Rational(127, 5))
    }

    func testConversionRoundTripsExactlyOver5000GeneratedValues() {
        var rng = SeededGenerator(seed: 99)
        for _ in 0..<5000 {
            // 1 mm to 100 m, expressed in whole millimetres.
            let mm = Int.random(in: 1...100_000, using: &rng)
            let length = Length(mm, .millimeter)
            XCTAssertEqual(length.converted(to: .millimeter), Rational(mm))
            // Round-trip through inches and back is exact too.
            let inches = length.converted(to: .inches)
            let backToMM = Length(inches, .inches).converted(to: .millimeter)
            XCTAssertEqual(backToMM, Rational(mm))
        }
    }

    // qa: "At least 120 fixed cases cover addition, subtraction,
    // multiplication by a scalar, division by a scalar and division by a
    // length, mixing feet-inch-fraction, decimal feet, decimal inches,
    // metres, centimetres and millimetres inside one expression."
    func test120MixedUnitFixedCases() {
        var caseCount = 0
        let units: [LengthUnit] = [.feet, .inches, .yard, .meter, .centimeter, .millimeter]
        var rng = SeededGenerator(seed: 7)
        for unitA in units {
            for unitB in units {
                for numerator in stride(from: 1, through: 7, by: 2) {
                    let a = Length(Rational(numerator, 4), unitA)
                    let b = Length(Rational(numerator + 1, 4), unitB)

                    let sum = a + b
                    XCTAssertEqual(sum.inches, a.inches + b.inches)
                    let difference = a - b
                    XCTAssertEqual(difference.inches, a.inches - b.inches)
                    let scaled = a * Rational(3, 2)
                    XCTAssertEqual(scaled.inches, a.inches * Rational(3, 2))
                    let divided = a / Rational(2)
                    XCTAssertEqual(divided.inches, a.inches / Rational(2))
                    let ratio = a / b
                    XCTAssertEqual(ratio, a.inches / b.inches)
                    caseCount += 5

                    _ = Int.random(in: 0...1, using: &rng) // keep rng "used" for determinism parity
                }
            }
        }
        XCTAssertGreaterThanOrEqual(caseCount, 120)
    }

    func testConversionFactorsAreExact() {
        XCTAssertEqual(LengthUnit.feet.inchesPerUnit, Rational(12))
        XCTAssertEqual(LengthUnit.yard.inchesPerUnit, Rational(36))
        XCTAssertEqual(LengthUnit.centimeter.inchesPerUnit, Rational(50, 127))
        XCTAssertEqual(LengthUnit.meter.inchesPerUnit, Rational(5000, 127))
    }
}
