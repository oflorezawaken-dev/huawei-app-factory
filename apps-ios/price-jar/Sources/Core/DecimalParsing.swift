import Foundation

/// Parses user-typed numbers into `Decimal`, accepting both '.' and ',' as
/// the decimal separator no matter which one the device's active locale
/// prefers -- a shopper's typing habit does not change with the app's
/// language, and the spec requires both to work in en-US, de-DE, fr-FR, tr
/// and ar-SA alike.
enum DecimalParsing {
    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var cleaned = String(trimmed.unicodeScalars.filter { !CharacterSet.whitespaces.contains($0) })
        // Map Arabic-Indic and Eastern Arabic-Indic digits to ASCII, since a
        // system keyboard in ar-SA can emit either.
        cleaned = cleaned.map(asciiDigit).joined()

        let lastComma = cleaned.lastIndex(of: ",")
        let lastPeriod = cleaned.lastIndex(of: ".")
        switch (lastComma, lastPeriod) {
        case (nil, nil):
            break
        case (.some, nil):
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        case (nil, .some):
            break
        case let (.some(commaIndex), .some(periodIndex)):
            if commaIndex > periodIndex {
                // Comma is the decimal separator; the period(s) were grouping.
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                // Period is the decimal separator; the comma(s) were grouping.
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        }
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func asciiDigit(_ character: Character) -> String {
        guard let scalar = character.unicodeScalars.first, character.unicodeScalars.count == 1 else {
            return String(character)
        }
        switch scalar.value {
        case 0x0660...0x0669: return String(scalar.value - 0x0660) // Arabic-Indic
        case 0x06F0...0x06F9: return String(scalar.value - 0x06F0) // Extended Arabic-Indic
        default: return String(character)
        }
    }
}
