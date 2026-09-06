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

    /// Every literal string passed to a known text-producing SwiftUI
    /// initializer (including a custom view's `title:`-labeled parameter)
    /// must exist in the catalog. This is what would have caught the
    /// "priceBook.category.all" chip: `CategoryChip`'s own `title:
    /// LocalizedStringKey` parameter is invisible to Xcode's built-in string
    /// extraction, so a forgotten key there rendered literally on screen
    /// instead of failing anything -- until this test runs.
    func testEveryLocalizationLikeLiteralInSourceExistsInTheCatalog() throws {
        let catalog = try loadCatalog()
        let catalogKeys = Set(try XCTUnwrap(catalog["strings"] as? [String: Any]).keys)

        let sourcesURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources")
        let enumerator = FileManager.default.enumerator(at: sourcesURL, includingPropertiesForKeys: nil)

        // Each pattern captures the raw quoted literal body (up to the next
        // quote); interpolation, if any, is truncated off in `check` below,
        // since a call site like `Text("key \(count)")` cannot be matched by
        // requiring the closing quote to immediately follow a dotted key.
        let patterns = [
            // First positional string argument to a known text-producing call.
            #"(?:Text|Label|Button|Toggle|Picker|Section|TextField|LabeledContent|ContentUnavailableView|DatePicker|PhotosPicker|Link|Stepper)\(\s*"([^"]+)"#,
            // A custom view's `title:` labeled parameter (e.g. CategoryChip).
            #"\btitle:\s*"([^"]+)"#,
            #"\.navigationTitle\(\s*"([^"]+)"#,
            #"\.alert\(\s*"([^"]+)"#,
            #"LocalizedStringKey\(\s*"([^"]+)"\s*\)"#,
            #"notEnoughData\(\s*"([^"]+)"\s*\)"#,
            #"\.value\(\s*"([^"]+)"#,
            // First element of a badge-style return tuple, e.g. ("verdict.best", .green, "star.fill").
            #"return \("([^"]+)","#,
            // A ternary title, e.g. `.navigationTitle(item == nil ? "edit.new" : "edit.existing")`
            // or `Button(didSave ? "verdict.saved" : "verdict.save", ...)`. Deliberately narrower
            // than a bare `? "..." : "..."` scan, which also matches unrelated ternaries choosing
            // between two SF Symbol names (e.g. a torch icon) that are not localization keys.
            #"(?:\.navigationTitle|Button)\([^)]*?\?\s*"([^"]+)"\s*:\s*"([^"]+)"\s*[,)]"#,
        ]
        let compiled = try patterns.map { try NSRegularExpression(pattern: $0) }

        var missing: Set<String> = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            let fullRange = NSRange(text.startIndex..., in: text)

            func check(_ rawKey: String) {
                // Interpolation truncates the literal at the first space, e.g.
                // `"edit.deleteConfirm.title \(count)"` -> "edit.deleteConfirm.title".
                let key = rawKey.split(separator: " ", maxSplits: 1).first.map(String.init) ?? rawKey
                // Not every quoted literal in these positions is a
                // dot-separated key (e.g. a plain sentence or an SF Symbol
                // name); only validate ones that look like one.
                guard key.range(of: #"^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z0-9]+)+$"#, options: .regularExpression) != nil else { return }
                let candidates = [key, "\(key) %lld", "\(key) %@", "\(key) %lld %lld", "\(key) %@ %@"]
                guard !candidates.contains(where: catalogKeys.contains) else { return }
                missing.insert("\(key) (in \(url.lastPathComponent))")
            }

            for regex in compiled {
                for match in regex.matches(in: text, range: fullRange) {
                    for groupIndex in 1..<match.numberOfRanges {
                        guard let range = Range(match.range(at: groupIndex), in: text) else { continue }
                        check(String(text[range]))
                    }
                }
            }
        }
        XCTAssertTrue(missing.isEmpty, "Localization-shaped literals missing from the catalog:\n\(missing.sorted().joined(separator: "\n"))")
    }
}
