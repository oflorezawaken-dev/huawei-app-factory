import XCTest
@testable import SiteCalc

/// Test-only bridge to `Double`.
///
/// The production `Rational` deliberately has no `Double` accessor: a
/// construction calculator that can turn an exact eighth of an inch into
/// 0.12500000000000003 on the way to the screen has given up the one property
/// that makes it safe to cut from, and `NoFloatingPointTests` enforces that by
/// scanning `Sources/Core/Rational.swift` for the word `Double`.
///
/// Assertions still need one — rounding behaviour and the trigonometric
/// solvers are only checkable within a tolerance — so the bridge lives here,
/// in the test target, where the app cannot reach it.
extension Rational {
    var doubleValue: Double { Double(numerator) / Double(denominator) }
}
