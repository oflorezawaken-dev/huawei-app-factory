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
    static func arrange(keyCount: Int, preferredColumns: Int, availableWidth: CGFloat) -> Metrics {
        precondition(keyCount > 0 && preferredColumns > 0 && availableWidth > 0)
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

        // Keys never shrink below the accessibility minimum, even if that
        // means this row's content is wider than the screen and the caller
        // must let it scroll horizontally rather than compress further.
        size = max(size, minKeySize)

        let rowCount = (keyCount + columns - 1) / columns
        return Metrics(columns: columns, keySize: size, spacing: spacing, rowCount: rowCount)
    }

    private static func keySize(forColumns columns: Int, spacing: CGFloat, availableWidth: CGFloat) -> CGFloat {
        let spacingTotal = spacing * CGFloat(max(columns - 1, 0))
        return (availableWidth - spacingTotal) / CGFloat(columns)
    }
}
