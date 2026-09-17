import Foundation

/// "291-3/8 in on 16 in centres" is a count, not a length (F001): the number of
/// spaces along a run at a given spacing, and the pieces needed to frame it
/// (one more than the number of spaces, since a piece stands at each end).
/// Shared by the tape's on-centre operator (F002) and the framing line of the
/// material estimator (F007) so the two never compute it differently.
enum OnCentreCalculator {
    struct Result {
        /// The exact, unrounded number of spaces (a dimensionless Length/Length).
        let exactSpaces: Rational
        /// Spaces rounded up to a whole number -- you cannot buy a fractional space.
        let spaces: Int
        /// One piece per space, plus the closing piece at the far end.
        var pieces: Int { spaces + 1 }
        /// What is left over in the final, partial space after `spaces - 1` full
        /// spaces at the given spacing -- the shortfall a builder needs to know
        /// about, not a rounding error to hide.
        let remainder: Length
    }

    static func compute(total: Length, spacing: Length) -> Result {
        precondition(!spacing.inches.isZero, "on-centre spacing must not be zero")
        let exactSpaces = total / spacing
        let spaces = exactSpaces.ceilValue
        let fullSpaces = exactSpaces.floorValue
        let remainder = total - spacing * Rational(fullSpaces)
        return Result(exactSpaces: exactSpaces, spaces: spaces, remainder: remainder)
    }
}
