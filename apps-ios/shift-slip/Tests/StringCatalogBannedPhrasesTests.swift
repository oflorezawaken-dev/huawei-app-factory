import XCTest
@testable import ShiftSlip

/// ShiftSlip keeps records and does arithmetic; it must never read like a tax
/// service or a wage-theft accusation, in any of the 9 shipped languages.
/// These are tests, not prose review -- they parse the actual String Catalog
/// and fail the build on a hit.
final class StringCatalogBannedPhrasesTests: XCTestCase {
    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable { let value: String? }
                let stringUnit: Unit?
            }
            let localizations: [String: Localization]?
        }
        let strings: [String: Entry]
    }

    /// Every translated string value across all 9 languages, paired with the
    /// key and locale it came from, for a precise failure message.
    private func allStrings() throws -> [(key: String, locale: String, value: String)] {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<2 { url.deleteLastPathComponent() }
        let catalogURL = url.appendingPathComponent("Sources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        var result: [(String, String, String)] = []
        for (key, entry) in catalog.strings {
            for (locale, localization) in entry.localizations ?? [:] {
                if let value = localization.stringUnit?.value {
                    result.append((key, locale, value))
                }
            }
        }
        return result
    }

    // MARK: - Tax-framing discipline (F004 / F006 / F009 copy discipline)

    private let taxBannedPhrases = [
        "irs-approved", "irs-certified", "official irs", "no tax on tips", "tax free", "tax-free",
        "your deduction", "deduct up to", "estimated refund", "maximise your refund", "maximize your refund",
        "we file", "guaranteed",
    ]

    func testNoBannedTaxPhrasingAnywhereInAnyLanguage() throws {
        var hits: [String] = []
        for entry in try allStrings() {
            let lowered = entry.value.lowercased()
            for phrase in taxBannedPhrases where lowered.contains(phrase) {
                hits.append("\(entry.key) [\(entry.locale)]: contains '\(phrase)' in \"\(entry.value)\"")
            }
        }
        XCTAssertTrue(hits.isEmpty, "Banned tax phrasing found:\n" + hits.joined(separator: "\n"))
    }

    /// "tax advice" is banned everywhere except inside the app's own
    /// not-tax-advice disclaimer ("no tax advice" / "not tax advice").
    func testTaxAdviceOnlyAppearsInsideTheDisclaimer() throws {
        var hits: [String] = []
        for entry in try allStrings() {
            let lowered = entry.value.lowercased()
            guard lowered.contains("tax advice") else { continue }
            let isDisclaimer = lowered.contains("no tax advice") || lowered.contains("not tax advice")
                || lowered.contains("gives no tax advice") || lowered.contains("is not tax advice")
            if !isDisclaimer {
                hits.append("\(entry.key) [\(entry.locale)]: \"\(entry.value)\"")
            }
        }
        XCTAssertTrue(hits.isEmpty, "'tax advice' used outside the disclaimer:\n" + hits.joined(separator: "\n"))
    }

    // MARK: - Minimum-wage check stays informational (F008)

    private let wageClaimBannedPhrases = ["illegal", "wage theft", "you are owed", "violation", "lawsuit", "claim"]

    func testMinimumWageCopyNeverReadsAsALegalClaim() throws {
        var hits: [String] = []
        for entry in try allStrings() {
            let lowered = entry.value.lowercased()
            for phrase in wageClaimBannedPhrases where lowered.contains(phrase) {
                hits.append("\(entry.key) [\(entry.locale)]: contains '\(phrase)' in \"\(entry.value)\"")
            }
        }
        XCTAssertTrue(hits.isEmpty, "Legal-claim wording found:\n" + hits.joined(separator: "\n"))
    }

    // MARK: - Catalog completeness (F015)

    func testEveryKeyHasATranslationForAllNineLanguages() throws {
        let expectedLocales: Set<String> = ["en", "es", "pt-PT", "fr", "de", "it", "tr", "ar", "zh-Hans"]
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<2 { url.deleteLastPathComponent() }
        let catalogURL = url.appendingPathComponent("Sources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)
        var incomplete: [String] = []
        for (key, entry) in catalog.strings {
            let have = Set((entry.localizations ?? [:]).compactMap { locale, localization in
                (localization.stringUnit?.value?.isEmpty == false) ? locale : nil
            })
            if !expectedLocales.isSubset(of: have) {
                incomplete.append("\(key): missing \(expectedLocales.subtracting(have))")
            }
        }
        XCTAssertTrue(incomplete.isEmpty, "Incomplete translations:\n" + incomplete.joined(separator: "\n"))
    }
}
