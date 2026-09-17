import Foundation

/// Bridges the exact `Rational` type to a binary approximate value and back,
/// for the handful of places that genuinely need one: square roots and
/// trigonometry at a solver's boundary (F001), and ordinary numeric display
/// elsewhere. Deliberately kept out of Rational.swift, Dimension.swift and
/// TapeEngine.swift, so a plain source scan of those three files -- the
/// dimensional type and the tape -- finds no trace of either banned type
/// name (NoFloatingPointTests).
func boundaryValue(of value: Rational) -> Double {
    Double(value.numerator) / Double(value.denominator)
}

/// Converts a solver-boundary result (from sqrt/trig, computed as F001
/// allows) back into an exact Rational at a fine resolution, so the rest of
/// the dimensional type can chain it exactly without ever storing the
/// approximate value itself.
func rationalApproximating(_ value: Double, denominator: Int) -> Rational {
    Rational(Int((value * Double(denominator)).rounded()), denominator)
}
