import Foundation

/// Turns a solver screen's free-text field into a Length, in whatever unit
/// the user's preferred system implies (decimal feet for imperial, the
/// chosen metric unit for metric) -- shared so every solver screen parses
/// input identically.
enum InputParsing {
    static func length(_ text: String, settings: AppSettings) -> Length? {
        guard let value = DecimalParsing.parse(text), !value.isNegative else { return nil }
        let unit: LengthUnit = settings.preferredSystem == .imperial ? .feet : settings.preferredMetricUnit
        return Length(value, unit)
    }

    static func rational(_ text: String) -> Rational? {
        guard let value = DecimalParsing.parse(text), !value.isNegative else { return nil }
        return value
    }
}
