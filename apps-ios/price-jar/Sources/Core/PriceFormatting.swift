import Foundation

/// Renders a `Decimal` amount and a unit-price suffix the way a shopper
/// reads a shelf tag. Kept separate from `UnitNormalization` because this is
/// presentation, not arithmetic: nothing here ever feeds back into a
/// calculation.
enum PriceFormatting {
    static func currencyAmount(_ value: Decimal, symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        let text = formatter.string(from: NSDecimalNumber(decimal: value)) ?? NSDecimalNumber(decimal: value).stringValue
        return "\(symbol)\(text)"
    }

    /// A unit price with its display-unit suffix, e.g. "$2.40/kg".
    static func string(_ unitPrice: Decimal, symbol: String, displayUnit: DisplayUnit) -> String {
        "\(currencyAmount(unitPrice, symbol: symbol))\(suffix(for: displayUnit))"
    }

    /// Unit abbreviations are not translated: "kg", "L" and "fl oz" read the
    /// same shorthand in every supported language, the way they do on a
    /// physical shelf tag.
    static func suffix(for displayUnit: DisplayUnit) -> String {
        switch displayUnit {
        case .perKilogram: return "/kg"
        case .per100Grams: return "/100g"
        case .perPound: return "/lb"
        case .perLiter: return "/L"
        case .per100Milliliters: return "/100mL"
        case .perFluidOunce: return "/fl oz"
        case .perItem: return "/item"
        }
    }

    static func percent(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = "+"
        let text = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        return "\(text)%"
    }
}

extension MeasurementUnit {
    /// Localizable.xcstrings key for this unit's picker label.
    var localizationKey: String { "unit.\(rawValue)" }
}

extension DisplayUnit {
    /// Localizable.xcstrings key for this display unit's picker label.
    var localizationKey: String { "displayUnit.\(rawValue)" }
}
