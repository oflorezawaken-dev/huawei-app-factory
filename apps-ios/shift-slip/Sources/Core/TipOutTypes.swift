import Foundation

/// The four ways a tip-out rule can be resolved (F003). Stored as a raw
/// String on Job/Shift-embedded structs so SwiftData can persist it directly.
enum TipOutRuleType: String, Codable, CaseIterable, Identifiable {
    case percentOfTips
    case percentOfSales
    case flat
    case manual

    var id: String { rawValue }
}

/// One recipient's rule, as configured on a Job's default tip-out rule.
struct TipOutRecipientRule: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var type: TipOutRuleType
    /// A percentage (0-100) for the percent types, a currency amount for flat
    /// and manual. Never a running remainder -- always applied against the
    /// shift's gross voluntary tips or sales, per F003.
    var value: Decimal
}

/// One recipient's resolved share on a specific shift: the rule that produced
/// it plus the already-rounded amount. Stored on the Shift itself so a saved
/// shift's tip-out never silently changes if the job's default rule changes later.
struct TipOutRecipientShare: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var type: TipOutRuleType
    var value: Decimal
    var resolvedAmount: Decimal
}

/// Pure arithmetic, Decimal throughout -- never Double or Float. Resolves a
/// job's tip-out rule against one shift's tips and sales.
enum TipOutEngine {
    /// Percentages apply to gross voluntary tips (cash + charge), never to a
    /// running remainder and never to service charges, per F003. Each
    /// recipient's raw share is rounded half-up to the currency's minor unit
    /// independently, so the displayed total is always the sum of the
    /// displayed shares -- never a total computed first and split after.
    static func resolve(
        recipients: [TipOutRecipientRule],
        voluntaryTips: Decimal,
        sales: Decimal,
        minorUnitScale: Int = 2
    ) -> [TipOutRecipientShare] {
        recipients.map { rule in
            let raw: Decimal
            switch rule.type {
            case .percentOfTips:
                raw = voluntaryTips * rule.value / 100
            case .percentOfSales:
                raw = sales * rule.value / 100
            case .flat, .manual:
                raw = rule.value
            }
            let rounded = raw.rounded(toScale: minorUnitScale)
            return TipOutRecipientShare(name: rule.name, type: rule.type, value: rule.value, resolvedAmount: rounded)
        }
    }

    /// The minor-unit decimal scale for a currency code. Not an exhaustive
    /// ISO 4217 table -- just the well-known zero- and three-decimal outliers
    /// a tipped worker might plausibly encounter; everything else is 2.
    static func minorUnitScale(forCurrencyCode code: String) -> Int {
        switch code.uppercased() {
        case "JPY", "KRW", "VND", "CLP", "ISK", "HUF": return 0
        case "BHD", "KWD", "OMR", "JOD", "TND": return 3
        default: return 2
        }
    }
}
