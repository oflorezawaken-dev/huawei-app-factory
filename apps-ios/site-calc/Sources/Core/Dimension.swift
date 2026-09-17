import Foundation

/// The units a length can be entered or displayed in. Conversion factors are
/// exact rationals derived from the international inch being exactly 25.4 mm
/// -- never an approximate binary value -- so every conversion is a rational
/// operation, and a round trip through any of these units returns the exact
/// original value.
enum LengthUnit: String, CaseIterable, Codable {
    case feet, inches, yard, meter, centimeter, millimeter

    /// Exact number of inches in one of this unit, as a Rational.
    var inchesPerUnit: Rational {
        switch self {
        case .inches: return Rational(1)
        case .feet: return Rational(12)
        case .yard: return Rational(36)
        // 1 in = 25.4 mm exactly => 1 mm = 1/25.4 in = 10/254 in = 5/127 in.
        case .millimeter: return Rational(5, 127)
        case .centimeter: return Rational(50, 127)
        case .meter: return Rational(5000, 127)
        }
    }
}

/// A length held as an exact rational number of inches. No binary
/// approximate type anywhere in this type or the tape that uses it (F001,
/// enforced by NoFloatingPointTests scanning this module's own source).
struct Length: Equatable, Comparable, Hashable, Codable {
    var inches: Rational

    init(inches: Rational) { self.inches = inches }
    init(_ value: Int, _ unit: LengthUnit) { self.inches = Rational(value) * unit.inchesPerUnit }
    init(_ value: Rational, _ unit: LengthUnit) { self.inches = value * unit.inchesPerUnit }

    static let zero = Length(inches: .zero)

    func converted(to unit: LengthUnit) -> Rational { inches / unit.inchesPerUnit }

    static func + (l: Length, r: Length) -> Length { Length(inches: l.inches + r.inches) }
    static func - (l: Length, r: Length) -> Length { Length(inches: l.inches - r.inches) }
    static prefix func - (l: Length) -> Length { Length(inches: -l.inches) }
    static func * (l: Length, scalar: Rational) -> Length { Length(inches: l.inches * scalar) }
    static func * (scalar: Rational, l: Length) -> Length { Length(inches: l.inches * scalar) }
    static func / (l: Length, scalar: Rational) -> Length { Length(inches: l.inches / scalar) }

    /// Length * Length = Area. This is dimensional algebra, not a convenience:
    /// F001 and F016 require the type itself to enforce it.
    static func * (l: Length, r: Length) -> Area { Area(squareInches: l.inches * r.inches) }

    /// Length / Length = a dimensionless count (F001's "291-3/8 in on 16 in
    /// centres is a count, not a length").
    static func / (l: Length, r: Length) -> Rational { l.inches / r.inches }

    static func < (l: Length, r: Length) -> Bool { l.inches < r.inches }
}

/// An area held as an exact rational number of square inches.
struct Area: Equatable, Comparable, Hashable, Codable {
    var squareInches: Rational

    static let zero = Area(squareInches: .zero)

    /// Exact square inches in one of these squared units.
    static func squareInchesPerUnit(_ unit: LengthUnit) -> Rational {
        let f = unit.inchesPerUnit
        return f * f
    }

    func converted(to unit: LengthUnit) -> Rational { squareInches / Area.squareInchesPerUnit(unit) }

    static func + (l: Area, r: Area) -> Area { Area(squareInches: l.squareInches + r.squareInches) }
    static func - (l: Area, r: Area) -> Area { Area(squareInches: l.squareInches - r.squareInches) }
    static func * (a: Area, scalar: Rational) -> Area { Area(squareInches: a.squareInches * scalar) }
    static func * (scalar: Rational, a: Area) -> Area { Area(squareInches: a.squareInches * scalar) }
    static func / (a: Area, scalar: Rational) -> Area { Area(squareInches: a.squareInches / scalar) }
    static func / (a: Area, r: Area) -> Rational { a.squareInches / r.squareInches }

    /// Area / Length = Length (e.g. area over a run length gives a width).
    static func / (a: Area, l: Length) -> Length { Length(inches: a.squareInches / l.inches) }

    /// Area * Length = Volume.
    static func * (a: Area, l: Length) -> Volume { Volume(cubicInches: a.squareInches * l.inches) }
    static func * (l: Length, a: Area) -> Volume { Volume(cubicInches: a.squareInches * l.inches) }

    static func < (l: Area, r: Area) -> Bool { l.squareInches < r.squareInches }
}

/// A volume held as an exact rational number of cubic inches.
struct Volume: Equatable, Comparable, Hashable, Codable {
    var cubicInches: Rational

    static let zero = Volume(cubicInches: .zero)

    static func cubicInchesPerUnit(_ unit: LengthUnit) -> Rational {
        let f = unit.inchesPerUnit
        return f * f * f
    }

    func converted(to unit: LengthUnit) -> Rational { cubicInches / Volume.cubicInchesPerUnit(unit) }

    /// Cubic feet to the cubic yard: a published constant (27), not a rounded one.
    static let cubicFeetPerCubicYard = Rational(27)

    static func + (l: Volume, r: Volume) -> Volume { Volume(cubicInches: l.cubicInches + r.cubicInches) }
    static func - (l: Volume, r: Volume) -> Volume { Volume(cubicInches: l.cubicInches - r.cubicInches) }
    static func * (v: Volume, scalar: Rational) -> Volume { Volume(cubicInches: v.cubicInches * scalar) }
    static func / (v: Volume, scalar: Rational) -> Volume { Volume(cubicInches: v.cubicInches / scalar) }
    static func / (v: Volume, r: Volume) -> Rational { v.cubicInches / r.cubicInches }
    static func / (v: Volume, a: Area) -> Length { Length(inches: v.cubicInches / a.squareInches) }
    static func / (v: Volume, l: Length) -> Area { Area(squareInches: v.cubicInches / l.inches) }

    static func < (l: Volume, r: Volume) -> Bool { l.cubicInches < r.cubicInches }
}
