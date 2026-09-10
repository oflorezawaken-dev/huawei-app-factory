import Foundation

/// One line of the statutory record (F006): exactly the fields IRS
/// Publication 531 (rev. 12/2024) tells a tipped employee to write down each
/// workday, plus service charges/auto-gratuities kept in their own column,
/// clearly outside the tip fields.
struct DailyTipRecordLine: Identifiable {
    var id: String { "\(date.timeIntervalSince1970)-\(jobID)" }
    var date: Date
    var jobID: UUID
    var employerName: String
    var businessName: String
    var cashTips: Decimal
    var chargeTips: Decimal
    var noncashTips: Decimal
    var tipsPaidOut: Decimal
    var serviceCharges: Decimal
    var isSample: Bool
}

/// One raw shift's contribution to the record, before same-day-same-job rows
/// are summed together.
struct DailyTipRecordInput {
    var date: Date
    var jobID: UUID
    var employerName: String
    var businessName: String
    var cashTips: Decimal
    var chargeTips: Decimal
    var noncashTips: Decimal
    var tipOutTotal: Decimal
    var serviceCharges: Decimal
    var isSample: Bool
}

enum DailyTipRecordEngine {
    /// One line per date per job; a day with several shifts at one job sums
    /// into that day's line (F006), sorted chronologically.
    static func lines(from inputs: [DailyTipRecordInput], calendar: Calendar) -> [DailyTipRecordLine] {
        struct Key: Hashable { var day: Date; var jobID: UUID }
        var grouped: [Key: DailyTipRecordLine] = [:]

        for input in inputs {
            let day = calendar.startOfDay(for: input.date)
            let key = Key(day: day, jobID: input.jobID)
            if var existing = grouped[key] {
                existing.cashTips += input.cashTips
                existing.chargeTips += input.chargeTips
                existing.noncashTips += input.noncashTips
                existing.tipsPaidOut += input.tipOutTotal
                existing.serviceCharges += input.serviceCharges
                existing.isSample = existing.isSample || input.isSample
                grouped[key] = existing
            } else {
                grouped[key] = DailyTipRecordLine(
                    date: day, jobID: input.jobID,
                    employerName: input.employerName, businessName: input.businessName,
                    cashTips: input.cashTips, chargeTips: input.chargeTips, noncashTips: input.noncashTips,
                    tipsPaidOut: input.tipOutTotal, serviceCharges: input.serviceCharges, isSample: input.isSample)
            }
        }
        return grouped.values.sorted { $0.date == $1.date ? $0.employerName < $1.employerName : $0.date < $1.date }
    }

    static func monthTotal(_ lines: [DailyTipRecordLine]) -> Rollup {
        var totalCash: Decimal = 0, totalCharge: Decimal = 0, totalNoncash: Decimal = 0
        var totalPaidOut: Decimal = 0, totalServiceCharges: Decimal = 0
        for line in lines {
            totalCash += line.cashTips
            totalCharge += line.chargeTips
            totalNoncash += line.noncashTips
            totalPaidOut += line.tipsPaidOut
            totalServiceCharges += line.serviceCharges
        }
        var rollup = Rollup()
        rollup.voluntaryTips = totalCash + totalCharge
        rollup.serviceCharges = totalServiceCharges
        rollup.tipsKept = totalCash + totalCharge - totalPaidOut
        rollup.shiftCount = lines.count
        return rollup
    }

    /// The "due to your employer by the 10th" marker: shown only from the 1st
    /// to the 10th (inclusive) of the month *following* the closing month, and
    /// only for the month being closed out. Returns the due date to display,
    /// or nil when the marker should not show.
    static func employerReportDueDate(closingMonth: Date, today: Date, calendar: Calendar) -> Date? {
        let closingMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: closingMonth))!
        guard let dueMonthStart = calendar.date(byAdding: .month, value: 1, to: closingMonthStart) else { return nil }
        guard let dueDate = calendar.date(byAdding: .day, value: 9, to: dueMonthStart) else { return nil }
        // Window is [dueMonthStart, dueDate] i.e. the 1st through the 10th inclusive.
        let todayStart = calendar.startOfDay(for: today)
        guard todayStart >= dueMonthStart, todayStart <= dueDate else { return nil }
        return dueDate
    }
}
