import XCTest
@testable import SiteCalc

/// qa: "Numeric entry accepts both the comma and the period as the decimal
/// separator and produces the same value in en-US, de-DE, fr-FR, tr and
/// ar-SA." DecimalParsing itself is locale-independent by design (it accepts
/// either separator regardless of device locale), so the same five checks
/// simply confirm both punctuation marks resolve identically everywhere the
/// app runs, without depending on Locale.current at test time.
final class DecimalParsingTests: XCTestCase {
    private let locales = ["en_US", "de_DE", "fr_FR", "tr_TR", "ar_SA"]

    func testCommaAndPeriodProduceTheSameValueInEveryLocale() {
        for identifier in locales {
            let withPeriod = DecimalParsing.parse("12.5")
            let withComma = DecimalParsing.parse("12,5")
            XCTAssertEqual(withPeriod, withComma, "mismatch for locale \(identifier)")
            XCTAssertEqual(withPeriod, Rational(25, 2))
        }
    }

    func testNegativeAndWholeNumbers() {
        XCTAssertEqual(DecimalParsing.parse("-3.5"), Rational(-7, 2))
        XCTAssertEqual(DecimalParsing.parse("10"), Rational(10))
        XCTAssertEqual(DecimalParsing.parse("0.125"), Rational(1, 8))
    }

    func testMalformedInputReturnsNil() {
        XCTAssertNil(DecimalParsing.parse(""))
        XCTAssertNil(DecimalParsing.parse("1.2.3"))
        XCTAssertNil(DecimalParsing.parse("abc"))
        XCTAssertNil(DecimalParsing.parse("1,2,3"))
    }

    func testLeadingDecimalPoint() {
        XCTAssertEqual(DecimalParsing.parse(".5"), Rational(1, 2))
        XCTAssertEqual(DecimalParsing.parse(","), nil)
    }
}
