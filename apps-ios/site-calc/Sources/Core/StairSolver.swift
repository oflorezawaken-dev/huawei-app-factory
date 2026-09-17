import Foundation

/// Stair layout (F005). Total rise in, full layout out -- using only the
/// limits the user typed in themselves. This solver ships no maximum riser or
/// minimum tread of its own; the caller must supply both, and the screen that
/// calls it disables Solve until they are non-empty (S005).
enum StairSolver {
    enum InputError: Error, Equatable { case invalidInputs }

    private static let chainingResolution = 1_000_000

    struct Result: Equatable {
        let riserCount: Int
        /// The exact riser height (e.g. 7.400 in for 111 in over 15 risers) --
        /// never itself rounded, so a caller can always ask what a chosen
        /// display precision would have cost in `StairSolver.shortfall`.
        let riserHeight: Length
        let treadCount: Int
        /// The user's own minimum tread depth, used directly as the tread the
        /// layout is built around.
        let treadDepth: Length
        let totalRun: Length
        let stringerLength: Length
    }

    static func solve(totalRise: Length, maxRiserHeight: Length, minTreadDepth: Length) throws -> Result {
        guard totalRise.inches.isZero == false, totalRise.inches.isNegative == false,
              maxRiserHeight.inches.isZero == false, maxRiserHeight.inches.isNegative == false,
              minTreadDepth.inches.isNegative == false else {
            throw InputError.invalidInputs
        }
        let exactRiserCount = totalRise / maxRiserHeight
        let riserCount = max(exactRiserCount.ceilValue, 1)
        let riserHeight = totalRise / Rational(riserCount)
        let treadCount = max(riserCount - 1, 0)
        let totalRun = minTreadDepth * Rational(treadCount)

        let riseValue = boundaryValue(of: totalRise.inches)
        let runValue = boundaryValue(of: totalRun.inches)
        let stringerValue = (riseValue * riseValue + runValue * runValue).squareRoot()
        let stringerLength = Length(inches: rationalApproximating(stringerValue, denominator: chainingResolution))

        return Result(riserCount: riserCount, riserHeight: riserHeight, treadCount: treadCount,
                       treadDepth: minTreadDepth, totalRun: totalRun, stringerLength: stringerLength)
    }

    /// How far short of the total rise the flight would fall if every riser
    /// were actually built at the nearest fraction of the exact riser height,
    /// rather than at its exact value -- the accumulated-rounding disclosure
    /// F005 requires the screen to show alongside the exact figure.
    static func shortfall(totalRise: Length, riserCount: Int, riserHeight: Length,
                           precision: FractionPrecision) -> Length {
        let roundedRiser = Length(inches: riserHeight.inches.rounded(toNearestFractionOf: precision.denominator))
        return totalRise - roundedRiser * Rational(riserCount)
    }
}
