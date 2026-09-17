import Foundation

enum MeasurementSystem: String, CaseIterable, Codable {
    case imperial, metric
}

/// The user's own defaults (F014), persisted in this app's own UserDefaults
/// suite. Two fields are deliberately excluded from any default anywhere in
/// this file, the string catalogue or the bundle: `maxRiserHeight` and
/// `minTreadDepth`. Every stair calculation must be built on a limit the user
/// typed in themselves, because a bundled limit would be a stale regulatory
/// value shipped inside an offline app -- worse than no value at all.
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var preferredSystem: MeasurementSystem {
        get { MeasurementSystem(rawValue: defaults.string(forKey: Keys.system) ?? "") ?? .imperial }
        set { defaults.set(newValue.rawValue, forKey: Keys.system) }
    }

    var fractionPrecision: FractionPrecision {
        get {
            let raw = defaults.integer(forKey: Keys.precision)
            return FractionPrecision(rawValue: raw) ?? .sixteenth
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.precision) }
    }

    var preferredMetricUnit: LengthUnit {
        get { LengthUnit(rawValue: defaults.string(forKey: Keys.metricUnit) ?? "") ?? .centimeter }
        set { defaults.set(newValue.rawValue, forKey: Keys.metricUnit) }
    }

    /// nil until the user sets it. No default: see the type's doc comment.
    var maxRiserHeight: Length? {
        get { rational(Keys.maxRiserN, Keys.maxRiserD).map(Length.init(inches:)) }
        set { setRational(newValue?.inches, Keys.maxRiserN, Keys.maxRiserD) }
    }

    /// nil until the user sets it. No default: see the type's doc comment.
    var minTreadDepth: Length? {
        get { rational(Keys.minTreadN, Keys.minTreadD).map(Length.init(inches:)) }
        set { setRational(newValue?.inches, Keys.minTreadN, Keys.minTreadD) }
    }

    /// An ordinary product default (16 in on centre), not a code value -- the
    /// user can change it in Settings and the framing solver never assumes it.
    var studSpacing: Length {
        get { rational(Keys.studSpacingN, Keys.studSpacingD).map(Length.init(inches:)) ?? Length(16, .inches) }
        set { setRational(newValue.inches, Keys.studSpacingN, Keys.studSpacingD) }
    }

    /// Standard 4x8 sheet, in feet -- a published dimension, editable.
    var sheetWidth: Length {
        get { rational(Keys.sheetWidthN, Keys.sheetWidthD).map(Length.init(inches:)) ?? Length(4, .feet) }
        set { setRational(newValue.inches, Keys.sheetWidthN, Keys.sheetWidthD) }
    }

    var sheetHeight: Length {
        get { rational(Keys.sheetHeightN, Keys.sheetHeightD).map(Length.init(inches:)) ?? Length(8, .feet) }
        set { setRational(newValue.inches, Keys.sheetHeightN, Keys.sheetHeightD) }
    }

    var tileWastePercent: Rational {
        get { rational(Keys.wasteN, Keys.wasteD) ?? Rational(10) }
        set { setRational(newValue, Keys.wasteN, Keys.wasteD) }
    }

    /// 0.60 cubic feet: the standard yield of an 80 lb bag (F014's reference
    /// section), editable, and the user can pick 40 or 60 lb yields instead.
    var concreteBagYieldCubicFeet: Rational {
        get { rational(Keys.bagYieldN, Keys.bagYieldD) ?? Rational(3, 5) }
        set { setRational(newValue, Keys.bagYieldN, Keys.bagYieldD) }
    }

    var firstRunCompleted: Bool {
        get { defaults.bool(forKey: Keys.firstRunCompleted) }
        set { defaults.set(newValue, forKey: Keys.firstRunCompleted) }
    }

    private func rational(_ numKey: String, _ denKey: String) -> Rational? {
        guard defaults.object(forKey: numKey) != nil, defaults.object(forKey: denKey) != nil else { return nil }
        let d = defaults.integer(forKey: denKey)
        guard d != 0 else { return nil }
        return Rational(defaults.integer(forKey: numKey), d)
    }

    private func setRational(_ value: Rational?, _ numKey: String, _ denKey: String) {
        guard let value else {
            defaults.removeObject(forKey: numKey)
            defaults.removeObject(forKey: denKey)
            return
        }
        defaults.set(value.numerator, forKey: numKey)
        defaults.set(value.denominator, forKey: denKey)
    }

    private enum Keys {
        static let system = "settings.system"
        static let precision = "settings.precision"
        static let metricUnit = "settings.metricUnit"
        static let maxRiserN = "settings.maxRiser.n"
        static let maxRiserD = "settings.maxRiser.d"
        static let minTreadN = "settings.minTread.n"
        static let minTreadD = "settings.minTread.d"
        static let studSpacingN = "settings.studSpacing.n"
        static let studSpacingD = "settings.studSpacing.d"
        static let sheetWidthN = "settings.sheetWidth.n"
        static let sheetWidthD = "settings.sheetWidth.d"
        static let sheetHeightN = "settings.sheetHeight.n"
        static let sheetHeightD = "settings.sheetHeight.d"
        static let wasteN = "settings.waste.n"
        static let wasteD = "settings.waste.d"
        static let bagYieldN = "settings.bagYield.n"
        static let bagYieldD = "settings.bagYield.d"
        static let firstRunCompleted = "settings.firstRunCompleted"
    }
}
