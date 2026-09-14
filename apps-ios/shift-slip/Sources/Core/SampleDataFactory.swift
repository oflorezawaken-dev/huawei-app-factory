import Foundation
import SwiftData

/// First-run sample data (F011): two jobs and three weeks of shifts, every
/// row flagged `isSample`, so the app is a populated tool in ten seconds
/// instead of four empty tabs -- which is also what an App Store reviewer sees.
enum SampleDataFactory {
    /// Inserts sample jobs and shifts into `context`, anchored so the most
    /// recent sample shift is "yesterday" relative to `today`.
    @MainActor
    static func insertSampleData(into context: ModelContext, today: Date = .now, calendar: Calendar = .current) {
        let restaurant = Job(name: "The Grove Bistro", payType: .hourlyPlusTips, baseRate: 2.13,
                              employerName: "The Grove Bistro LLC", businessName: "The Grove Bistro",
                              occupationLabel: "Server", currencyCode: "USD", currencySymbol: "$",
                              payPeriodCycle: .weekly(startWeekday: 2), isSample: true, createdAt: today)
        restaurant.defaultTipOutRule = [
            TipOutRecipientRule(name: "Bar", type: .percentOfTips, value: 5),
            TipOutRecipientRule(name: "Busser", type: .percentOfTips, value: 3),
        ]
        context.insert(restaurant)

        let cafe = Job(name: "Roasted Coffee Co.", payType: .hourlyPlusTips, baseRate: 12.00,
                        employerName: "Roasted Coffee Co.", businessName: "Roasted Coffee Co.",
                        occupationLabel: "Barista", currencyCode: "USD", currencySymbol: "$",
                        payPeriodCycle: .weekly(startWeekday: 2), isSample: true, createdAt: today)
        context.insert(cafe)

        let dayStart = calendar.startOfDay(for: today)
        // A repeating but not-identical pattern across 21 days, so charts and
        // roll-ups have real variation without needing true randomness.
        let restaurantPattern: [(dayOffset: Int, hours: Decimal, cash: Decimal, charge: Decimal, sales: Decimal)] = [
            (-1, 6.5, 38, 142, 610), (-2, 5.0, 22, 96, 420), (-4, 7.0, 51, 188, 780),
            (-6, 6.0, 30, 120, 505), (-8, 5.5, 26, 108, 470), (-9, 7.5, 60, 210, 860),
            (-11, 6.5, 34, 130, 560), (-13, 5.0, 20, 90, 400), (-15, 7.0, 48, 175, 730),
            (-16, 6.0, 28, 118, 495), (-18, 6.5, 40, 150, 640), (-20, 5.5, 24, 100, 440),
        ]
        for entry in restaurantPattern {
            let date = calendar.date(byAdding: .day, value: entry.dayOffset, to: dayStart)!
            addShift(to: restaurant, in: context, date: date, hours: entry.hours,
                     cash: entry.cash, charge: entry.charge, sales: entry.sales, calendar: calendar)
        }

        let cafePattern: [(dayOffset: Int, hours: Decimal, cash: Decimal, charge: Decimal)] = [
            (-1, 5.0, 12, 34), (-3, 4.5, 9, 28), (-5, 6.0, 16, 42), (-7, 5.0, 11, 30),
            (-10, 4.5, 8, 26), (-12, 6.0, 18, 45), (-14, 5.0, 10, 31), (-17, 4.5, 9, 27),
            (-19, 6.0, 17, 44),
        ]
        for entry in cafePattern {
            let date = calendar.date(byAdding: .day, value: entry.dayOffset, to: dayStart)!
            addShift(to: cafe, in: context, date: date, hours: entry.hours,
                     cash: entry.cash, charge: entry.charge, sales: nil, calendar: calendar)
        }
    }

    @MainActor
    private static func addShift(to job: Job, in context: ModelContext, date: Date, hours: Decimal,
                                  cash: Decimal, charge: Decimal, sales: Decimal?, calendar: Calendar) {
        let start = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date)!
        let end = calendar.date(byAdding: .minute, value: Int(truncating: (hours * 60) as NSNumber),
                                 to: start)!
        let shift = Shift(job: job, entryMode: .times, startTime: start, endTime: end,
                           cashTips: cash, chargeTips: charge, sales: sales, isSample: true,
                           createdAt: date, calendar: calendar)
        if !job.defaultTipOutRule.isEmpty {
            shift.tipOutShares = TipOutEngine.resolve(recipients: job.defaultTipOutRule,
                                                       voluntaryTips: cash + charge,
                                                       sales: sales ?? 0)
        }
        context.insert(shift)
        job.lastUsedAt = date
    }

    /// Deletes exactly the sample rows -- jobs and shifts -- and never a
    /// user-entered one (F011).
    @MainActor
    static func removeSampleData(from context: ModelContext) {
        let sampleShifts = (try? context.fetch(FetchDescriptor<Shift>(predicate: #Predicate { $0.isSample }))) ?? []
        for shift in sampleShifts { context.delete(shift) }
        let sampleJobs = (try? context.fetch(FetchDescriptor<Job>(predicate: #Predicate { $0.isSample }))) ?? []
        for job in sampleJobs { context.delete(job) }
    }
}
