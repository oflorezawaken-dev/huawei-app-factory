import XCTest
@testable import ShiftSlip

/// F005's earnings maths is the other module that must never be wrong.
final class EarningsEngineTests: XCTestCase {
    /// Fixed to UTC so results do not change with the runner's timezone,
    /// except in the DST tests, which deliberately use "America/New_York".
    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    func testWorkedExampleFromF005() {
        let figures = ShiftFigures(hours: Decimal(string: "5.5")!, baseRate: Decimal(string: "2.13")!,
                                    cashTips: 60, chargeTips: 180, tipOutTotal: Decimal(string: "19.20")!,
                                    sales: 1450)
        XCTAssertEqual(EarningsEngine.tipsKept(figures), Decimal(string: "220.80"))
        XCTAssertEqual(EarningsEngine.basePay(figures), Decimal(string: "11.715"))
        XCTAssertEqual(EarningsEngine.totalPay(figures).rounded(toScale: 2), Decimal(string: "232.52"))
        XCTAssertEqual(EarningsEngine.effectiveHourly(figures)?.rounded(toScale: 2), Decimal(string: "42.28"))
        XCTAssertEqual(EarningsEngine.tipsPerHour(figures)?.rounded(toScale: 2), Decimal(string: "40.15"))
        XCTAssertEqual(EarningsEngine.tipPercentage(figures)?.rounded(toScale: 2), Decimal(string: "16.55"))
    }

    func testZeroHourShiftShowsDashInsteadOfDividingByZero() {
        let figures = ShiftFigures(hours: 0, baseRate: 15, cashTips: 20, chargeTips: 0, tipOutTotal: 0, sales: nil)
        XCTAssertNil(EarningsEngine.effectiveHourly(figures))
        XCTAssertNil(EarningsEngine.tipsPerHour(figures))
    }

    func testZeroTipShiftStillReportsBasePay() {
        let figures = ShiftFigures(hours: 8, baseRate: 15, cashTips: 0, chargeTips: 0, tipOutTotal: 0, sales: nil)
        XCTAssertEqual(EarningsEngine.basePay(figures), 120)
        XCTAssertEqual(EarningsEngine.totalPay(figures), 120)
    }

    func testTipPercentageIsNilWhenSalesNotEntered() {
        let figures = ShiftFigures(hours: 5, baseRate: 10, cashTips: 20, chargeTips: 10, tipOutTotal: 0, sales: nil)
        XCTAssertNil(EarningsEngine.tipPercentage(figures))
    }

    func testNoncashTipsAndServiceChargesNeverEnterVoluntaryTips() {
        // ShiftFigures deliberately has no noncash/serviceCharges fields --
        // only cash + charge count as voluntaryTips, per F004.
        let figures = ShiftFigures(hours: 5, baseRate: 10, cashTips: 20, chargeTips: 10, tipOutTotal: 0, sales: nil)
        XCTAssertEqual(figures.voluntaryTips, 30)
    }

    // MARK: - Overnight shifts, DST-safe

    func testOvernightShiftIsFourPointSevenFiveHours() {
        let start = utc.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 21, minute: 45))!
        let end = utc.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: 2, minute: 30))!
        XCTAssertEqual(EarningsEngine.hoursBetween(start, end), Decimal(string: "4.75"))
    }

    func testSpringForwardNightIsTwentyThreeClockHours() {
        // US spring-forward 2026: clocks jump forward at 2:00am on 2026-03-08
        // in America/New_York, so a shift spanning midnight to the next
        // morning loses one real hour compared to a normal night.
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let start = newYork.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 22, minute: 0))!
        let end = newYork.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 22, minute: 0))!
        // 24 wall-clock hours minus the 1 hour skipped by spring-forward = 23 real hours.
        XCTAssertEqual(EarningsEngine.hoursBetween(start, end), Decimal(23))
    }

    func testFallBackNightIsTwentyFiveClockHours() {
        // US fall-back 2026: clocks fall back at 2:00am on 2026-11-01 in
        // America/New_York, so the same wall-clock span gains one real hour.
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!
        let start = newYork.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 22, minute: 0))!
        let end = newYork.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 22, minute: 0))!
        XCTAssertEqual(EarningsEngine.hoursBetween(start, end), Decimal(25))
    }

    func testDoubleAndFloatNeverAppearInTheEarningsModule() throws {
        let url = try XCTUnwrap(sourceFileURL(named: "EarningsEngine.swift"))
        let source = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(source.contains(": Double"), "Double must never appear in the earnings module")
        XCTAssertFalse(source.contains(": Float"), "Float must never appear in the earnings module")
    }

    func testDoubleAndFloatNeverAppearInTheTipOutModule() throws {
        let url = try XCTUnwrap(sourceFileURL(named: "TipOutTypes.swift"))
        let source = try String(contentsOf: url, encoding: .utf8)
        XCTAssertFalse(source.contains(": Double"), "Double must never appear in the tip-out module")
        XCTAssertFalse(source.contains(": Float"), "Float must never appear in the tip-out module")
    }
}

/// Locates a Sources file by name relative to this test file, so a source
/// scan test works without embedding the source as a test resource.
func sourceFileURL(named fileName: String) -> URL? {
    var url = URL(fileURLWithPath: #filePath)
    for _ in 0..<2 { url.deleteLastPathComponent() }
    let candidates = ["Core", "Monetisation", "Features", ""]
    for folder in candidates {
        let candidate = url.appendingPathComponent("Sources").appendingPathComponent(folder).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
    }
    return nil
}
