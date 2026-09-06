import Foundation

/// Turns the price book into an RFC 4180 CSV, encoded UTF-8 with a leading
/// byte-order mark so spreadsheets pick the encoding up automatically, dates
/// in ISO 8601 and numbers with a period decimal separator regardless of the
/// device's locale. Import is deliberately out of scope for V1; this is a
/// one-way door for spreadsheet users to leave with their data.
enum CSVExport {
    static let header = ["item", "brand", "category", "store", "date", "package_size", "unit",
                          "paid_price", "unit_price", "currency", "sale", "loyalty"]

    struct Row {
        let itemName: String
        let brand: String
        let category: String
        let storeName: String
        let date: Date
        let packageSize: Decimal
        let unit: String
        let paidPrice: Decimal
        let unitPrice: Decimal
        let currencyCode: String
        let isSale: Bool
        let isLoyalty: Bool
    }

    static func csvString(rows: [Row]) -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [header.map(field).joined(separator: ",")]
        for row in rows {
            let fields: [String] = [
                row.itemName, row.brand, row.category, row.storeName,
                formatter.string(from: row.date),
                decimalString(row.packageSize), row.unit,
                decimalString(row.paidPrice), decimalString(row.unitPrice), row.currencyCode,
                row.isSale ? "true" : "false", row.isLoyalty ? "true" : "false",
            ]
            lines.append(fields.map(field).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    /// UTF-8 text prefixed with the byte-order mark (EF BB BF).
    static func data(rows: [Row]) -> Data {
        let bom = Data([0xEF, 0xBB, 0xBF])
        return bom + Data(csvString(rows: rows).utf8)
    }

    /// `NSDecimalNumber.stringValue` is documented locale-independent (always
    /// a period), unlike `Decimal`'s `description` in some configurations.
    private static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    /// RFC 4180 quoting: wrap in double quotes and escape embedded quotes
    /// whenever the field contains a comma, quote or line break.
    private static func field(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// A minimal RFC 4180 parser, used only by the round-trip unit test to prove
/// the export can be read back byte-for-byte.
enum CSVParser {
    static func parse(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var insideQuotes = false
        var iterator = csv.makeIterator()
        var pending: Character?

        func nextChar() -> Character? {
            if let pending {
                pendingReset()
                return pending
            }
            return iterator.next()
        }
        func pendingReset() { pending = nil }

        while let char = nextChar() {
            if insideQuotes {
                if char == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" {
                            currentField.append("\"")
                        } else {
                            insideQuotes = false
                            pending = next
                        }
                    } else {
                        insideQuotes = false
                    }
                } else {
                    currentField.append(char)
                }
            } else {
                switch char {
                case "\"":
                    insideQuotes = true
                case ",":
                    currentRow.append(currentField)
                    currentField = ""
                case "\r":
                    continue
                case "\n":
                    currentRow.append(currentField)
                    rows.append(currentRow)
                    currentRow = []
                    currentField = ""
                default:
                    currentField.append(char)
                }
            }
        }
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }
        return rows
    }
}
