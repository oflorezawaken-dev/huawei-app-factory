import Foundation

/// The fraction precisions the user can choose, 1/2 through 1/64 (F003).
/// Display-only: it never touches the stored Rational value.
enum FractionPrecision: Int, CaseIterable, Codable {
    case half = 2, quarter = 4, eighth = 8, sixteenth = 16, thirtySecond = 32, sixtyFourth = 64

    var denominator: Int { rawValue }
}

/// Formats the exact dimensional type for display. Rounding happens only
/// here, at the boundary between the exact stored value and the string shown
/// to the user -- the Length/Rational it is given is never mutated by it.
enum LengthFormatting {
    static func feetInchFraction(_ length: Length, precision: FractionPrecision) -> String {
        let negative = length.inches.isNegative
        let magnitude = negative ? -length.inches : length.inches
        let rounded = magnitude.rounded(toNearestFractionOf: precision.denominator)
        let wholeInches = rounded.floorValue
        let fractionPart = rounded - Rational(wholeInches)
        let feet = wholeInches / 12
        let inches = wholeInches % 12

        let body: String
        if fractionPart.isZero {
            body = "\(inches)\""
        } else if inches == 0 && feet == 0 {
            // Three eighths of an inch reads as 3/8", not 0-3/8". The leading
            // zero is correct and looks like a typo, and it went out in a store
            // screenshot ("would fall 0-3/8\" short of the total rise").
            body = "\(fractionPart.numerator)/\(fractionPart.denominator)\""
        } else {
            body = "\(inches)-\(fractionPart.numerator)/\(fractionPart.denominator)\""
        }
        let result = feet != 0 ? "\(feet)' \(body)" : body
        return negative ? "-\(result)" : result
    }

    /// Decimal display in a chosen unit, rounded to `decimalPlaces`, using the
    /// given locale's decimal separator. Rounding happens only in this string;
    /// the underlying Rational is untouched.
    static func decimal(_ length: Length, unit: LengthUnit, decimalPlaces: Int, locale: Locale = .current) -> String {
        decimalString(length.converted(to: unit), decimalPlaces: decimalPlaces, locale: locale)
    }

    static func decimalString(_ value: Rational, decimalPlaces: Int, locale: Locale = .current) -> String {
        precondition(decimalPlaces >= 0)
        let scale = Int(pow(10.0, Double(decimalPlaces)))
        let scaledRounded = (value * Rational(scale)).roundedToNearestInt
        let negative = scaledRounded < 0
        let magnitude = abs(scaledRounded)
        let whole = magnitude / scale
        let frac = magnitude % scale
        let sep = locale.decimalSeparator ?? "."
        let result: String
        if decimalPlaces > 0 {
            let fracString = String(format: "%0\(decimalPlaces)d", frac)
            result = "\(whole)\(sep)\(fracString)"
        } else {
            result = "\(whole)"
        }
        return negative ? "-\(result)" : result
    }
}

/// Speaks a dimensional value as words for VoiceOver, e.g. "fourteen feet
/// three and five eighths inches" (F015). Numbers go through NumberFormatter's
/// spellOut style so this reads correctly in every supported locale; the
/// fraction words are a small fixed table since spellOut has no notion of a
/// denominator.
enum LengthAccessibilityFormatting {
    private static func spelled(_ value: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// "halves", "quarters", "eighths", "sixteenths", "thirty-seconds", "sixty-fourths"
    /// (singular "half" for 1/2). English-only fixed table: the exact spoken
    /// phrase in the spec ("five eighths") is only asserted in English.
    private static func fractionWord(numerator: Int, denominator: Int) -> String {
        let plural = numerator != 1
        switch denominator {
        case 2: return plural ? "halves" : "half"
        case 4: return plural ? "quarters" : "quarter"
        case 8: return plural ? "eighths" : "eighth"
        case 16: return plural ? "sixteenths" : "sixteenth"
        case 32: return plural ? "thirty-seconds" : "thirty-second"
        case 64: return plural ? "sixty-fourths" : "sixty-fourth"
        default: return "\(denominator)ths"
        }
    }

    static func spokenFeetInchFraction(_ length: Length, precision: FractionPrecision,
                                        locale: Locale = Locale(identifier: "en_US")) -> String {
        let negative = length.inches.isNegative
        let magnitude = negative ? -length.inches : length.inches
        let rounded = magnitude.rounded(toNearestFractionOf: precision.denominator)
        let wholeInches = rounded.floorValue
        let fractionPart = rounded - Rational(wholeInches)
        let feet = wholeInches / 12
        let inches = wholeInches % 12

        var pieces: [String] = []
        if feet != 0 {
            pieces.append("\(spelled(feet, locale: locale)) \(feet == 1 ? "foot" : "feet")")
        }
        if inches != 0 || fractionPart.isZero == false || feet == 0 {
            if fractionPart.isZero {
                pieces.append("\(spelled(inches, locale: locale)) \(inches == 1 ? "inch" : "inches")")
            } else {
                let word = fractionWord(numerator: fractionPart.numerator, denominator: fractionPart.denominator)
                if inches == 0 {
                    pieces.append("\(spelled(fractionPart.numerator, locale: locale)) \(word) of an inch")
                } else {
                    pieces.append("\(spelled(inches, locale: locale)) and " +
                                   "\(spelled(fractionPart.numerator, locale: locale)) \(word) inches")
                }
            }
        }
        let spoken = pieces.joined(separator: " ")
        return negative ? "negative \(spoken)" : spoken
    }

    /// Metric values are spoken directly in the unit they were displayed in.
    static func spokenMetric(_ value: Rational, unit: LengthUnit, decimalPlaces: Int,
                              locale: Locale = Locale(identifier: "en_US")) -> String {
        let unitWord: String
        switch unit {
        case .meter: unitWord = "meters"
        case .centimeter: unitWord = "centimeters"
        case .millimeter: unitWord = "millimeters"
        case .yard: unitWord = "yards"
        case .feet: unitWord = "feet"
        case .inches: unitWord = "inches"
        }
        let text = LengthFormatting.decimalString(value, decimalPlaces: decimalPlaces, locale: locale)
        return "\(text) \(unitWord)"
    }
}
