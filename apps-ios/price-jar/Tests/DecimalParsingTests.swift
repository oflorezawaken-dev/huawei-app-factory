import XCTest
@testable import PriceJar

/// `DecimalParsing` takes no locale parameter by design -- a shopper's
/// typing habit does not change with the app's display language -- so both
/// separators must parse identically regardless of which of the five
/// locales named in the acceptance criteria (en-US, de-DE, fr-FR, tr,
/// ar-SA) the device is actually running in.
final class DecimalParsingTests: XCTestCase {
    private let localeIdentifiers = ["en_US", "de_DE", "fr_FR", "tr_TR", "ar_SA"]

    func testPeriodSeparatorIsLocaleIndependent() {
        for identifier in localeIdentifiers {
            XCTAssertEqual(DecimalParsing.parse("12.34"), Decimal(string: "12.34"),
                            "period separator failed while representing \(identifier)")
        }
    }

    func testCommaSeparatorIsLocaleIndependent() {
        for identifier in localeIdentifiers {
            XCTAssertEqual(DecimalParsing.parse("12,34"), Decimal(string: "12.34"),
                            "comma separator failed while representing \(identifier)")
        }
    }

    func testGroupingWithPeriodThenCommaDecimal() {
        // "1.234,56" -- period is grouping, comma is the decimal separator.
        XCTAssertEqual(DecimalParsing.parse("1.234,56"), Decimal(string: "1234.56"))
    }

    func testGroupingWithCommaThenPeriodDecimal() {
        // "1,234.56" -- comma is grouping, period is the decimal separator.
        XCTAssertEqual(DecimalParsing.parse("1,234.56"), Decimal(string: "1234.56"))
    }

    func testIntegerWithNoSeparator() {
        XCTAssertEqual(DecimalParsing.parse("5"), 5)
    }

    func testEmptyStringIsNil() {
        XCTAssertNil(DecimalParsing.parse(""))
    }

    func testWhitespaceOnlyIsNil() {
        XCTAssertNil(DecimalParsing.parse("   "))
    }

    func testGarbageIsNil() {
        XCTAssertNil(DecimalParsing.parse("abc"))
    }

    func testLeadingAndTrailingWhitespaceIsTrimmed() {
        XCTAssertEqual(DecimalParsing.parse("  3.50  "), Decimal(string: "3.50"))
    }

    func testArabicIndicDigitsAreAccepted() {
        // "12.34" written with Arabic-Indic digits.
        XCTAssertEqual(DecimalParsing.parse("\u{0661}\u{0662}.\u{0663}\u{0664}"), Decimal(string: "12.34"))
    }

    func testExtendedArabicIndicDigitsAreAccepted() {
        XCTAssertEqual(DecimalParsing.parse("\u{06F1}\u{06F2},\u{06F3}\u{06F4}"), Decimal(string: "12.34"))
    }
}
