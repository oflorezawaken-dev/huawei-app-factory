import XCTest
@testable import ShiftSlip

final class CSVExportTests: XCTestCase {
    private func row(job: String = "The Grove Bistro, LLC", employer: String = "Employer \"A\"",
                      cash: Decimal = 30, charge: Decimal = 90) -> CSVShiftRow {
        CSVShiftRow(date: Date(timeIntervalSince1970: 1_780_000_000), jobName: job, employerName: employer,
                    businessName: "Business", hours: 5, baseRate: 2.13, basePay: Decimal(string: "10.65")!,
                    cashTips: cash, chargeTips: charge, noncashTips: 0, serviceCharges: 0,
                    tipOutTotal: 5, recipientShares: [TipOutRecipientShare(name: "Bar", type: .percentOfTips, value: 5, resolvedAmount: 5)],
                    tipsKept: 115, totalPay: Decimal(string: "125.65")!, effectiveHourly: Decimal(string: "25.13")!,
                    sales: 500, isSample: false)
    }

    func testRoundTripThroughAnRFC4180ParserProducesIdenticalValues() {
        let rows = [row(), row(job: "Roasted, Coffee Co.", employer: "Café Employer"), row(cash: 0, charge: 0)]
        let csv = CSVExport.csvString(rows: rows)
        let parsed = CSVParser.parse(csv)
        XCTAssertEqual(parsed.count, rows.count + 1) // header + rows
        XCTAssertEqual(parsed[1][1], "The Grove Bistro, LLC")
        XCTAssertEqual(parsed[1][2], "Employer \"A\"")
        XCTAssertEqual(parsed[2][1], "Roasted, Coffee Co.")
        XCTAssertEqual(parsed[2][2], "Café Employer")
    }

    func testNonASCIIJobNamesSurviveRoundTrip() {
        let rows = [row(job: "Café Müller"), row(job: "北京饭店")]
        let csv = CSVExport.csvString(rows: rows)
        let parsed = CSVParser.parse(csv)
        XCTAssertEqual(parsed[1][1], "Café Müller")
        XCTAssertEqual(parsed[2][1], "北京饭店")
    }

    func testDataHasUTF8BOMPrefix() {
        let data = CSVExport.data(rows: [row()])
        XCTAssertEqual(Array(data.prefix(3)), [0xEF, 0xBB, 0xBF])
    }

    func testDecimalSeparatorIsAlwaysAPeriodRegardlessOfLocale() {
        let csv = CSVExport.csvString(rows: [row(cash: Decimal(string: "30.50")!)])
        XCTAssertTrue(csv.contains("30.5"))
        XCTAssertFalse(csv.contains("30,5"))
    }

    func testRecipientColumnsAreTheUnionAcrossAllExportedRows() {
        var rowA = row()
        var rowB = row()
        // Build rows with different recipient names to prove column union.
        rowA = CSVShiftRow(date: rowA.date, jobName: rowA.jobName, employerName: rowA.employerName,
                            businessName: rowA.businessName, hours: rowA.hours, baseRate: rowA.baseRate,
                            basePay: rowA.basePay, cashTips: rowA.cashTips, chargeTips: rowA.chargeTips,
                            noncashTips: rowA.noncashTips, serviceCharges: rowA.serviceCharges,
                            tipOutTotal: rowA.tipOutTotal,
                            recipientShares: [TipOutRecipientShare(name: "Bar", type: .percentOfTips, value: 5, resolvedAmount: 5)],
                            tipsKept: rowA.tipsKept, totalPay: rowA.totalPay, effectiveHourly: rowA.effectiveHourly,
                            sales: rowA.sales, isSample: rowA.isSample)
        rowB = CSVShiftRow(date: rowB.date, jobName: rowB.jobName, employerName: rowB.employerName,
                            businessName: rowB.businessName, hours: rowB.hours, baseRate: rowB.baseRate,
                            basePay: rowB.basePay, cashTips: rowB.cashTips, chargeTips: rowB.chargeTips,
                            noncashTips: rowB.noncashTips, serviceCharges: rowB.serviceCharges,
                            tipOutTotal: rowB.tipOutTotal,
                            recipientShares: [TipOutRecipientShare(name: "Busser", type: .percentOfTips, value: 3, resolvedAmount: 3)],
                            tipsKept: rowB.tipsKept, totalPay: rowB.totalPay, effectiveHourly: rowB.effectiveHourly,
                            sales: rowB.sales, isSample: rowB.isSample)
        let csv = CSVExport.csvString(rows: [rowA, rowB])
        XCTAssertTrue(csv.contains("tipout_Bar"))
        XCTAssertTrue(csv.contains("tipout_Busser"))
    }

    func test120ShiftThreeMonthFixtureParsesBackToIdenticalValues() {
        var rows: [CSVShiftRow] = []
        for i in 0..<120 {
            rows.append(row(job: "Job \(i % 2), \"quoted\"", cash: Decimal(i), charge: Decimal(i) * 2))
        }
        let csv = CSVExport.csvString(rows: rows)
        let parsed = CSVParser.parse(csv)
        XCTAssertEqual(parsed.count, 121)
        for (index, row) in rows.enumerated() {
            XCTAssertEqual(parsed[index + 1][1], row.jobName)
            XCTAssertEqual(parsed[index + 1][7], NSDecimalNumber(decimal: row.cashTips).stringValue)
        }
    }
}
