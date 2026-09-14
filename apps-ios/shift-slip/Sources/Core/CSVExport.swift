import Foundation

/// One exported shift row (F009). Free forever, behind no purchase: with no
/// cloud sync in V1 this is also the app's backup story.
struct CSVShiftRow {
    let date: Date
    let jobName: String
    let employerName: String
    let businessName: String
    let hours: Decimal
    let baseRate: Decimal
    let basePay: Decimal
    let cashTips: Decimal
    let chargeTips: Decimal
    let noncashTips: Decimal
    let serviceCharges: Decimal
    let tipOutTotal: Decimal
    let recipientShares: [TipOutRecipientShare]
    let tipsKept: Decimal
    let totalPay: Decimal
    let effectiveHourly: Decimal?
    let sales: Decimal?
    let isSample: Bool
}

/// Turns a range of shifts into an RFC 4180 CSV: UTF-8 with a leading
/// byte-order mark so spreadsheets pick the encoding up automatically, ISO
/// 8601 dates, and a period decimal separator regardless of the device's
/// locale. One column per named tip-out recipient, so the split is visible
/// without opening the app.
enum CSVExport {
    static let fixedHeader = [
        "date", "job", "employer", "business_name", "hours", "base_rate", "base_pay",
        "cash_tips", "charge_tips", "noncash_tips", "service_charges", "auto_gratuities",
        "tip_out_total", "tips_kept", "total_pay", "effective_hourly", "sales", "sample",
    ]

    static func csvString(rows: [CSVShiftRow]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        // Recipient columns are the union of every recipient name across the
        // exported range, in first-seen order, so a job with more recipients
        // than another still produces one rectangular table.
        var recipientNames: [String] = []
        for row in rows {
            for share in row.recipientShares where !recipientNames.contains(share.name) {
                recipientNames.append(share.name)
            }
        }
        let header = fixedHeader + recipientNames.map { "tipout_\($0)" }
        var lines = [header.map(field).joined(separator: ",")]

        for row in rows {
            var fields: [String] = [
                formatter.string(from: row.date),
                row.jobName, row.employerName, row.businessName,
                decimalString(row.hours), decimalString(row.baseRate), decimalString(row.basePay),
                decimalString(row.cashTips), decimalString(row.chargeTips), decimalString(row.noncashTips),
                row.serviceCharges > 0 ? decimalString(row.serviceCharges) : "0",
                "0", // reserved: auto-gratuities are folded into serviceCharges upstream
                decimalString(row.tipOutTotal), decimalString(row.tipsKept), decimalString(row.totalPay),
                row.effectiveHourly.map(decimalString) ?? "",
                row.sales.map(decimalString) ?? "",
                row.isSample ? "true" : "false",
            ]
            for name in recipientNames {
                let amount = row.recipientShares.first { $0.name == name }?.resolvedAmount
                fields.append(amount.map(decimalString) ?? "")
            }
            lines.append(fields.map(field).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    static func data(rows: [CSVShiftRow]) -> Data {
        let bom = Data([0xEF, 0xBB, 0xBF])
        return bom + Data(csvString(rows: rows).utf8)
    }

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
            if let value = pending {
                pending = nil
                return value
            }
            return iterator.next()
        }

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
                case "\r\n", "\n":
                    // Swift's Character is an extended grapheme cluster, so
                    // "\r\n" from `csvString`'s CRLF line endings arrives as
                    // ONE Character equal to neither "\r" nor "\n" alone --
                    // matching only "\n" here would silently swallow every row
                    // break into the next field's text.
                    currentRow.append(currentField)
                    rows.append(currentRow)
                    currentRow = []
                    currentField = ""
                case "\r":
                    continue
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
