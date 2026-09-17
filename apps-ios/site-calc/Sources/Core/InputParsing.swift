import Foundation

/// Turns a solver screen's free-text field into a Length.
///
/// Two things this has to get right, and the first version got neither:
///
/// 1. **The unit a bare number means is the field's, not the app's.** It used
///    to be decimal feet for every imperial field, so "111" typed into the
///    stair solver's total rise meant 111 feet -- a 34-metre staircase -- and
///    the screen answered 7' 4-13/16" per riser with complete confidence. The
///    unit tests never saw it because they build `Length(111, .inches)`
///    directly and never go through this parser. Each field now declares the
///    unit its bare numbers mean, and the field's placeholder says so.
///
/// 2. **Tradespeople type fractions.** The spec's own worked examples are
///    written as "7-3/4 in" and "9 ft 3 in". Neither was accepted: the parser
///    took plain decimals only, so the published example could not be entered
///    into the screen that reproduces it.
///
/// Accepted, in any mix: `111`, `7.75`, `7,75`, `7-3/4`, `7 3/4`, `3/4`,
/// `15'`, `9' 3"`, `9'3"`, `111"`, `15 ft`, `6 in`, `2.5 m`, `40 cm`, `900 mm`,
/// `3 yd`. An explicit mark always wins over the field's default unit.
enum InputParsing {
    static func length(_ text: String, settings: AppSettings) -> Length? {
        length(text, settings: settings, defaultUnit: nil)
    }

    /// - Parameter defaultUnit: what a number with no unit mark means in this
    ///   field. Pass the unit the field's label promises. When nil, falls back
    ///   to the user's system -- feet for imperial, their chosen metric unit.
    static func length(_ text: String, settings: AppSettings, defaultUnit: LengthUnit?) -> Length? {
        let fallback = defaultUnit ?? (settings.preferredSystem == .imperial ? .feet : settings.preferredMetricUnit)
        return parse(text, defaultUnit: fallback)
    }

    static func rational(_ text: String) -> Rational? {
        guard let value = parseNumber(text), !value.isNegative else { return nil }
        return value
    }

    // MARK: - parsing

    static func parse(_ raw: String, defaultUnit: LengthUnit) -> Length? {
        let text = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty else { return nil }
        // "-" separates a whole number from its fraction ("7-3/4"), so the loop
        // below skips it. That must not quietly turn "-5" into 5: a negative
        // length is not a length here, and answering 5 to someone who typed -5
        // is exactly the silent reinterpretation this parser exists to stop.
        guard !text.hasPrefix("-") else { return nil }

        var total: Length?
        var sawAnything = false
        var index = text.startIndex

        while index < text.endIndex {
            // Skip separators between components: "9' 3\"" and "15 ft 6 in".
            while index < text.endIndex, text[index] == " " || text[index] == "-" {
                index = text.index(after: index)
            }
            guard index < text.endIndex else { break }

            guard let (value, next) = scanNumber(text, from: index) else { return nil }
            index = next
            let (unit, afterUnit) = scanUnit(text, from: index)
            index = afterUnit

            guard !value.isNegative else { return nil }
            let component = Length(value, unit ?? defaultUnit)
            total = (total ?? Length(.zero, .inches)) + component
            sawAnything = true
        }

        guard sawAnything, let total, !total.inches.isNegative else { return nil }
        return total
    }

    /// A number, which may be `7`, `7.75`, `7,75`, `3/4` or `7 3/4` / `7-3/4`.
    private static func scanNumber(_ text: String, from start: String.Index) -> (Rational, String.Index)? {
        guard let (whole, afterWhole) = scanPlainNumber(text, from: start) else { return nil }

        // A slash straight after makes the number a fraction: "3/4".
        if afterWhole < text.endIndex, text[afterWhole] == "/" {
            let afterSlash = text.index(after: afterWhole)
            guard let (denominator, end) = scanPlainNumber(text, from: afterSlash),
                  !denominator.isZero, denominator.isInteger, whole.isInteger else { return nil }
            return (Rational(whole.numerator, denominator.numerator), end)
        }

        // Otherwise a following "<int>/<int>" is a mixed fraction: "7 3/4".
        var probe = afterWhole
        while probe < text.endIndex, text[probe] == " " || text[probe] == "-" {
            probe = text.index(after: probe)
        }
        if probe < text.endIndex, text[probe].isNumber,
           let (numerator, afterNumerator) = scanPlainNumber(text, from: probe),
           afterNumerator < text.endIndex, text[afterNumerator] == "/" {
            let afterSlash = text.index(after: afterNumerator)
            guard let (denominator, end) = scanPlainNumber(text, from: afterSlash),
                  !denominator.isZero, denominator.isInteger, numerator.isInteger else { return nil }
            return (whole + Rational(numerator.numerator, denominator.numerator), end)
        }

        return (whole, afterWhole)
    }

    private static func scanPlainNumber(_ text: String, from start: String.Index) -> (Rational, String.Index)? {
        var end = start
        while end < text.endIndex, text[end].isNumber || text[end] == "." || text[end] == "," {
            end = text.index(after: end)
        }
        guard end > start, let value = DecimalParsing.parse(String(text[start..<end])) else { return nil }
        return (value, end)
    }

    /// `'` and `ft`, `"` and `in`, plus the metric names. Returns nil when the
    /// number carries no mark and the caller's default should apply.
    private static func scanUnit(_ text: String, from start: String.Index) -> (LengthUnit?, String.Index) {
        var index = start
        while index < text.endIndex, text[index] == " " { index = text.index(after: index) }
        guard index < text.endIndex else { return (nil, start) }

        let rest = text[index...]
        // Longest first: "mm" before "m", "in" before nothing.
        let marks: [(String, LengthUnit)] = [
            ("feet", .feet), ("foot", .feet), ("ft", .feet), ("'", .feet),
            ("inches", .inches), ("inch", .inches), ("in", .inches), ("\"", .inches), ("''", .inches),
            ("yards", .yard), ("yard", .yard), ("yd", .yard),
            ("mm", .millimeter), ("millimetres", .millimeter), ("millimeters", .millimeter),
            ("cm", .centimeter), ("centimetres", .centimeter), ("centimeters", .centimeter),
            ("metres", .meter), ("meters", .meter), ("m", .meter),
        ]
        for (mark, unit) in marks where rest.hasPrefix(mark) {
            return (unit, text.index(index, offsetBy: mark.count))
        }
        return (nil, start)
    }

    private static func parseNumber(_ text: String) -> Rational? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let (value, end) = scanNumber(trimmed, from: trimmed.startIndex),
              end == trimmed.endIndex else { return DecimalParsing.parse(trimmed) }
        return value
    }
}
