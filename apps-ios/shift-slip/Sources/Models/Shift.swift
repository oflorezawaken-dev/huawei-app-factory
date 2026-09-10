import Foundation
import SwiftData

/// One logged shift (F002/F003/F004/F005). All arithmetic lives in the pure
/// `EarningsEngine` / `TipOutEngine`, driven by a `ShiftFigures` snapshot
/// built from this model's stored fields, so the model itself holds data and
/// never duplicates the maths.
@Model
final class Shift {
    var id: UUID = UUID()
    var job: Job?
    var entryModeRaw: String = ShiftEntryMode.times.rawValue
    /// The shift's start instant. For `.hours` entry mode this is still set
    /// (midnight of the chosen date) so `assignedDate` and sorting stay simple.
    var startTime: Date = Date.now
    /// Set only in `.times` mode. Already placed on the correct calendar day
    /// (the next day, for a shift that crosses midnight) by the editor, so
    /// `EarningsEngine.hoursBetween` sees true elapsed time across any DST change.
    var endTime: Date?
    /// Set only in `.hours` mode.
    var manualHoursValue: Decimal?
    /// Start-of-day of `startTime`. An overnight shift belongs to the day it
    /// started in every roll-up and on the daily tip record (F005) -- stored
    /// explicitly (not recomputed ad hoc) so every query groups the same way.
    var assignedDate: Date = Date.now
    var cashTips: Decimal = 0
    var chargeTips: Decimal = 0
    var noncashTips: Decimal = 0
    /// Service charges and mandatory auto-gratuities -- never voluntary tips,
    /// kept in a column that never mixes with cash/charge tips (F004).
    var serviceCharges: Decimal = 0
    var sales: Decimal?
    var tipOutIsManual: Bool = false
    var tipOutManualAmount: Decimal?
    var closeoutPhotoFileName: String?
    var isSample: Bool = false
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \TipOutShareRecord.shift)
    var tipOutShareRecords: [TipOutShareRecord]? = []

    init(job: Job?, entryMode: ShiftEntryMode, startTime: Date, endTime: Date? = nil,
         manualHoursValue: Decimal? = nil, cashTips: Decimal = 0, chargeTips: Decimal = 0,
         noncashTips: Decimal = 0, serviceCharges: Decimal = 0, sales: Decimal? = nil,
         isSample: Bool = false, createdAt: Date = .now, calendar: Calendar = .current) {
        self.job = job
        self.entryModeRaw = entryMode.rawValue
        self.startTime = startTime
        self.endTime = endTime
        self.manualHoursValue = manualHoursValue
        self.assignedDate = calendar.startOfDay(for: startTime)
        self.cashTips = cashTips
        self.chargeTips = chargeTips
        self.noncashTips = noncashTips
        self.serviceCharges = serviceCharges
        self.sales = sales
        self.isSample = isSample
        self.createdAt = createdAt
    }

    var entryMode: ShiftEntryMode {
        get { ShiftEntryMode(rawValue: entryModeRaw) ?? .times }
        set { entryModeRaw = newValue.rawValue }
    }

    var hours: Decimal {
        switch entryMode {
        case .times:
            guard let endTime else { return 0 }
            return EarningsEngine.hoursBetween(startTime, endTime)
        case .hours:
            return manualHoursValue ?? 0
        }
    }

    var tipOutShares: [TipOutRecipientShare] {
        get {
            (tipOutShareRecords ?? [])
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { TipOutRecipientShare(id: $0.id, name: $0.name, type: $0.type, value: $0.value,
                                             resolvedAmount: $0.resolvedAmount) }
        }
        set {
            tipOutShareRecords?.removeAll()
            for (index, share) in newValue.enumerated() {
                let record = TipOutShareRecord(shift: self, name: share.name, type: share.type,
                                                value: share.value, resolvedAmount: share.resolvedAmount,
                                                sortIndex: index)
                tipOutShareRecords?.append(record)
            }
        }
    }

    var tipOutTotal: Decimal {
        tipOutIsManual ? (tipOutManualAmount ?? 0) : tipOutShares.reduce(Decimal(0)) { $0 + $1.resolvedAmount }
    }

    var figures: ShiftFigures {
        ShiftFigures(hours: hours, baseRate: job?.baseRate ?? 0, cashTips: cashTips,
                     chargeTips: chargeTips, tipOutTotal: tipOutTotal, sales: sales)
    }

    var tipsKept: Decimal { EarningsEngine.tipsKept(figures) }
    var basePay: Decimal { EarningsEngine.basePay(figures) }
    var totalPay: Decimal { EarningsEngine.totalPay(figures) }
    var effectiveHourly: Decimal? { EarningsEngine.effectiveHourly(figures) }
    var tipsPerHour: Decimal? { EarningsEngine.tipsPerHour(figures) }
    var tipPercentage: Decimal? { EarningsEngine.tipPercentage(figures) }
}

/// One recipient's resolved share on a specific shift (F003). A real
/// SwiftData relationship, so a saved shift's tip-out never changes just
/// because the job's default rule changes afterward.
@Model
final class TipOutShareRecord {
    var id: UUID = UUID()
    var shift: Shift?
    var name: String = ""
    var typeRaw: String = TipOutRuleType.percentOfTips.rawValue
    var value: Decimal = 0
    var resolvedAmount: Decimal = 0
    var sortIndex: Int = 0

    init(shift: Shift?, name: String, type: TipOutRuleType, value: Decimal, resolvedAmount: Decimal, sortIndex: Int) {
        self.shift = shift
        self.name = name
        self.typeRaw = type.rawValue
        self.value = value
        self.resolvedAmount = resolvedAmount
        self.sortIndex = sortIndex
    }

    var type: TipOutRuleType {
        get { TipOutRuleType(rawValue: typeRaw) ?? .percentOfTips }
        set { typeRaw = newValue.rawValue }
    }
}
