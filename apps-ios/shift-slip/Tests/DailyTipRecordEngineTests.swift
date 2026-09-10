import XCTest
@testable import ShiftSlip

final class DailyTipRecordEngineTests: XCTestCase {
    private var utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    func testSplitShiftsAcrossTwoJobsOnOneDaySumCorrectlyIntoTwoLines() {
        let day = utc.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let jobA = UUID(), jobB = UUID()
        let inputs = [
            DailyTipRecordInput(date: day, jobID: jobA, employerName: "A", businessName: "A", cashTips: 10,
                                 chargeTips: 20, noncashTips: 0, tipOutTotal: 2, serviceCharges: 0, isSample: false),
            DailyTipRecordInput(date: day, jobID: jobA, employerName: "A", businessName: "A", cashTips: 5,
                                 chargeTips: 15, noncashTips: 0, tipOutTotal: 1, serviceCharges: 0, isSample: false),
            DailyTipRecordInput(date: day, jobID: jobB, employerName: "B", businessName: "B", cashTips: 8,
                                 chargeTips: 12, noncashTips: 0, tipOutTotal: 0, serviceCharges: 3, isSample: false),
        ]
        let lines = DailyTipRecordEngine.lines(from: inputs, calendar: utc)
        XCTAssertEqual(lines.count, 2)
        let lineA = lines.first { $0.jobID == jobA }!
        XCTAssertEqual(lineA.cashTips, 15)
        XCTAssertEqual(lineA.chargeTips, 35)
        XCTAssertEqual(lineA.tipsPaidOut, 3)
        let lineB = lines.first { $0.jobID == jobB }!
        XCTAssertEqual(lineB.serviceCharges, 3)
    }

    func testFieldsMatchPublication531ExactlyAndServiceChargesStayOutsideTipFields() {
        let day = utc.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let inputs = [DailyTipRecordInput(date: day, jobID: UUID(), employerName: "E", businessName: "B",
                                           cashTips: 10, chargeTips: 20, noncashTips: 5, tipOutTotal: 2,
                                           serviceCharges: 7, isSample: false)]
        let line = DailyTipRecordEngine.lines(from: inputs, calendar: utc)[0]
        XCTAssertEqual(line.cashTips, 10)
        XCTAssertEqual(line.chargeTips, 20)
        XCTAssertEqual(line.noncashTips, 5)
        XCTAssertEqual(line.tipsPaidOut, 2)
        XCTAssertEqual(line.serviceCharges, 7)
        // Service charges never enter the tip fields.
        XCTAssertEqual(line.cashTips + line.chargeTips, 30)
    }

    func testDueDateMarkerShowsOnlyFromThe1stToThe10thInclusive() {
        let closingMonth = utc.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let expectedDue = utc.date(from: DateComponents(year: 2026, month: 6, day: 10))!

        let first = utc.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        XCTAssertEqual(DailyTipRecordEngine.employerReportDueDate(closingMonth: closingMonth, today: first, calendar: utc), expectedDue)

        let tenth = utc.date(from: DateComponents(year: 2026, month: 6, day: 10))!
        XCTAssertEqual(DailyTipRecordEngine.employerReportDueDate(closingMonth: closingMonth, today: tenth, calendar: utc), expectedDue)

        let eleventh = utc.date(from: DateComponents(year: 2026, month: 6, day: 11))!
        XCTAssertNil(DailyTipRecordEngine.employerReportDueDate(closingMonth: closingMonth, today: eleventh, calendar: utc))

        let lastDayOfPriorMonth = utc.date(from: DateComponents(year: 2026, month: 5, day: 31))!
        XCTAssertNil(DailyTipRecordEngine.employerReportDueDate(closingMonth: closingMonth, today: lastDayOfPriorMonth, calendar: utc))
    }

    func testMonthTotalSumsAcrossAllLines() {
        let day1 = utc.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let day2 = utc.date(from: DateComponents(year: 2026, month: 6, day: 2))!
        let jobID = UUID()
        let inputs = [
            DailyTipRecordInput(date: day1, jobID: jobID, employerName: "E", businessName: "B", cashTips: 10,
                                 chargeTips: 10, noncashTips: 0, tipOutTotal: 2, serviceCharges: 0, isSample: false),
            DailyTipRecordInput(date: day2, jobID: jobID, employerName: "E", businessName: "B", cashTips: 20,
                                 chargeTips: 20, noncashTips: 0, tipOutTotal: 4, serviceCharges: 0, isSample: false),
        ]
        let lines = DailyTipRecordEngine.lines(from: inputs, calendar: utc)
        let total = DailyTipRecordEngine.monthTotal(lines)
        XCTAssertEqual(total.voluntaryTips, 60)
        XCTAssertEqual(total.tipsKept, 54)
    }
}
