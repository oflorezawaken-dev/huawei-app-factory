import XCTest
@testable import PriceJar

final class CSVExportTests: XCTestCase {
    private func d(_ s: String) -> Decimal { Decimal(string: s)! }

    private func makeFixture(stores: Int, items: Int, entriesPerItem: Int) -> [CSVExport.Row] {
        var rows: [CSVExport.Row] = []
        let calendar = Calendar(identifier: .gregorian)
        for itemIndex in 0..<items {
            // Non-ASCII names, embedded commas and quotes -- exactly the
            // characters RFC 4180 quoting exists to handle.
            let name = "Caf\u{00e9}, \"Special\" Item \(itemIndex)"
            for entryIndex in 0..<entriesPerItem {
                let store = "Store \(entryIndex % stores)"
                let date = calendar.date(byAdding: .day, value: -entryIndex, to: Date(timeIntervalSince1970: 1_780_000_000))!
                rows.append(CSVExport.Row(
                    itemName: name, brand: "Br\u{00e4}nd", category: "pantry", storeName: store, date: date,
                    packageSize: d("1.5"), unit: "kilogram", paidPrice: d("3.99"), unitPrice: d("2.6600"),
                    currencyCode: "USD", isSale: entryIndex % 2 == 0, isLoyalty: entryIndex % 3 == 0))
            }
        }
        return rows
    }

    func testRoundTripPreservesEveryField() {
        let rows = makeFixture(stores: 3, items: 20, entriesPerItem: 6)
        let csv = CSVExport.csvString(rows: rows)
        let parsed = CSVParser.parse(csv)

        XCTAssertEqual(parsed.count, rows.count + 1, "header plus one row per entry")
        XCTAssertEqual(parsed[0], CSVExport.header)

        for (index, row) in rows.enumerated() {
            let fields = parsed[index + 1]
            XCTAssertEqual(fields[0], row.itemName)
            XCTAssertEqual(fields[1], row.brand)
            XCTAssertEqual(fields[2], row.category)
            XCTAssertEqual(fields[3], row.storeName)
            XCTAssertEqual(fields[5], "1.5")
            XCTAssertEqual(fields[6], "kilogram")
            XCTAssertEqual(fields[7], "3.99")
            XCTAssertEqual(fields[8], "2.66")
            XCTAssertEqual(fields[9], row.currencyCode)
            XCTAssertEqual(fields[10], row.isSale ? "true" : "false")
            XCTAssertEqual(fields[11], row.isLoyalty ? "true" : "false")
        }
    }

    func test120EntryFixtureRoundTripsExactly() {
        let rows = makeFixture(stores: 3, items: 20, entriesPerItem: 6)
        XCTAssertEqual(rows.count, 120)
        let parsed = CSVParser.parse(CSVExport.csvString(rows: rows))
        XCTAssertEqual(parsed.count, 121)
    }

    func testDataHasUTF8BOMPrefix() {
        let data = CSVExport.data(rows: [])
        XCTAssertEqual(Array(data.prefix(3)), [0xEF, 0xBB, 0xBF])
    }

    func testDatesAreISO8601() {
        let date = Date(timeIntervalSince1970: 1_780_000_000)
        let row = CSVExport.Row(itemName: "X", brand: "", category: "other", storeName: "S", date: date,
                                 packageSize: 1, unit: "item", paidPrice: 1, unitPrice: 1,
                                 currencyCode: "USD", isSale: false, isLoyalty: false)
        let csv = CSVExport.csvString(rows: [row])
        let fields = CSVParser.parse(csv)[1]
        XCTAssertTrue(fields[4].contains("T"))
        XCTAssertTrue(fields[4].hasSuffix("Z"))
    }

    func testDecimalSeparatorIsAlwaysAPeriodRegardlessOfLocale() {
        let row = CSVExport.Row(itemName: "X", brand: "", category: "other", storeName: "S", date: .now,
                                 packageSize: d("1234.56"), unit: "gram", paidPrice: d("9.99"), unitPrice: d("0.0081"),
                                 currencyCode: "EUR", isSale: false, isLoyalty: false)
        let csv = CSVExport.csvString(rows: [row])
        XCTAssertTrue(csv.contains("1234.56"))
        XCTAssertFalse(csv.contains("1234,56"))
    }

    func testFieldsWithCommasAreQuoted() {
        let csv = CSVExport.csvString(rows: [rowNamed("A, B")])
        XCTAssertTrue(csv.contains("\"A, B\""))
    }

    func testFieldsWithQuotesAreEscaped() {
        let csv = CSVExport.csvString(rows: [rowNamed("A \"B\" C")])
        XCTAssertTrue(csv.contains("\"A \"\"B\"\" C\""))
    }

    func testPlainFieldsAreNotQuoted() {
        let csv = CSVExport.csvString(rows: [rowNamed("Plain")])
        let firstLine = csv.split(separator: "\r\n")[1]
        XCTAssertTrue(firstLine.hasPrefix("Plain,"))
    }

    private func rowNamed(_ name: String) -> CSVExport.Row {
        CSVExport.Row(itemName: name, brand: "", category: "other", storeName: "S", date: .now,
                      packageSize: 1, unit: "item", paidPrice: 1, unitPrice: 1,
                      currencyCode: "USD", isSale: false, isLoyalty: false)
    }
}
