import CoreGraphics

/// Arranges a row of equal-sized square keys to fit whatever width the screen
/// actually offers, instead of assuming one. This is the fix for the Sudoku
/// failure mode named in factory rule 8: nine 48pt keys were placed in a
/// 384pt row and the ninth became unreachable. SiteCalc's keypad is denser
/// than Sudoku's, so every row goes through this function first: it measures
/// the width, then wraps to more rows before it will ever shrink a key below
/// the 44x44pt accessibility minimum.
enum KeypadLayout {
    static let minKeySize: CGFloat = 44
    /// Keys are square, so width alone would make them grow without bound: on a
    /// 440pt phone the 4-column digit grid worked out to 100pt keys and 424pt of
    /// keypad, which pushed the equals bar off the bottom of the screen. A key
    /// is a thumb target, not a billboard.
    static let maxKeySize: CGFloat = 64
    static let idealSpacing: CGFloat = 8
    static let minSpacing: CGFloat = 4

    struct Metrics: Equatable {
        let columns: Int
        let keySize: CGFloat
        let spacing: CGFloat
        let rowCount: Int

        /// The total width this arrangement actually occupies -- must never
        /// exceed the width it was given.
        var occupiedWidth: CGFloat {
            keySize * CGFloat(columns) + spacing * CGFloat(max(columns - 1, 0))
        }
    }

    /// - Parameters:
    ///   - keyCount: total number of keys in this row group.
    ///   - preferredColumns: the layout's ideal column count at ample width.
    ///   - availableWidth: the width actually offered by the screen, measured
    ///     by the caller (a GeometryReader) before this is called -- never
    ///     assumed.
    /// - Parameter availableHeight: the height this group may occupy, when the
    ///   caller knows it. Width alone decided the key size until the equals bar
    ///   ended up below the bottom of the screen on the widest iPhone -- the
    ///   Sudoku failure mode, vertical this time, which is why the height is
    ///   part of the measurement now and not an afterthought.
    static func arrange(keyCount: Int, preferredColumns: Int, availableWidth: CGFloat,
                        availableHeight: CGFloat? = nil) -> Metrics {
        // A key count or column count of zero is a caller bug and should trap.
        // A width of zero is NOT: SwiftUI runs a body before the layout system
        // has a size to offer, so a GeometryReader legitimately reports 0 on
        // the first pass. Trapping on it crashed the app on launch -- the very
        // function written to keep a key from falling off the screen took the
        // whole screen with it. An unknown width yields the ideal arrangement
        // at the minimum key size, which the next pass replaces with the real
        // measurement.
        precondition(keyCount > 0 && preferredColumns > 0)
        guard availableWidth.isFinite, availableWidth > 0 else {
            let columns = min(preferredColumns, keyCount)
            return Metrics(columns: columns, keySize: minKeySize, spacing: idealSpacing,
                           rowCount: (keyCount + columns - 1) / columns)
        }
        var columns = min(preferredColumns, keyCount)

        // Shrink the column count until ideally-spaced keys fit at >=44pt.
        while columns > 1 {
            let size = keySize(forColumns: columns, spacing: idealSpacing, availableWidth: availableWidth)
            if size >= minKeySize { break }
            columns -= 1
        }

        var spacing = idealSpacing
        var size = keySize(forColumns: columns, spacing: spacing, availableWidth: availableWidth)

        if size < minKeySize {
            // Ideal spacing does not leave room for a 44pt key even at one
            // column per row; tighten spacing before ever shrinking the key.
            spacing = minSpacing
            size = keySize(forColumns: columns, spacing: spacing, availableWidth: availableWidth)
        }

        size = min(size, maxKeySize)
        let rowCount = (keyCount + columns - 1) / columns

        // Fit the rows into the height the caller can spare, if it said so.
        if let availableHeight, availableHeight.isFinite, availableHeight > 0, rowCount > 0 {
            let spacingTotal = spacing * CGFloat(max(rowCount - 1, 0))
            let perRow = (availableHeight - spacingTotal) / CGFloat(rowCount)
            size = min(size, perRow)
        }

        // Keys never shrink below the accessibility minimum, even if that
        // means this group is larger than the space offered and the caller
        // must let it scroll rather than compress further.
        size = max(size, minKeySize)

        return Metrics(columns: columns, keySize: size, spacing: spacing, rowCount: rowCount)
    }

    private static func keySize(forColumns columns: Int, spacing: CGFloat, availableWidth: CGFloat) -> CGFloat {
        let spacingTotal = spacing * CGFloat(max(columns - 1, 0))
        return (availableWidth - spacingTotal) / CGFloat(columns)
    }
}
