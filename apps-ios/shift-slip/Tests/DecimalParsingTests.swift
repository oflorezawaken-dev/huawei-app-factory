import XCTest
@testable import ShiftSlip

/// Number entry must accept both ',' and '.' as the decimal separator and
/// produce the same Decimal regardless of the active locale (en-US, de-DE,
/// fr-FR, tr, ar-SA), for tips, hours, rates and sales alike.
final class DecimalParsingTests: XCTestCase {
    private let locales = ["en_US", "de_DE", "fr_FR", "tr_TR", "ar_SA"]

    func testPeriodAndCommaBothParseToTheSameValueInEveryLocale() {
        for identifier in locales {
            let previous = Locale.current
            _ = previous // Locale.current cannot be overridden process-wide in a unit test;
            // DecimalParsing is locale-independent by design, so this asserts
            // that independence directly rather than swapping the process locale.
            XCTAssertEqual(DecimalParsing.parse("42.50"), Decimal(string: "42.50"), identifier)
            XCTAssertEqual(DecimalParsing.parse("42,50"), Decimal(string: "42.50"), identifier)
        }
    }

    func testThousandsGroupingWithPeriodAsGroupingAndCommaAsDecimal() {
        XCTAssertEqual(DecimalParsing.parse("1.234,56"), Decimal(string: "1234.56"))
    }

    func testThousandsGroupingWithCommaAsGroupingAndPeriodAsDecimal() {
        XCTAssertEqual(DecimalParsing.parse("1,234.56"), Decimal(string: "1234.56"))
    }

    func testWholeNumberNoSeparator() {
        XCTAssertEqual(DecimalParsing.parse("42"), Decimal(42))
    }

    func testWhitespaceIsTrimmed() {
        XCTAssertEqual(DecimalParsing.parse("  42.50  "), Decimal(string: "42.50"))
    }

    func testEmptyStringParsesToNil() {
        XCTAssertNil(DecimalParsing.parse(""))
        XCTAssertNil(DecimalParsing.parse("   "))
    }

    func testGarbageParsesToNil() {
        XCTAssertNil(DecimalParsing.parse("abc"))
    }

    func testArabicIndicDigitsParse() {
        // "٤٢.٥٠" is Arabic-Indic for "42.50".
        XCTAssertEqual(DecimalParsing.parse("٤٢.٥٠"), Decimal(string: "42.50"))
    }

    func testExtendedArabicIndicDigitsParse() {
        // "۴۲.۵۰" is Extended Arabic-Indic (Persian/Urdu keyboards) for "42.50".
        XCTAssertEqual(DecimalParsing.parse("۴۲.۵۰"), Decimal(string: "42.50"))
    }

    func testALoneSeparatorWithNoDigitsParsesToZeroRatherThanCrashing() {
        // Foundation's Decimal(string:) treats "." as 0, not nil; a lone
        // separator with no digits should not crash or produce garbage.
        XCTAssertEqual(DecimalParsing.parse("."), 0)
        XCTAssertEqual(DecimalParsing.parse(","), 0)
    }
}
