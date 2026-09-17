import XCTest
import CoreGraphics
@testable import SiteCalc

/// qa: "the keypad measures the width it is offered before placing anything,
/// wraps or shrinks, and is verified at 320/375/393/430 pt with no key under
/// 44x44."
///
/// That criterion was in the spec and in the comments and had no test at all,
/// which is how the crash below survived: `arrange` trapped on a width of 0,
/// SwiftUI legitimately passes 0 on the first layout pass, and the app died on
/// launch in the screenshot run. A rule nothing exercises is a comment.
final class KeypadLayoutTests: XCTestCase {
    /// The three real row groups on S001, with the column counts KeypadView asks for.
    private let groups: [(name: String, keyCount: Int, preferredColumns: Int)] = [
        ("units", 6, 6),      // FT IN YD M CM MM
        ("utilities", 6, 6),  // C ⌫ % O.C. + −
        ("digits", 14, 4),    // 0-9 . / × ÷
    ]

    /// 320 is an iPhone SE in Display Zoom, the narrowest layout iOS 17 offers;
    /// 430 is the widest iPhone. A keypad that survives both survives the range.
    private let widths: [CGFloat] = [320, 375, 393, 430]

    func testNoKeyEverFallsBelowTheAccessibilityMinimum() {
        for group in groups {
            for width in widths {
                let m = KeypadLayout.arrange(keyCount: group.keyCount,
                                             preferredColumns: group.preferredColumns,
                                             availableWidth: width)
                XCTAssertGreaterThanOrEqual(m.keySize, KeypadLayout.minKeySize,
                                            "\(group.name) at \(width)pt shrank a key to \(m.keySize)")
            }
        }
    }

    func testEveryKeyIsReachable() {
        // Sudoku's ninth key fell off a 384pt row. Capacity must cover the row.
        for group in groups {
            for width in widths {
                let m = KeypadLayout.arrange(keyCount: group.keyCount,
                                             preferredColumns: group.preferredColumns,
                                             availableWidth: width)
                XCTAssertGreaterThanOrEqual(m.columns * m.rowCount, group.keyCount,
                                            "\(group.name) at \(width)pt holds \(m.columns * m.rowCount) of \(group.keyCount)")
            }
        }
    }

    func testTheArrangementFitsTheWidthItWasGiven() {
        for group in groups {
            for width in widths {
                let m = KeypadLayout.arrange(keyCount: group.keyCount,
                                             preferredColumns: group.preferredColumns,
                                             availableWidth: width)
                XCTAssertLessThanOrEqual(m.occupiedWidth, width + 0.001,
                                         "\(group.name) at \(width)pt occupies \(m.occupiedWidth)")
            }
        }
    }

    func testItWrapsBeforeItShrinks() {
        // A width that cannot hold six 44pt keys must drop to fewer columns and
        // more rows, never to a 30pt key.
        let m = KeypadLayout.arrange(keyCount: 6, preferredColumns: 6, availableWidth: 200)
        XCTAssertLessThan(m.columns, 6)
        XCTAssertGreaterThan(m.rowCount, 1)
        XCTAssertGreaterThanOrEqual(m.keySize, KeypadLayout.minKeySize)
    }

    /// The equals bar landed at y=968 on a 956pt-tall screen: off the bottom,
    /// untappable, and XCUITest could not even scroll to it. The cause was that
    /// keys are square and were sized from the width alone, so the 4-column
    /// digit grid became 100pt keys and 424pt of keypad on a 440pt phone.
    func testKeysDoNotGrowWithoutBound() {
        for width in [CGFloat(393), 430, 440, 1024] {
            let m = KeypadLayout.arrange(keyCount: 14, preferredColumns: 4, availableWidth: width)
            XCTAssertLessThanOrEqual(m.keySize, KeypadLayout.maxKeySize,
                                     "a \(m.keySize)pt key at \(width)pt wide is a billboard, not a thumb target")
        }
    }

    func testAGroupFitsTheHeightItIsGiven() {
        // 4 rows of digits in the height a 6.9in screen can actually spare.
        for height in [CGFloat(200), 260, 320, 424] {
            let m = KeypadLayout.arrange(keyCount: 14, preferredColumns: 4,
                                         availableWidth: 424, availableHeight: height)
            let occupied = m.keySize * CGFloat(m.rowCount) + m.spacing * CGFloat(m.rowCount - 1)
            XCTAssertLessThanOrEqual(occupied, height + 0.001,
                                     "the grid took \(occupied)pt of a \(height)pt budget")
            XCTAssertGreaterThanOrEqual(m.keySize, KeypadLayout.minKeySize)
        }
    }

    func testAnImpossibleHeightStillKeepsTheAccessibilityMinimum() {
        // Given less room than 44pt rows need, the keypad keeps 44 and the
        // caller has to scroll -- it must never quietly ship a 20pt key.
        let m = KeypadLayout.arrange(keyCount: 14, preferredColumns: 4,
                                     availableWidth: 424, availableHeight: 60)
        XCTAssertEqual(m.keySize, KeypadLayout.minKeySize)
    }

    /// The crash. SwiftUI evaluates a body before the layout system has a size,
    /// so a GeometryReader reports 0 on the first pass; `arrange` used to
    /// `precondition` on it and take the app down on launch.
    func testAnUnmeasuredWidthIsNotAProgrammerError() {
        for width in [CGFloat(0), -1, .nan, .infinity] {
            let m = KeypadLayout.arrange(keyCount: 14, preferredColumns: 4, availableWidth: width)
            XCTAssertGreaterThanOrEqual(m.keySize, KeypadLayout.minKeySize)
            XCTAssertGreaterThanOrEqual(m.columns * m.rowCount, 14)
            XCTAssertEqual(m.columns, 4, "an unknown width keeps the ideal arrangement until the real one arrives")
        }
    }
}
