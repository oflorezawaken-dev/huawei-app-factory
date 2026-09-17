import XCTest
@testable import SiteCalc

/// Every key the app builds at runtime must exist in the String Catalog, and
/// must be looked up in a way that actually finds it.
///
/// Both halves failed once. `Text(LocalizedStringKey("material.category.\(raw)"))`
/// looks like a lookup and is not one: SwiftUI treats an interpolated
/// `LocalizedStringKey` as a *format string* with an argument, so it searches
/// for "material.category.%@", finds nothing, and renders the literal
/// "material.category.concrete" on screen. It shipped into a store screenshot
/// that way. The fix is `localized("material.category." + raw)`, which composes
/// the key first and then looks it up -- and this test is what keeps it fixed.
final class LocalizationKeyTests: XCTestCase {
    private func assertLocalized(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        let value = localized(key)
        XCTAssertNotEqual(value, key,
                          "'\(key)' has no String Catalog entry -- the raw key would show on screen",
                          file: file, line: line)
        XCTAssertFalse(value.isEmpty, "'\(key)' is empty", file: file, line: line)
    }

    func testEveryShapeHasANameAndAHint() {
        for shape in AreaVolumeShape.allCases {
            assertLocalized("areaVolume.shape.\(shape.rawValue)")
            assertLocalized("areaVolume.hint.\(shape.rawValue)")
        }
    }

    func testEveryMaterialCategoryHasANameAndAHint() {
        for category in MaterialCategory.allCases {
            assertLocalized("material.category.\(category.rawValue)")
            assertLocalized("material.hint.\(category.rawValue)")
        }
    }

    func testEveryGenericFieldLabelExists() {
        for key in ["a", "b", "c", "d"] {
            assertLocalized("areaVolume.field.\(key)")
        }
    }

    func testTheKeyboardDoneButtonIsTranslated() {
        assertLocalized("common.done")
    }
}
