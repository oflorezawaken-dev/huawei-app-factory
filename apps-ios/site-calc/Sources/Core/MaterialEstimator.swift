import Foundation

/// Geometry to quantities of material -- counts and volumes, never money
/// (F007). Every function returns the exact quantity alongside the rounded-up
/// purchasable count, computed in exact Rational arithmetic throughout: waste
/// and yield percentages are Rational fractions (e.g. 10% is exactly 1/10),
/// never a Double, which is what keeps 180 sqft at 10% waste exactly 198
/// tiles instead of the 198.00000000000003 a binary float would produce.
enum MaterialEstimator {
    struct Quantity {
        let exact: Rational
        let roundedUp: Int
    }

    private static func quantity(exact: Rational) -> Quantity {
        Quantity(exact: exact, roundedUp: exact.ceilValue)
    }

    private static func withWaste(_ area: Area, wastePercent: Rational) -> Area {
        area * (Rational(1) + wastePercent / Rational(100))
    }

    private static func withWaste(_ volume: Volume, wastePercent: Rational) -> Volume {
        volume * (Rational(1) + wastePercent / Rational(100))
    }

    // MARK: Concrete

    static func concreteBags(volume: Volume, bagYieldCubicFeet: Rational, wastePercent: Rational = .zero) -> Quantity {
        let cuft = withWaste(volume, wastePercent: wastePercent).converted(to: .feet)
        return quantity(exact: cuft / bagYieldCubicFeet)
    }

    static func cubicYards(_ volume: Volume, wastePercent: Rational = .zero) -> Rational {
        withWaste(volume, wastePercent: wastePercent).converted(to: .feet) / Volume.cubicFeetPerCubicYard
    }

    // MARK: Framing (studs, joists, rafters at a chosen spacing)

    static func framing(total: Length, spacing: Length) -> OnCentreCalculator.Result {
        OnCentreCalculator.compute(total: total, spacing: spacing)
    }

    // MARK: Sheets (drywall, sheathing)

    static func sheets(area: Area, sheetWidth: Length, sheetHeight: Length,
                       wastePercent: Rational = .zero) -> Quantity {
        let sheetArea = sheetWidth * sheetHeight
        let needed = withWaste(area, wastePercent: wastePercent)
        return quantity(exact: needed / sheetArea)
    }

    // MARK: Tile and flooring

    static func pieces(area: Area, pieceWidth: Length, pieceHeight: Length,
                       wastePercent: Rational) -> Quantity {
        let pieceArea = pieceWidth * pieceHeight
        let needed = withWaste(area, wastePercent: wastePercent)
        return quantity(exact: needed / pieceArea)
    }

    // MARK: Paint

    static func paintContainers(area: Area, coverageSquareFeetPerContainer: Rational) -> Quantity {
        let sqft = area.converted(to: .feet)
        return quantity(exact: sqft / coverageSquareFeetPerContainer)
    }

    // MARK: Decking

    static func deckingBoards(coverageWidth: Length, boardWidth: Length, gap: Length) -> Quantity {
        let effectiveWidth = boardWidth + gap
        return quantity(exact: coverageWidth / effectiveWidth)
    }

    // MARK: Roofing

    /// A published, non-expiring constant: 100 square feet to the roofing square.
    static let squareFeetPerRoofingSquare = Rational(100)

    static func roofingSquares(area: Area, wastePercent: Rational = .zero) -> Quantity {
        let sqft = withWaste(area, wastePercent: wastePercent).converted(to: .feet)
        return quantity(exact: sqft / MaterialEstimator.squareFeetPerRoofingSquare)
    }
}
