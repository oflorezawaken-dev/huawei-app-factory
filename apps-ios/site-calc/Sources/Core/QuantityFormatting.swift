import Foundation

/// Display formatting shared by the tape, the solver screens, and both export
/// formats, so a value is never rendered two different ways in the same app.
enum QuantityFormatting {
    static func display(_ quantity: Quantity, precision: FractionPrecision, system: MeasurementSystem,
                         metricUnit: LengthUnit, locale: Locale = .current) -> String {
        switch quantity {
        case .length(let length):
            if system == .imperial {
                return LengthFormatting.feetInchFraction(length, precision: precision)
            } else {
                return LengthFormatting.decimal(length, unit: metricUnit, decimalPlaces: 2, locale: locale) +
                    " " + unitSuffix(metricUnit)
            }
        case .area(let area):
            let unit: LengthUnit = system == .imperial ? .feet : metricUnit
            let value = area.converted(to: unit)
            return LengthFormatting.decimalString(value, decimalPlaces: 2, locale: locale) + " sq " + unitSuffix(unit)
        case .volume(let volume):
            let unit: LengthUnit = system == .imperial ? .feet : metricUnit
            let value = volume.converted(to: unit)
            return LengthFormatting.decimalString(value, decimalPlaces: 2, locale: locale) + " cu " + unitSuffix(unit)
        case .count(let rational):
            return LengthFormatting.decimalString(rational, decimalPlaces: 4, locale: locale)
        }
    }

    static func unitSuffix(_ unit: LengthUnit) -> String {
        switch unit {
        case .feet: return "ft"
        case .inches: return "in"
        case .yard: return "yd"
        case .meter: return "m"
        case .centimeter: return "cm"
        case .millimeter: return "mm"
        }
    }

    /// Exact decimal value in inches, to a fixed number of places, with a
    /// period separator regardless of device locale -- used by CSV export,
    /// which must be locale-independent (qa acceptance criteria).
    static func exactInches(_ quantity: Quantity) -> String {
        let posix = Locale(identifier: "en_US_POSIX")
        switch quantity {
        case .length(let l): return LengthFormatting.decimalString(l.inches, decimalPlaces: 6, locale: posix)
        case .area(let a): return LengthFormatting.decimalString(a.squareInches, decimalPlaces: 6, locale: posix)
        case .volume(let v): return LengthFormatting.decimalString(v.cubicInches, decimalPlaces: 6, locale: posix)
        case .count(let c): return LengthFormatting.decimalString(c, decimalPlaces: 6, locale: posix)
        }
    }

    /// Exact decimal value in millimetres (or square/cubic millimetres),
    /// again with a period separator regardless of locale. Meaningless for a
    /// dimensionless count, which reports the same value as `exactInches`.
    static func exactMillimeters(_ quantity: Quantity) -> String {
        let posix = Locale(identifier: "en_US_POSIX")
        switch quantity {
        case .length(let l): return LengthFormatting.decimalString(l.converted(to: .millimeter),
                                                                     decimalPlaces: 3, locale: posix)
        case .area(let a):
            let mmPerIn = LengthUnit.millimeter.inchesPerUnit
            return LengthFormatting.decimalString(a.squareInches / (mmPerIn * mmPerIn), decimalPlaces: 3, locale: posix)
        case .volume(let v):
            let mmPerIn = LengthUnit.millimeter.inchesPerUnit
            return LengthFormatting.decimalString(v.cubicInches / (mmPerIn * mmPerIn * mmPerIn),
                                                    decimalPlaces: 3, locale: posix)
        case .count(let c): return LengthFormatting.decimalString(c, decimalPlaces: 6, locale: posix)
        }
    }

    static func unitLabel(_ quantity: Quantity) -> String {
        switch quantity {
        case .length: return "length"
        case .area: return "area"
        case .volume: return "volume"
        case .count: return "count"
        }
    }
}
