import Foundation

/// Formats a `Decimal` money amount using a job or Settings' own currency
/// code, independent of the device locale -- ShiftSlip does no currency
/// conversion, so the number and the symbol must always agree with what the
/// user typed them as.
enum CurrencyFormatting {
    static func string(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? amount.fixedPointString
    }

    /// A dash for the "not applicable" state (zero hours, no sales entered).
    static func stringOrDash(_ amount: Decimal?, currencyCode: String) -> String {
        guard let amount else { return "\u{2014}" }
        return string(amount, currencyCode: currencyCode)
    }

    static func hours(_ hours: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter.string(from: NSDecimalNumber(decimal: hours)) ?? hours.fixedPointString
    }

    static func percentage(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        let text = formatter.string(from: NSDecimalNumber(decimal: value)) ?? value.fixedPointString
        return text + "%"
    }
}
