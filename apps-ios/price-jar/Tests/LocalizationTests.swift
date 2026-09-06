import XCTest
@testable import PriceJar

/// The string catalogue must have a real, non-empty, "translated" value for
/// every key in all nine registry languages -- a missing or "new" entry
/// silently falls back to the raw key text on screen.
final class LocalizationTests: XCTestCase {
    private static let expectedLanguages: Set<String> = ["en", "es", "pt-PT", "fr", "de", "it", "tr", "ar", "zh-Hans"]

    private func loadCatalog() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return json
    }

    func testEveryKeyIsFullyTranslatedInAllNineLanguages() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(catalog["sourceLanguage"] as? String, "en")
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        XCTAssertFalse(strings.isEmpty)

        var incomplete: [String] = []
        for (key, entry) in strings {
            guard let entryDict = entry as? [String: Any],
                  let localizations = entryDict["localizations"] as? [String: Any] else {
                incomplete.append("\(key): no localizations")
                continue
            }
            let presentLanguages = Set(localizations.keys)
            if presentLanguages != Self.expectedLanguages {
                incomplete.append("\(key): languages \(presentLanguages) != expected")
                continue
            }
            for (language, localization) in localizations {
                guard let localizationDict = localization as? [String: Any],
                      let stringUnit = localizationDict["stringUnit"] as? [String: Any],
                      let state = stringUnit["state"] as? String,
                      let value = stringUnit["value"] as? String else {
                    incomplete.append("\(key)/\(language): malformed stringUnit")
                    continue
                }
                if state != "translated" || value.trimmingCharacters(in: .whitespaces).isEmpty {
                    incomplete.append("\(key)/\(language): state=\(state) value='\(value)'")
                }
            }
        }
        XCTAssertTrue(incomplete.isEmpty, "Incomplete translations:\n\(incomplete.joined(separator: "\n"))")
    }

    func testNoDuplicateKeyDifferingOnlyByWhitespace() throws {
        let catalog = try loadCatalog()
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let normalized = strings.keys.map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertEqual(Set(normalized).count, strings.keys.count)
    }
}
