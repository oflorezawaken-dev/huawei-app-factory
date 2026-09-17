import XCTest

/// qa: "a build check fails if 'Double' or 'Float' appears in the
/// dimensional-type module or in the tape module." Enforced here as a plain
/// source scan of the three files that make up the exact type: Rational (the
/// fraction itself), Dimension (Length/Area/Volume) and TapeEngine (the tape
/// that chains them). Square roots and trigonometry are confined to the
/// solver modules instead (RoofSolverTests / AreaVolumeMaterialTests exist
/// alongside real solver files that do use Double, by design, at that
/// boundary only).
final class NoFloatingPointTests: XCTestCase {
    private let projectRoot: URL = {
        // Tests/NoFloatingPointTests.swift -> Tests -> <app root>
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }()

    private func source(_ relativePath: String) throws -> String {
        try String(contentsOf: projectRoot.appendingPathComponent(relativePath), encoding: .utf8)
    }

    func testDimensionalTypeAndTapeContainNoBinaryFloatingPointType() throws {
        let files = ["Sources/Core/Rational.swift", "Sources/Core/Dimension.swift", "Sources/Core/TapeEngine.swift"]
        for path in files {
            let text = try source(path)
            XCTAssertFalse(text.contains("Double"), "\(path) must never mention Double")
            XCTAssertFalse(text.contains("Float"), "\(path) must never mention Float")
        }
    }

    // qa: "a test asserts that only the solver modules import Foundation's
    // math functions" -- sqrt/sin/cos/atan live only in the three solvers and
    // the boundary helper they share.
    func testMathFunctionsAreConfinedToSolverBoundaryModules() throws {
        let allowed: Set<String> = [
            "Sources/Core/RoofSolver.swift", "Sources/Core/StairSolver.swift",
            "Sources/Core/AreaVolumeSolver.swift", "Sources/Core/SolverBoundary.swift",
        ]
        let mathTokens = ["squareRoot()", "atan2(", "sin(", "cos(", "tan("]
        let base = projectRoot.appendingPathComponent("Sources")
        let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil)
        while let file = enumerator?.nextObject() as? URL {
            guard file.pathExtension == "swift" else { continue }
            let relative = "Sources/" + file.path.replacingOccurrences(of: base.path + "/", with: "")
            guard !allowed.contains(relative) else { continue }
            let text = try String(contentsOf: file, encoding: .utf8)
            for token in mathTokens {
                XCTAssertFalse(text.contains(token), "\(relative) uses \(token) outside a solver boundary module")
            }
        }
    }

    // qa: "for 10,000 randomly generated solver inputs the displayed value
    // differs from the exact value by at most half of the display precision
    // -- no more than 1/128 in when the user is working at 1/64."
    func testSolverBoundaryDisplayRoundingStaysWithinHalfThePrecisionUnitOver10000Cases() throws {
        var rng = SeededGenerator(seed: 2024)
        var checked = 0
        for _ in 0..<10_000 {
            let run = Length(Int.random(in: 12...600, using: &rng), .inches)
            let pitch = Rational(Int.random(in: 1...24, using: &rng))
            let result = try RoofSolver.solve(rise: nil, run: run, diagonal: nil, pitchPer12: pitch)
            for precision in FractionPrecision.allCases {
                let displayed = result.commonRafter.inches.rounded(toNearestFractionOf: precision.denominator)
                let delta = abs(displayed.doubleValueForTesting - result.commonRafter.inches.doubleValueForTesting)
                XCTAssertLessThanOrEqual(delta, 1.0 / Double(2 * precision.denominator) + 1e-9)
            }
            checked += 1
        }
        XCTAssertEqual(checked, 10_000)
    }
}

private extension Rational {
    /// Test-only bridge (never used by the app itself): avoids re-adding a
    /// `Double` accessor to the production Rational type just to assert
    /// against it here.
    var doubleValueForTesting: Double { Double(numerator) / Double(denominator) }
}
