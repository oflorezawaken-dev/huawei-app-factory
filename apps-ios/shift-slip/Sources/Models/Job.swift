import Foundation
import SwiftData

enum PayType: String, Codable, CaseIterable, Identifiable, Sendable {
    case hourly
    case hourlyPlusTips
    case commission
    case tipsOnly

    var id: String { rawValue }
    var localizationKey: String { "paytype.\(rawValue)" }
}

enum ShiftEntryMode: String, Codable, CaseIterable, Sendable {
    case times
    case hours
}

/// A user-defined income source (F001). Stored as raw strings for the enums,
/// the pattern already proven in this factory's SwiftData models, so the
/// store never depends on how well SwiftData externalises an arbitrary
/// Codable enum with an associated value.
@Model
final class Job {
    var id: UUID = UUID()
    var name: String = ""
    var payTypeRaw: String = PayType.hourlyPlusTips.rawValue
    var baseRate: Decimal = 0
    var employerName: String = ""
    var businessName: String = ""
    var occupationLabel: String = ""
    var currencyCode: String = "USD"
    var currencySymbol: String = "$"
    var payPeriodCycleRaw: String = "weekly"
    /// Used only when payPeriodCycleRaw == "weekly". 1 = Sunday ... 7 = Saturday.
    var periodStartWeekday: Int = 1
    /// Used only when payPeriodCycleRaw == "biweekly": the start of some past period.
    var periodAnchorDate: Date = Date.now
    var isSample: Bool = false
    var createdAt: Date = Date.now
    /// Updated whenever a shift is logged for this job, so the entry form can
    /// default the job picker to whichever job was used most recently.
    var lastUsedAt: Date?
    var lastEntryModeRaw: String = ShiftEntryMode.times.rawValue
    var lastTypicalHours: Decimal?

    @Relationship(deleteRule: .cascade, inverse: \Shift.job)
    var shifts: [Shift]? = []

    @Relationship(deleteRule: .cascade, inverse: \TipOutRecipientTemplate.job)
    var defaultRecipientTemplates: [TipOutRecipientTemplate]? = []

    init(name: String, payType: PayType = .hourlyPlusTips, baseRate: Decimal = 0,
         employerName: String = "", businessName: String = "", occupationLabel: String = "",
         currencyCode: String = "USD", currencySymbol: String = "$",
         payPeriodCycle: PayPeriodCycle = .weekly(startWeekday: 1),
         isSample: Bool = false, createdAt: Date = Date.now) {
        self.name = name
        self.payTypeRaw = payType.rawValue
        self.baseRate = baseRate
        self.employerName = employerName
        self.businessName = businessName
        self.occupationLabel = occupationLabel
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.isSample = isSample
        self.createdAt = createdAt
        setCycle(payPeriodCycle)
    }

    var payType: PayType {
        get { PayType(rawValue: payTypeRaw) ?? .hourlyPlusTips }
        set { payTypeRaw = newValue.rawValue }
    }

    var lastEntryMode: ShiftEntryMode {
        get { ShiftEntryMode(rawValue: lastEntryModeRaw) ?? .times }
        set { lastEntryModeRaw = newValue.rawValue }
    }

    var payPeriodCycle: PayPeriodCycle {
        get {
            switch payPeriodCycleRaw {
            case "weekly": return .weekly(startWeekday: periodStartWeekday)
            case "biweekly": return .biweekly(anchorDate: periodAnchorDate)
            case "semimonthly": return .semimonthly
            default: return .monthly
            }
        }
        set { setCycle(newValue) }
    }

    private func setCycle(_ cycle: PayPeriodCycle) {
        switch cycle {
        case .weekly(let weekday):
            payPeriodCycleRaw = "weekly"
            periodStartWeekday = weekday
        case .biweekly(let anchor):
            payPeriodCycleRaw = "biweekly"
            periodAnchorDate = anchor
        case .semimonthly:
            payPeriodCycleRaw = "semimonthly"
        case .monthly:
            payPeriodCycleRaw = "monthly"
        }
    }

    /// The job's default tip-out rule, as plain DTOs for the pure engine.
    var defaultTipOutRule: [TipOutRecipientRule] {
        get {
            (defaultRecipientTemplates ?? [])
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { TipOutRecipientRule(id: $0.id, name: $0.name, type: $0.type, value: $0.value) }
        }
        set {
            defaultRecipientTemplates?.removeAll()
            for (index, rule) in newValue.enumerated() {
                let template = TipOutRecipientTemplate(job: self, name: rule.name, type: rule.type,
                                                        value: rule.value, sortIndex: index)
                defaultRecipientTemplates?.append(template)
            }
        }
    }

    /// Non-sample shifts, for counting what a delete confirmation would remove.
    var nonSampleShiftCount: Int { (shifts ?? []).filter { !$0.isSample }.count }
}

/// One recipient in a Job's default tip-out rule (F001/F003). A real
/// SwiftData relationship rather than a stored Codable array, so persistence
/// stays on the pattern already proven elsewhere in this factory.
@Model
final class TipOutRecipientTemplate {
    var id: UUID = UUID()
    var job: Job?
    var name: String = ""
    var typeRaw: String = TipOutRuleType.percentOfTips.rawValue
    var value: Decimal = 0
    var sortIndex: Int = 0

    init(job: Job?, name: String, type: TipOutRuleType, value: Decimal, sortIndex: Int) {
        self.job = job
        self.name = name
        self.typeRaw = type.rawValue
        self.value = value
        self.sortIndex = sortIndex
    }

    var type: TipOutRuleType {
        get { TipOutRuleType(rawValue: typeRaw) ?? .percentOfTips }
        set { typeRaw = newValue.rawValue }
    }
}
