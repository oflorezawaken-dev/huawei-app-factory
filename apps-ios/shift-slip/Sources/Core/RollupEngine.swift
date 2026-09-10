import Foundation

/// One shift's figures plus the metadata roll-ups group by. `assignedDate` is
/// always the shift's start date -- an overnight shift belongs to the day it
/// started, in every roll-up and on the daily tip record (F005), never the
/// day it ended.
struct RollupInput {
    var jobID: UUID
    var assignedDate: Date
    var figures: ShiftFigures
}

/// A summed group of shifts: a day, a week, a pay period or a month. Every
/// per-shift figure it reports is derived from the same `ShiftFigures` used
/// per-shift, so a roll-up total can never disagree with the sum of its parts.
struct Rollup {
    var hours: Decimal = 0
    var basePay: Decimal = 0
    var tipsKept: Decimal = 0
    var totalPay: Decimal = 0
    var voluntaryTips: Decimal = 0
    var serviceCharges: Decimal = 0
    var shiftCount: Int = 0

    var effectiveHourly: Decimal? {
        guard hours > 0 else { return nil }
        return totalPay / hours
    }

    mutating func add(_ figures: ShiftFigures, serviceCharges: Decimal = 0) {
        hours += figures.hours
        basePay += EarningsEngine.basePay(figures)
        tipsKept += EarningsEngine.tipsKept(figures)
        totalPay += EarningsEngine.totalPay(figures)
        voluntaryTips += figures.voluntaryTips
        self.serviceCharges += serviceCharges
        shiftCount += 1
    }
}

enum RollupEngine {
    /// Groups by calendar day (using each input's `assignedDate`, already
    /// normalised to a start of day).
    static func byDay(_ inputs: [RollupInput], calendar: Calendar) -> [Date: Rollup] {
        var result: [Date: Rollup] = [:]
        for input in inputs {
            let day = calendar.startOfDay(for: input.assignedDate)
            result[day, default: Rollup()].add(input.figures)
        }
        return result
    }

    /// Groups by the pay-period window each input's date falls in, keyed by
    /// the window's start. A shift is assigned to exactly one window because
    /// `PayPeriodEngine.window` always returns the same half-open interval for
    /// every date inside it.
    static func byPeriod(_ inputs: [RollupInput], cycle: PayPeriodCycle, calendar: Calendar) -> [DateInterval: Rollup] {
        var result: [DateInterval: Rollup] = [:]
        for input in inputs {
            let window = PayPeriodEngine.window(containing: input.assignedDate, cycle: cycle, calendar: calendar)
            result[window, default: Rollup()].add(input.figures)
        }
        return result
    }

    static func byMonth(_ inputs: [RollupInput], calendar: Calendar) -> [DateInterval: Rollup] {
        byPeriod(inputs, cycle: .monthly, calendar: calendar)
    }

    /// The sum across every input, independent of grouping -- used to prove a
    /// set of roll-ups accounts for every shift exactly once.
    static func total(_ inputs: [RollupInput]) -> Rollup {
        var rollup = Rollup()
        for input in inputs { rollup.add(input.figures) }
        return rollup
    }
}
