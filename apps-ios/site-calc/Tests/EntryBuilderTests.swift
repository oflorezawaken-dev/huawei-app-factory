import XCTest
@testable import SiteCalc

final class EntryBuilderTests: XCTestCase {
    // The exact keypad sequence a user would type for "14 ft 3-5/8 in":
    // 1,4,FT,3,IN... but a fraction is entered as digits then "/" then
    // digits, so this composes 14' then 3" then the 5/8 fraction.
    func testComposesFeetInchFraction() {
        var entry = EntryBuilder()
        entry.digit(1); entry.digit(4)
        entry.commitFeet()
        entry.digit(3)
        entry.commitInches()
        entry.digit(5)
        entry.fractionSlash()
        entry.digit(8)
        let quantity = entry.finalizeFeetInchFraction()
        guard case .length(let length) = quantity else { return XCTFail("expected a length") }
        XCTAssertEqual(length.inches, Rational(1373, 8)) // 171.625 in
    }

    func testHeadlineAdditionViaTwoEntries() {
        var first = EntryBuilder()
        first.digit(1); first.digit(4)
        first.commitFeet()
        first.digit(3)
        first.commitInches()
        first.digit(5); first.fractionSlash(); first.digit(8)
        guard case .length(let a) = first.finalizeFeetInchFraction()! else { return XCTFail() }

        var second = EntryBuilder()
        second.digit(9)
        second.commitFeet()
        second.digit(1); second.digit(1)
        second.commitInches()
        second.digit(3); second.fractionSlash(); second.digit(4)
        guard case .length(let b) = second.finalizeFeetInchFraction()! else { return XCTFail() }

        XCTAssertEqual((a + b).inches, Rational(2331, 8))
    }

    func testDecimalFeetDirectEntry() {
        var entry = EntryBuilder()
        entry.digit(1); entry.digit(0); entry.decimalPoint(); entry.digit(5)
        guard case .length(let length) = entry.finalizeDirect(unit: .feet)! else { return XCTFail() }
        XCTAssertEqual(length.inches, Rational(126)) // 10.5 ft = 126 in
    }

    func testMetricDirectEntry() {
        var entry = EntryBuilder()
        entry.digit(2); entry.digit(4); entry.digit(0); entry.digit(0)
        guard case .length(let length) = entry.finalizeDirect(unit: .millimeter)! else { return XCTFail() }
        XCTAssertEqual(length.converted(to: .millimeter), Rational(2400))
    }

    func testBackspaceRemovesBufferThenComponents() {
        var entry = EntryBuilder()
        entry.digit(1); entry.digit(4)
        entry.commitFeet()
        entry.digit(3)
        entry.backspace() // removes the "3" from buffer, not the committed feet
        XCTAssertTrue(entry.buffer.isEmpty)
        entry.backspace() // now removes the committed feet
        XCTAssertNil(entry.feetComponent)
    }

    func testPercentProducesADimensionlessCount() {
        var entry = EntryBuilder()
        entry.digit(1); entry.digit(0)
        entry.percent()
        guard case .count(let value) = entry.finalizeFeetInchFraction()! else { return XCTFail() }
        XCTAssertEqual(value, Rational(1, 10))
    }

    func testEmptyEntryFinalizesToNil() {
        let entry = EntryBuilder()
        XCTAssertNil(entry.finalizeFeetInchFraction())
    }
}
