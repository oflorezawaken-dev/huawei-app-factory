import XCTest
@testable import SiteCalc

/// A tiny deterministic PRNG so the property tests below are reproducible
/// (a flaky property test is worse than no property test) while still
/// exercising 200,000 generated pairs per qa acceptance criteria.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdead_beef : seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

final class RationalTests: XCTestCase {
    func testBasicReduction() {
        XCTAssertEqual(Rational(2, 4), Rational(1, 2))
        XCTAssertEqual(Rational(-2, 4), Rational(-1, 2))
        XCTAssertEqual(Rational(2, -4), Rational(-1, 2))
        XCTAssertEqual(Rational(0, 5), Rational(0, 1))
    }

    func testArithmeticIsExact() {
        XCTAssertEqual(Rational(1, 2) + Rational(1, 3), Rational(5, 6))
        XCTAssertEqual(Rational(1, 2) - Rational(1, 3), Rational(1, 6))
        XCTAssertEqual(Rational(2, 3) * Rational(3, 4), Rational(1, 2))
        XCTAssertEqual(Rational(2, 3) / Rational(4, 9), Rational(3, 2))
    }

    func testFloorAndCeil() {
        XCTAssertEqual(Rational(7, 2).floorValue, 3)
        XCTAssertEqual(Rational(7, 2).ceilValue, 4)
        XCTAssertEqual(Rational(-7, 2).floorValue, -4)
        XCTAssertEqual(Rational(-7, 2).ceilValue, -3)
        XCTAssertEqual(Rational(6, 2).floorValue, 3)
        XCTAssertEqual(Rational(6, 2).ceilValue, 3)
    }

    func testRoundedToNearestFraction() {
        // 7.4 in rounds to the nearest 1/16: 118.4/16 -> 118/16 -> 59/8 = 7-3/8.
        let value = Rational(37, 5) // 7.4
        let rounded = value.rounded(toNearestFractionOf: 16)
        XCTAssertEqual(rounded, Rational(59, 8))
    }

    func testRoundedHalfAwayFromZero() {
        XCTAssertEqual(Rational(1, 2).roundedToNearestInt, 1)
        XCTAssertEqual(Rational(-1, 2).roundedToNearestInt, -1)
        XCTAssertEqual(Rational(3, 2).roundedToNearestInt, 2)
    }

    // qa: "a property test over 200,000 generated pairs asserts that
    // (a + b) + c equals a + (b + c) and a + b equals b + a exactly."
    func testAdditionIsAssociativeAndCommutativeOver200000GeneratedTriples() {
        var rng = SeededGenerator(seed: 12345)
        for _ in 0..<200_000 {
            let a = Rational(Int.random(in: -5000...5000, using: &rng), Int.random(in: 1...64, using: &rng))
            let b = Rational(Int.random(in: -5000...5000, using: &rng), Int.random(in: 1...64, using: &rng))
            let c = Rational(Int.random(in: -5000...5000, using: &rng), Int.random(in: 1...64, using: &rng))
            XCTAssertEqual((a + b) + c, a + (b + c))
            XCTAssertEqual(a + b, b + a)
        }
    }
}
