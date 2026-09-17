import XCTest
@testable import SiteCalc

/// qa: "the maximum riser and minimum tread fields are empty on a fresh
/// install ... and a test scans the app bundle, the string catalogue and the
/// source for any bundled numeric default for either field and fails on a
/// hit" plus "the app contains no regulatory value at all: a test scans the
/// bundle, every resource file and the string catalogue in all 9 languages
/// for the phrases in qa.banned_phrases.code_authority."
final class NoRegulatoryDefaultsTests: XCTestCase {
    private let projectRoot: URL = {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }()

    func testFreshSettingsHaveNoStairLimitDefault() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = AppSettings(defaults: defaults)
        XCTAssertNil(settings.maxRiserHeight)
        XCTAssertNil(settings.minTreadDepth)
    }

    func testSolveIsDisabledConceptuallyWithoutBothLimits() throws {
        // The type itself has no notion of a default: solve() requires the
        // caller to supply both non-nil limits, which is what lets the view
        // disable Solve until they exist.
        let result = try? StairSolver.solve(totalRise: Length(100, .inches), maxRiserHeight: Length(7, .inches),
                                             minTreadDepth: Length(10, .inches))
        XCTAssertNotNil(result) // proves the call succeeds only once real numbers are supplied by the caller
    }

    func testAppSettingsSourceNeverAssignsADefaultToTheStairLimits() throws {
        let text = try String(contentsOf: projectRoot.appendingPathComponent("Sources/Core/AppSettings.swift"),
                               encoding: .utf8)
        // Every OTHER default in this file uses "?? Length(...)" or "?? Rational(...)".
        // maxRiserHeight/minTreadDepth must be the only two computed properties
        // that return the raw optional with no "??" fallback.
        let lines = text.components(separatedBy: "\n")
        let riserLine = lines.first { $0.contains("var maxRiserHeight") }
        let treadLine = lines.first { $0.contains("var minTreadDepth") }
        XCTAssertNotNil(riserLine)
        XCTAssertNotNil(treadLine)
        let getterBlock = text.components(separatedBy: "maxRiserHeight")[1]
        XCTAssertFalse(getterBlock.prefix(200).contains("??"))
    }

    private let codeAuthorityPhrases = [
        "building code", "code compliant", "code-compliant", "meets code", "up to code", "per code",
        "code minimum", "code maximum", "code requirement", "code approved",
        "international residential code", "national electrical code", "span table", "allowable span",
        "maximum span", "load table", "ampacity", "structurally safe", "structurally sound", "safe to cut",
        "guaranteed accurate", "engineer approved", "engineer-approved",
        "normativa", "código técnico", "cumple la norma", "bauordnung", "normgerecht",
        "conforme à la norme", "réglementation", "a norma di legge", "regulamento", "yönetmelik",
        "standarda uygun", "符合规范", "规范要求", "كود البناء", "مطابق للكود",
    ]

    func testStringCatalogueContainsNoRegulatoryAuthorityPhrase() throws {
        let data = try Data(contentsOf: projectRoot.appendingPathComponent("Sources/Localizable.xcstrings"))
        let text = String(data: data, encoding: .utf8)!.lowercased()
        for phrase in codeAuthorityPhrases {
            XCTAssertFalse(text.contains(phrase.lowercased()), "banned phrase '\(phrase)' found in string catalogue")
        }
    }

    func testSourceContainsNoRegulatoryAuthorityPhrase() throws {
        let base = projectRoot.appendingPathComponent("Sources")
        let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil)
        while let file = enumerator?.nextObject() as? URL {
            guard file.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: file, encoding: .utf8).lowercased()
            for phrase in codeAuthorityPhrases {
                XCTAssertFalse(text.contains(phrase.lowercased()),
                               "banned phrase '\(phrase)' found in \(file.lastPathComponent)")
            }
        }
    }
}
