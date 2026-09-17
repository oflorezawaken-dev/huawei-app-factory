import Foundation

/// Composes one tape entry from keypad taps. Digits accumulate into a text
/// buffer; a unit key commits that buffer as feet, as a whole-inches count,
/// or (for yard/metre/centimetre/millimetre) as the entry's only unit. A
/// fraction is entered as two digit runs separated by the fraction key.
/// A plain value type on purpose: every button maps to one pure mutation,
/// which is what makes the exact 14'3-5/8" + 9'11-3/4" case (and everything
/// else in DimensionTests) testable without any SwiftUI in the way.
struct EntryBuilder: Equatable {
    private(set) var feetComponent: Rational?
    private(set) var inchesComponent: Rational?
    private(set) var fractionNumerator: Rational?
    private(set) var buffer: String = ""
    private(set) var isPercent = false

    var isEmpty: Bool {
        feetComponent == nil && inchesComponent == nil && fractionNumerator == nil && buffer.isEmpty
    }

    /// What the keypad shows above the keys while this entry is being typed.
    var displayText: String {
        var parts: [String] = []
        if let feet = feetComponent { parts.append("\(feet.description)'") }
        if let inches = inchesComponent { parts.append("\(inches.description)\"") }
        if let numerator = fractionNumerator { parts.append("\(numerator.description)/") }
        if !buffer.isEmpty || parts.isEmpty { parts.append(buffer.isEmpty ? "0" : buffer) }
        return parts.joined(separator: " ") + (isPercent ? "%" : "")
    }

    mutating func digit(_ value: Int) {
        buffer += String(value)
    }

    mutating func decimalPoint() {
        guard !buffer.contains(".") else { return }
        buffer = buffer.isEmpty ? "0." : buffer + "."
    }

    mutating func backspace() {
        if !buffer.isEmpty {
            buffer.removeLast()
        } else if fractionNumerator != nil {
            fractionNumerator = nil
        } else if inchesComponent != nil {
            inchesComponent = nil
        } else if feetComponent != nil {
            feetComponent = nil
        }
    }

    mutating func clear() {
        self = EntryBuilder()
    }

    mutating func commitFeet() {
        guard let value = DecimalParsing.parse(buffer), buffer.isEmpty == false else { return }
        feetComponent = (feetComponent ?? .zero) + value
        buffer = ""
    }

    mutating func commitInches() {
        guard let value = DecimalParsing.parse(buffer), buffer.isEmpty == false else { return }
        inchesComponent = (inchesComponent ?? .zero) + value
        buffer = ""
    }

    /// The "/" key: the digits typed so far become the fraction's numerator,
    /// and subsequent digits become the denominator, committed by whichever
    /// unit key ends the entry.
    mutating func fractionSlash() {
        guard let value = DecimalParsing.parse(buffer), buffer.isEmpty == false, fractionNumerator == nil else {
            return
        }
        fractionNumerator = value
        buffer = ""
    }

    mutating func percent() {
        isPercent = true
    }

    /// Finalises a pure decimal/metric entry in the given unit (yard, metre,
    /// centimetre, millimetre, or a standalone decimal feet/inches value).
    func finalizeDirect(unit: LengthUnit) -> Quantity? {
        guard let value = DecimalParsing.parse(buffer) else { return nil }
        return .length(Length(value, unit))
    }

    /// Finalises a feet-inch-fraction composite entry (F001/F002), or -- if
    /// `%` was pressed -- a dimensionless percent count.
    func finalizeFeetInchFraction() -> Quantity? {
        if isPercent {
            guard let value = DecimalParsing.parse(buffer) ?? feetComponent else { return nil }
            return .count(value / Rational(100))
        }
        guard !isEmpty else { return nil }
        var totalInches = Rational.zero
        if let feet = feetComponent { totalInches = totalInches + feet * Rational(12) }
        if let inches = inchesComponent {
            totalInches = totalInches + inches
        } else if !buffer.isEmpty, let pending = DecimalParsing.parse(buffer) {
            totalInches = totalInches + pending
        }
        if let numerator = fractionNumerator, !buffer.isEmpty, let denominator = DecimalParsing.parse(buffer),
           !denominator.isZero {
            totalInches = totalInches + numerator / denominator
        }
        return .length(Length(inches: totalInches))
    }
}
