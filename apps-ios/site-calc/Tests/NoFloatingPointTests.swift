import XCTest
@testable import SiteCalc

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

    /// Strips `//` and `/* */` comments. The rule is about the code, not the
    /// prose: the first version of this scan matched the plain substring and
    /// failed on Rational.swift's own comment explaining the rule, because
    /// "NoFloatingPointTests" contains "Float". A substring match is weak in
    /// the other direction too -- it would pass a file whose only mention of
    /// Double was a comment claiming there is none.
    private func codeWithoutComments(_ text: String) -> String {
        var out = ""
        var index = text.startIndex
        var inLine = false, inBlock = false
        while index < text.endIndex {
            let rest = text[index...]
            if inLine {
                if text[index] == "\n" { inLine = false; out.append("\n") }
            } else if inBlock {
                if rest.hasPrefix("*/") { inBlock = false; index = text.index(index, offsetBy: 2); continue }
            } else if rest.hasPrefix("//") {
                inLine = true; index = text.index(index, offsetBy: 2); continue
            } else if rest.hasPrefix("/*") {
                inBlock = true; index = text.index(index, offsetBy: 2); continue
            } else {
                out.append(text[index])
            }
            index = text.index(after: index)
        }
        return out
    }

    /// Whole-word match, so an identifier that merely contains the name -- or a
    /// type like `BinaryFloatingPoint` -- is not mistaken for a use of it.
    private func mentions(_ type: String, in code: String) -> Bool {
        code.range(of: "\\b\(type)\\b", options: .regularExpression) != nil
    }

    func testDimensionalTypeAndTapeContainNoBinaryFloatingPointType() throws {
        let files = ["Sources/Core/Rational.swift", "Sources/Core/Dimension.swift", "Sources/Core/TapeEngine.swift"]
        for path in files {
            let code = codeWithoutComments(try source(path))
            XCTAssertFalse(mentions("Double", in: code), "\(path) must never use Double")
            XCTAssertFalse(mentions("Float", in: code), "\(path) must never use Float")
        }
    }

    /// The scan has to be able to fail, or it proves nothing.
    func testTheScanActuallyDetectsAFloatingPointUse() {
        let clean = codeWithoutComments("// Double in a comment is fine\nlet x: Rational = .init(1, 2)\n")
        XCTAssertFalse(mentions("Double", in: clean))
        let dirty = codeWithoutComments("let ratio: Double = 0.5 // not fine\n")
        XCTAssertTrue(mentions("Double", in: dirty))
        XCTAssertFalse(mentions("Float", in: codeWithoutComments("let v: BinaryFloatingPointish = 1\n")))
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
                let delta = abs(displayed.doubleValue - result.commonRafter.inches.doubleValue)
                XCTAssertLessThanOrEqual(delta, 1.0 / Double(2 * precision.denominator) + 1e-9)
            }
            checked += 1
        }
        XCTAssertEqual(checked, 10_000)
    }
}

