import XCTest
@testable import ShiftSlip

final class PayPeriodEngineTests: XCTestCase {
    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    // MARK: - Basic window shape

    func testWeeklyWindowIsSevenDaysStartingOnTheChosenWeekday() {
        // 2026-03-04 is a Wednesday (weekday 4). Start weekday = Sunday (1).
        let date = utc.date(from: DateComponents(year: 2026, month: 3, day: 4))!
        let window = PayPeriodEngine.window(containing: date, cycle: .weekly(startWeekday: 1), calendar: utc)
        let expectedStart = utc.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        XCTAssertEqual(window.start, expectedStart)
        XCTAssertEqual(window.duration, 7 * 86400)
    }

    func testSemimonthlyFirstHalf() {
        let date = utc.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        let window = PayPeriodEngine.window(containing: date, cycle: .semimonthly, calendar: utc)
        XCTAssertEqual(window.start, utc.date(from: DateComponents(year: 2026, month: 4, day: 1))!)
        XCTAssertEqual(window.end, utc.date(from: DateComponents(year: 2026, month: 4, day: 16))!)
    }

    func testSemimonthlySecondHalfCrossesIntoNextMonth() {
        let date = utc.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let window = PayPeriodEngine.window(containing: date, cycle: .semimonthly, calendar: utc)
        XCTAssertEqual(window.start, utc.date(from: DateComponents(year: 2026, month: 4, day: 16))!)
        XCTAssertEqual(window.end, utc.date(from: DateComponents(year: 2026, month: 5, day: 1))!)
    }

    func testMonthlyWindowSpansTheWholeMonth() {
        let date = utc.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let window = PayPeriodEngine.window(containing: date, cycle: .monthly, calendar: utc)
        XCTAssertEqual(window.start, utc.date(from: DateComponents(year: 2026, month: 2, day: 1))!)
        XCTAssertEqual(window.end, utc.date(from: DateComponents(year: 2026, month: 3, day: 1))!)
    }

    func testBiweeklyWindowsAreFourteenDaysFromTheAnchor() {
        let anchor = utc.date(from: DateComponents(year: 2026, month: 1, day: 4))!
        let date = utc.date(from: DateComponents(year: 2026, month: 1, day: 20))!
        let window = PayPeriodEngine.window(containing: date, cycle: .biweekly(anchorDate: anchor), calendar: utc)
        XCTAssertEqual(window.start, utc.date(from: DateComponents(year: 2026, month: 1, day: 18))!)
        XCTAssertEqual(window.duration, 14 * 86400)
    }

    func testBiweeklyWindowBeforeTheAnchorRoundsDownNotTowardZero() {
        let anchor = utc.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let date = utc.date(from: DateComponents(year: 2026, month: 1, day: 10))!
        let window = PayPeriodEngine.window(containing: date, cycle: .biweekly(anchorDate: anchor), calendar: utc)
        XCTAssertEqual(window.start, utc.date(from: DateComponents(year: 2026, month: 1, day: 1))!)
    }

    // MARK: - Every shift lands in exactly one window, for all four cycles,
    // across a 2-year, 400-shift fixture spanning the 2028 leap day.

    func testTwoYearFixtureAssignsEveryShiftToExactlyOneWindowForEveryCycle() {
        let start = utc.date(from: DateComponents(year: 2027, month: 6, day: 1))!
        var dates: [Date] = []
        // 400 shifts, spaced roughly every 1.8 days across ~2 years (730 days),
        // deterministically generated so the run is reproducible.
        for i in 0..<400 {
            let offsetDays = Int((Double(i) * 1.826).rounded())
            dates.append(utc.date(byAdding: .day, value: offsetDays, to: start)!)
        }
        // Sanity: the fixture's span crosses the 2028 leap day.
        XCTAssertNotNil(utc.date(from: DateComponents(year: 2028, month: 2, day: 29)))
        XCTAssertTrue(dates.contains { $0 >= utc.date(from: DateComponents(year: 2028, month: 2, day: 1))! })

        let fixtureTotal = Decimal(dates.count) * 100 // each shift contributes exactly 100 to totalPay
        let inputs = dates.map { date in
            RollupInput(jobID: UUID(), assignedDate: date,
                        figures: ShiftFigures(hours: 1, baseRate: 100, cashTips: 0, chargeTips: 0, tipOutTotal: 0, sales: nil))
        }

        let cycles: [PayPeriodCycle] = [
            .weekly(startWeekday: 1),
            .biweekly(anchorDate: start),
            .semimonthly,
            .monthly,
        ]

        for cycle in cycles {
            let rollups = RollupEngine.byPeriod(inputs, cycle: cycle, calendar: utc)
            let summedTotal = rollups.values.reduce(Decimal(0)) { $0 + $1.totalPay }
            let summedCount = rollups.values.reduce(0) { $0 + $1.shiftCount }
            XCTAssertEqual(summedTotal, fixtureTotal, "cycle \(cycle) lost or double-counted a shift's pay")
            XCTAssertEqual(summedCount, dates.count, "cycle \(cycle) lost or double-counted a shift")

            // No two windows overlap: sort windows by start and check each
            // window's end <= the next window's start.
            let windows = rollups.keys.sorted { $0.start < $1.start }
            for pair in zip(windows, windows.dropFirst()) {
                XCTAssertLessThanOrEqual(pair.0.end, pair.1.start, "cycle \(cycle) produced overlapping windows")
            }
        }
    }

    func testDirectComparisonAgainstUngroupedTotalForAllFourCycles() {
        let calendar = utc
        var inputs: [RollupInput] = []
        var date = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        for i in 0..<400 {
            inputs.append(RollupInput(jobID: UUID(), assignedDate: date,
                                       figures: ShiftFigures(hours: 1, baseRate: Decimal(i % 20 + 10), cashTips: 5,
                                                              chargeTips: 5, tipOutTotal: 1, sales: nil)))
            date = calendar.date(byAdding: .day, value: 2, to: date)!
        }
        let ungroupedTotal = RollupEngine.total(inputs)
        for cycle: PayPeriodCycle in [.weekly(startWeekday: 1), .biweekly(anchorDate: inputs[0].assignedDate), .semimonthly, .monthly] {
            let grouped = RollupEngine.byPeriod(inputs, cycle: cycle, calendar: calendar)
            let groupedTotal = grouped.values.reduce(Decimal(0)) { $0 + $1.totalPay }
            XCTAssertEqual(groupedTotal, ungroupedTotal.totalPay)
        }
    }
}
