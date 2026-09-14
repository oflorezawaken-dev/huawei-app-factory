import Foundation

/// A snapshot of the numbers one shift needs to answer "what did it really
/// pay" -- deliberately not the SwiftData model itself, so this whole module
/// stays pure Swift with no persistence dependency and is exhaustively
/// unit-testable per F005.
struct ShiftFigures {
    var hours: Decimal
    var baseRate: Decimal
    var cashTips: Decimal
    var chargeTips: Decimal
    var tipOutTotal: Decimal
    var sales: Decimal?

    /// Voluntary tips only (cash + charge). Noncash tips and service charges
    /// never enter cash earnings or effective hourly (F004).
    var voluntaryTips: Decimal { cashTips + chargeTips }
}

/// The earnings maths (F005). Pure Swift, Decimal throughout; a build-time
/// check fails if Double or Float appears in this module.
enum EarningsEngine {
    /// Tips actually kept after the tip-out came off.
    static func tipsKept(_ figures: ShiftFigures) -> Decimal {
        figures.voluntaryTips - figures.tipOutTotal
    }

    static func basePay(_ figures: ShiftFigures) -> Decimal {
        figures.hours * figures.baseRate
    }

    static func totalPay(_ figures: ShiftFigures) -> Decimal {
        basePay(figures) + tipsKept(figures)
    }

    /// nil when hours is zero, so the UI can show a dash instead of dividing by zero.
    static func effectiveHourly(_ figures: ShiftFigures) -> Decimal? {
        guard figures.hours > 0 else { return nil }
        return totalPay(figures) / figures.hours
    }

    static func tipsPerHour(_ figures: ShiftFigures) -> Decimal? {
        guard figures.hours > 0 else { return nil }
        return tipsKept(figures) / figures.hours
    }

    /// nil when sales were not entered, or sales is zero.
    static func tipPercentage(_ figures: ShiftFigures) -> Decimal? {
        guard let sales = figures.sales, sales > 0 else { return nil }
        return figures.voluntaryTips / sales * 100
    }

    /// Elapsed hours between two absolute instants, expressed to 2 decimal
    /// places. `start` and `end` must already be correct calendar instants
    /// (end on the next day when the shift crosses midnight) -- `Date`
    /// subtraction is instant-to-instant and is correct across a DST
    /// transition on its own, because the calendar (not a bare 24-hour
    /// assumption) is what placed `end` on its day in the first place.
    static func hoursBetween(_ start: Date, _ end: Date) -> Decimal {
        let seconds = end.timeIntervalSince(start)
        guard seconds > 0 else { return 0 }
        let hours = Decimal(seconds) / 3600
        return hours.rounded(toScale: 2)
    }
}
