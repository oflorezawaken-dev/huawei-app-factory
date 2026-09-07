import Foundation
import SwiftData

@Model
final class Item {
    var title: String
    var detail: String
    var intervalDays: Int
    var lastDone: Date?
    var createdAt: Date

    init(title: String, detail: String = "", intervalDays: Int = 7,
         lastDone: Date? = nil, createdAt: Date = .now) {
        self.title = title
        self.detail = detail
        self.intervalDays = intervalDays
        self.lastDone = lastDone
        self.createdAt = createdAt
    }

    /// When this item is next due, or nil while it has never been done.
    var nextDue: Date? {
        guard let lastDone else { return nil }
        return Calendar.current.date(byAdding: .day, value: intervalDays, to: lastDone)
    }

    /// Due today or overdue. A brand new item counts as due, so it is not hidden.
    func isDue(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let nextDue else { return true }
        return calendar.startOfDay(for: nextDue) <= calendar.startOfDay(for: date)
    }
}
