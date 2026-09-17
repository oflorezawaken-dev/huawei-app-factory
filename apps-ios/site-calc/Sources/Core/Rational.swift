import Foundation

/// An exact fraction of two Int values, always stored reduced with a positive
/// denominator. This is the only numeric representation used anywhere in the
/// dimensional-arithmetic module: no binary approximate type of any kind. A
/// wrong rafter length gets cut into a real board, so nothing here is
/// allowed to accumulate rounding error. (A source scan enforces this file
/// stays free of the two banned type names -- see NoFloatingPointTests.)
struct Rational: Equatable, Comparable, Hashable, CustomStringConvertible, Codable {
    let numerator: Int
    let denominator: Int

    init(_ numerator: Int, _ denominator: Int = 1) {
        precondition(denominator != 0, "Rational denominator must not be zero")
        let sign = denominator < 0 ? -1 : 1
        let n = numerator * sign
        let d = denominator * sign
        if n == 0 {
            self.numerator = 0
            self.denominator = 1
        } else {
            let g = Rational.gcd(abs(n), d)
            self.numerator = n / g
            self.denominator = d / g
        }
    }

    static let zero = Rational(0)
    static let one = Rational(1)

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a == 0 ? 1 : a
    }

    var isZero: Bool { numerator == 0 }
    var isNegative: Bool { numerator < 0 }
    var isInteger: Bool { denominator == 1 }

    static func + (l: Rational, r: Rational) -> Rational {
        Rational(l.numerator * r.denominator + r.numerator * l.denominator, l.denominator * r.denominator)
    }

    static func - (l: Rational, r: Rational) -> Rational {
        Rational(l.numerator * r.denominator - r.numerator * l.denominator, l.denominator * r.denominator)
    }

    static func * (l: Rational, r: Rational) -> Rational {
        Rational(l.numerator * r.numerator, l.denominator * r.denominator)
    }

    static func / (l: Rational, r: Rational) -> Rational {
        precondition(r.numerator != 0, "Rational division by zero")
        return Rational(l.numerator * r.denominator, l.denominator * r.numerator)
    }

    static prefix func - (v: Rational) -> Rational { Rational(-v.numerator, v.denominator) }

    static func < (l: Rational, r: Rational) -> Bool {
        l.numerator * r.denominator < r.numerator * l.denominator
    }

    /// Largest integer <= self.
    var floorValue: Int {
        if numerator >= 0 { return numerator / denominator }
        let q = numerator / denominator
        let r = numerator % denominator
        return r == 0 ? q : q - 1
    }

    /// Smallest integer >= self.
    var ceilValue: Int {
        -((-self).floorValue)
    }

    /// Rounds to the nearest multiple of 1/precisionDenominator, half away from zero.
    /// This is the only rounding operation in the type, and it is used for display only
    /// -- the stored Rational this is called on is never replaced by the result.
    func rounded(toNearestFractionOf precisionDenominator: Int) -> Rational {
        precondition(precisionDenominator > 0)
        let scaled = self * Rational(precisionDenominator)
        return Rational(scaled.roundedToNearestInt, precisionDenominator)
    }

    /// Rounds this rational to the nearest integer, half away from zero.
    var roundedToNearestInt: Int {
        let q = numerator / denominator
        let r = numerator % denominator
        if r == 0 { return q }
        let twiceR = 2 * abs(r)
        if twiceR >= denominator {
            return numerator > 0 ? q + 1 : q - 1
        }
        return q
    }

    var description: String { denominator == 1 ? "\(numerator)" : "\(numerator)/\(denominator)" }
}
