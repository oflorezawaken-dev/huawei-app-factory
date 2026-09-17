import Foundation

/// Parses user-typed decimal numbers into an exact Rational -- never through
/// Double -- accepting either ',' or '.' as the decimal separator regardless
/// of the device locale (F015, qa acceptance: "numeric entry accepts both the
/// comma and the period as the decimal separator in every locale").
enum DecimalParsing {
    /// Returns nil for empty or malformed input (more than one separator, or a
    /// non-digit character). "-" is accepted as a leading sign.
    static func parse(_ raw: String) -> Rational? {
        var text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        var negative = false
        if text.hasPrefix("-") {
            negative = true
            text.removeFirst()
        }
        guard !text.isEmpty else { return nil }

        let separators = CharacterSet(charactersIn: ",.")
        let parts = text.components(separatedBy: separators)
        guard parts.count <= 2, parts.allSatisfy({ $0.allSatisfy(\.isNumber) }) else { return nil }
        guard !(parts.count == 2 && parts[1].isEmpty && parts[0].isEmpty) else { return nil }

        let wholePart = parts[0].isEmpty ? "0" : parts[0]
        guard let whole = Int(wholePart) else { return nil }

        var value = Rational(whole)
        if parts.count == 2, !parts[1].isEmpty {
            guard let fractionalDigits = Int(parts[1]) else { return nil }
            let scale = Int(pow(10.0, Double(parts[1].count)))
            value = value + Rational(fractionalDigits, scale)
        }
        return negative ? -value : value
    }
}
