import Foundation

/// Shapes to quantities (F006): rooms and walls with openings, rectangular and
/// circular footings, columns, slabs, circles, segments and arcs. Rectangular
/// shapes stay exact rational arithmetic throughout; circular shapes use pi
/// and (for segments) sine at the solver boundary, exactly like RoofSolver's
/// square roots, converted back to the exact type at the same fine resolution.
enum AreaVolumeSolver {
    private static let chainingResolution = 1_000_000

    private static func fromDouble(_ value: Double) -> Rational {
        rationalApproximating(value, denominator: chainingResolution)
    }

    // MARK: Rooms and walls

    static func rectangleArea(width: Length, height: Length) -> Area { width * height }

    /// A wall's area minus a list of rectangular openings (doors, windows).
    static func wallArea(width: Length, height: Length, openings: [(width: Length, height: Length)]) -> Area {
        let gross = width * height
        let openingsArea = openings.reduce(Area.zero) { $0 + $1.width * $1.height }
        let net = gross - openingsArea
        return net.squareInches.isNegative ? Area.zero : net
    }

    // MARK: Rectangular solids

    static func slabVolume(length: Length, width: Length, thickness: Length) -> Volume {
        length * width * thickness
    }

    static func rectangularFootingVolume(length: Length, width: Length, depth: Length) -> Volume {
        length * width * depth
    }

    static func columnVolume(width: Length, depth: Length, height: Length) -> Volume {
        width * depth * height
    }

    // MARK: Circular shapes (pi at the solver boundary)

    static func circleArea(radius: Length) -> Area {
        let r = boundaryValue(of: radius.inches)
        return Area(squareInches: fromDouble(Double.pi * r * r))
    }

    static func circleCircumference(radius: Length) -> Length {
        let r = boundaryValue(of: radius.inches)
        return Length(inches: fromDouble(2 * Double.pi * r))
    }

    static func circularFootingVolume(radius: Length, depth: Length) -> Volume {
        let area = circleArea(radius: radius)
        return area * depth
    }

    static func circularColumnVolume(radius: Length, height: Length) -> Volume {
        circularFootingVolume(radius: radius, depth: height)
    }

    /// The area of a circular segment cut off by a chord subtending
    /// `includedAngleDegrees` at the centre: r^2/2 * (theta - sin theta).
    static func segmentArea(radius: Length, includedAngleDegrees: Rational) -> Area {
        let r = boundaryValue(of: radius.inches)
        let theta = boundaryValue(of: includedAngleDegrees) * Double.pi / 180
        let value = (r * r / 2) * (theta - sin(theta))
        return Area(squareInches: fromDouble(max(value, 0)))
    }

    /// Arc length subtending `includedAngleDegrees` at the centre: r * theta (radians).
    static func arcLength(radius: Length, includedAngleDegrees: Rational) -> Length {
        let r = boundaryValue(of: radius.inches)
        let theta = boundaryValue(of: includedAngleDegrees) * Double.pi / 180
        return Length(inches: fromDouble(r * theta))
    }
}
