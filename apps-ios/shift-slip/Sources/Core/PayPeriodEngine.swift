import Foundation

/// The four pay-period cycles a Job can use (F001). Weekly needs a start
/// weekday (1 = Sunday ... 7 = Saturday, matching `Calendar.component(.weekday)`);
/// biweekly needs an anchor date that started some period.
enum PayPeriodCycle: Codable, Equatable {
    case weekly(startWeekday: Int)
    case biweekly(anchorDate: Date)
    case semimonthly
    case monthly
}

/// Assigns shifts to non-overlapping, gap-free windows and rolls figures up
/// per window. Pure Swift, integer day arithmetic throughout (never floating
/// seconds), so a leap day or a DST transition inside a window changes
/// nothing about which window a shift belongs to.
enum PayPeriodEngine {
    /// The half-open [start, end) window containing `date`, for one cycle.
    /// Half-open and computed the same way for every date is what guarantees
    /// every shift lands in exactly one window: there is never a boundary
    /// instant that could be claimed by two windows or by neither.
    static func window(containing date: Date, cycle: PayPeriodCycle, calendar: Calendar) -> DateInterval {
        let day = calendar.startOfDay(for: date)
        switch cycle {
        case .weekly(let startWeekday):
            let weekday = calendar.component(.weekday, from: day)
            let offset = (weekday - startWeekday + 7) % 7
            let start = calendar.date(byAdding: .day, value: -offset, to: day)!
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return DateInterval(start: start, end: end)

        case .biweekly(let anchorDate):
            let anchorDay = calendar.startOfDay(for: anchorDate)
            let daysSinceAnchor = calendar.dateComponents([.day], from: anchorDay, to: day).day!
            let periodIndex = floorDiv(daysSinceAnchor, 14)
            let start = calendar.date(byAdding: .day, value: periodIndex * 14, to: anchorDay)!
            let end = calendar.date(byAdding: .day, value: 14, to: start)!
            return DateInterval(start: start, end: end)

        case .semimonthly:
            let components = calendar.dateComponents([.year, .month, .day], from: day)
            let dayOfMonth = components.day!
            var startComponents = components
            var endComponents = components
            if dayOfMonth <= 15 {
                startComponents.day = 1
                endComponents.day = 16
                let start = calendar.date(from: startComponents)!
                let end = calendar.date(from: endComponents)!
                return DateInterval(start: start, end: end)
            } else {
                startComponents.day = 16
                let start = calendar.date(from: startComponents)!
                let nextMonthFirst = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: {
                    var c = components; c.day = 1; return c
                }())!)!
                return DateInterval(start: start, end: nextMonthFirst)
            }

        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: day)
            let start = calendar.date(from: components)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return DateInterval(start: start, end: end)
        }
    }

    /// A human label for the window, e.g. "Mar 2 - Mar 8" -- callers format
    /// with their own DateFormatter for localisation; this just gives a stable
    /// key useful for grouping/sorting.
    static func sortKey(for window: DateInterval) -> Date { window.start }

    /// Floor division that rounds toward negative infinity (unlike Swift's
    /// `/`, which truncates toward zero) so dates before the anchor land in
    /// the correct preceding period instead of off by one.
    private static func floorDiv(_ a: Int, _ b: Int) -> Int {
        let quotient = a / b
        let remainder = a % b
        return (remainder != 0 && (remainder < 0) != (b < 0)) ? quotient - 1 : quotient
    }
}
