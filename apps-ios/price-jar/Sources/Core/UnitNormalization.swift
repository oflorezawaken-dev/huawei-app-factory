import Foundation

// This module is PriceJar's premise: every price becomes a comparable unit
// price. It is pure Swift, does no I/O, and uses Decimal exclusively -- a
// unit test (UnitNormalizationSourceTests) reads this file's own source back
// and fails the build if the words "Double" or "Float" ever appear in it, so
// every quantity below stays a Decimal literal or a Decimal computation.

/// A unit a package size can be recorded in. Grouped into three dimensions
/// that never convert into one another: mass, volume and count.
enum MeasurementUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case gram
    case kilogram
    case pound
    case ounce
    case milliliter
    case liter
    case usGallon
    case usFluidOunce
    case imperialFluidOunce
    case item

    var id: String { rawValue }

    enum Dimension: String, Codable, Sendable {
        case mass
        case volume
        case count
    }

    var dimension: Dimension {
        switch self {
        case .gram, .kilogram, .pound, .ounce: return .mass
        case .milliliter, .liter, .usGallon, .usFluidOunce, .imperialFluidOunce: return .volume
        case .item: return .count
        }
    }

    /// How many base units (grams for mass, millilitres for volume, items for
    /// count) one unit of this measure represents. The exact table from the
    /// spec: 1 kg = 1000 g, 1 lb = 453.59237 g, 1 oz = 28.349523125 g,
    /// 1 L = 1000 mL, 1 US gal = 3.785411784 L, 1 US fl oz = 29.5735295625 mL,
    /// 1 imperial fl oz = 28.4130625 mL.
    var baseUnitsPerUnit: Decimal {
        switch self {
        case .gram: return 1
        case .kilogram: return 1000
        case .pound: return Decimal(string: "453.59237")!
        case .ounce: return Decimal(string: "28.349523125")!
        case .milliliter: return 1
        case .liter: return 1000
        case .usGallon: return Decimal(string: "3785.411784")!
        case .usFluidOunce: return Decimal(string: "29.5735295625")!
        case .imperialFluidOunce: return Decimal(string: "28.4130625")!
        case .item: return 1
        }
    }

    /// Units appropriate to offer for a given dimension, in a sensible order.
    static func units(for dimension: Dimension) -> [MeasurementUnit] {
        allCases.filter { $0.dimension == dimension }
    }
}

/// A unit the app displays a normalised price in. Distinct from
/// `MeasurementUnit` because a price is always recorded in a package's own
/// unit but always *shown* as a per-kg / per-lb / per-item rate the user
/// picked as their preference.
enum DisplayUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case perKilogram
    case per100Grams
    case perPound
    case perLiter
    case per100Milliliters
    case perFluidOunce
    case perItem

    var id: String { rawValue }

    var dimension: MeasurementUnit.Dimension {
        switch self {
        case .perKilogram, .per100Grams, .perPound: return .mass
        case .perLiter, .per100Milliliters: return .volume
        case .perFluidOunce: return .volume
        case .perItem: return .count
        }
    }

    /// How many base units one display unit represents, e.g. per100Grams -> 100 g.
    var baseUnitsPerDisplayUnit: Decimal {
        switch self {
        case .perKilogram: return 1000
        case .per100Grams: return 100
        case .perPound: return Decimal(string: "453.59237")!
        case .perLiter: return 1000
        case .per100Milliliters: return 100
        case .perFluidOunce: return Decimal(string: "29.5735295625")!
        case .perItem: return 1
        }
    }

    static func displayUnits(for dimension: MeasurementUnit.Dimension) -> [DisplayUnit] {
        allCases.filter { $0.dimension == dimension }
    }

    /// A reasonable default display unit for a dimension under a measurement system.
    static func systemDefault(for dimension: MeasurementUnit.Dimension, metric: Bool) -> DisplayUnit {
        switch dimension {
        case .mass: return metric ? .perKilogram : .perPound
        case .volume: return metric ? .perLiter : .perFluidOunce
        case .count: return .perItem
        }
    }
}

/// Errors the normalisation engine raises. Named so the UI can explain
/// exactly what went wrong instead of silently coercing a bad comparison.
enum UnitNormalizationError: Error, Equatable, Sendable {
    /// The unit picked for an entry belongs to a different dimension (mass vs
    /// volume vs count) than the item it is being recorded against.
    case dimensionMismatch(entryDimension: MeasurementUnit.Dimension, itemDimension: MeasurementUnit.Dimension)
    /// A package size of zero or less has no meaningful unit price.
    case nonPositivePackageSize
}

/// The pure, exhaustively-tested conversion and pricing engine. No SwiftUI,
/// no SwiftData, no networking -- it exists so a price in any unit, in any
/// package size, can be reduced to one comparable number.
enum UnitNormalization {
    /// Rounds a Decimal to `scale` fractional digits using plain (round to
    /// nearest) rounding, matching how a shopper would round the number.
    static func rounded(_ value: Decimal, scale: Int) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }

    /// The package size expressed in the dimension's base unit (grams,
    /// millilitres or items).
    static func baseQuantity(packageSize: Decimal, unit: MeasurementUnit) -> Decimal {
        packageSize * unit.baseUnitsPerUnit
    }

    /// Confirms an entry's unit shares the item's own dimension. Mass and
    /// volume never interconvert; this is the guard that enforces it at the
    /// moment a price is entered, not after the fact.
    static func validateDimension(entryUnit: MeasurementUnit, itemDimension: MeasurementUnit.Dimension) throws {
        guard entryUnit.dimension == itemDimension else {
            throw UnitNormalizationError.dimensionMismatch(entryDimension: entryUnit.dimension, itemDimension: itemDimension)
        }
    }

    /// The price per base unit (per gram / per millilitre / per item),
    /// computed to four decimal places as the spec requires.
    static func unitPrice(price: Decimal, packageSize: Decimal, unit: MeasurementUnit) throws -> Decimal {
        guard packageSize > 0 else { throw UnitNormalizationError.nonPositivePackageSize }
        let base = baseQuantity(packageSize: packageSize, unit: unit)
        let raw = price / base
        return rounded(raw, scale: 4)
    }

    /// A base unit price (per gram / per millilitre / per item) converted to
    /// the display unit the user prefers, e.g. per kg or per 100 mL.
    static func displayUnitPrice(baseUnitPrice: Decimal, displayUnit: DisplayUnit) -> Decimal {
        baseUnitPrice * displayUnit.baseUnitsPerDisplayUnit
    }

    /// Convenience: price -> unit price -> display price in one call, for the
    /// common case of showing a recorded entry's rate in the item's
    /// preferred display unit.
    static func displayUnitPrice(price: Decimal, packageSize: Decimal, unit: MeasurementUnit,
                                  displayUnit: DisplayUnit) throws -> Decimal {
        let base = try unitPrice(price: price, packageSize: packageSize, unit: unit)
        return displayUnitPrice(baseUnitPrice: base, displayUnit: displayUnit)
    }
}
