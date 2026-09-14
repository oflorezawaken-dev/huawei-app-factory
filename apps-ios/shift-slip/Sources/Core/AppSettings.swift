import Foundation

/// The user's own defaults and small pieces of lifetime state (F014),
/// persisted in this app's own UserDefaults suite. Nothing here ever leaves
/// the device; it is the "what stays on this iPhone" surface named in Settings.
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        employeeName = defaults.string(forKey: Keys.employeeName) ?? ""
        currencyCode = defaults.string(forKey: Keys.currencyCode) ?? Self.defaultCurrencyCode
        currencySymbol = defaults.string(forKey: Keys.currencySymbol) ?? Self.defaultCurrencySymbol
        minimumWageText = defaults.string(forKey: Keys.minimumWageText) ?? ""
        firstDayOfWeek = {
            let stored = defaults.integer(forKey: Keys.firstDayOfWeek)
            return stored == 0 ? Calendar.current.firstWeekday : stored
        }()
        defaultEntryModeRaw = defaults.string(forKey: Keys.defaultEntryMode) ?? ShiftEntryMode.times.rawValue
        monthlyExportReminderEnabled = defaults.object(forKey: Keys.monthlyExportReminder) as? Bool ?? true
        hasCompletedFirstRun = defaults.bool(forKey: Keys.hasCompletedFirstRun)
        savedShiftCount = defaults.integer(forKey: Keys.savedShiftCount)
        hasSavedFirstShift = defaults.bool(forKey: Keys.hasSavedFirstShift)
        hasRequestedTracking = defaults.bool(forKey: Keys.hasRequestedTracking)
    }

    var employeeName: String { didSet { defaults.set(employeeName, forKey: Keys.employeeName) } }
    var currencyCode: String { didSet { defaults.set(currencyCode, forKey: Keys.currencyCode) } }
    var currencySymbol: String { didSet { defaults.set(currencySymbol, forKey: Keys.currencySymbol) } }

    /// Stored as text (not Decimal) so the field can represent "blank" while
    /// being edited -- F008 stays invisible until this is entered.
    private var minimumWageText: String { didSet { defaults.set(minimumWageText, forKey: Keys.minimumWageText) } }
    var minimumWage: Decimal? {
        get { DecimalParsing.parse(minimumWageText) }
        set { minimumWageText = newValue.map(\.fixedPointString) ?? "" }
    }

    /// 1 = Sunday ... 7 = Saturday.
    var firstDayOfWeek: Int { didSet { defaults.set(firstDayOfWeek, forKey: Keys.firstDayOfWeek) } }

    private var defaultEntryModeRaw: String { didSet { defaults.set(defaultEntryModeRaw, forKey: Keys.defaultEntryMode) } }
    var defaultEntryMode: ShiftEntryMode {
        get { ShiftEntryMode(rawValue: defaultEntryModeRaw) ?? .times }
        set { defaultEntryModeRaw = newValue.rawValue }
    }

    var monthlyExportReminderEnabled: Bool { didSet { defaults.set(monthlyExportReminderEnabled, forKey: Keys.monthlyExportReminder) } }
    var hasCompletedFirstRun: Bool { didSet { defaults.set(hasCompletedFirstRun, forKey: Keys.hasCompletedFirstRun) } }

    /// Lifetime count of saved shifts -- gates the interstitial (F013),
    /// never reset by deleting a shift.
    var savedShiftCount: Int { didSet { defaults.set(savedShiftCount, forKey: Keys.savedShiftCount) } }
    func recordShiftSaved() { savedShiftCount += 1 }

    /// ATT is requested once, right after the first shift is ever saved --
    /// never at launch, never during first run.
    var hasSavedFirstShift: Bool { didSet { defaults.set(hasSavedFirstShift, forKey: Keys.hasSavedFirstShift) } }
    var hasRequestedTracking: Bool { didSet { defaults.set(hasRequestedTracking, forKey: Keys.hasRequestedTracking) } }

    static var defaultCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    static var defaultCurrencySymbol: String {
        let code = defaultCurrencyCode
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? "$"
    }

    private enum Keys {
        static let employeeName = "settings.employeeName"
        static let currencyCode = "settings.currencyCode"
        static let currencySymbol = "settings.currencySymbol"
        static let minimumWageText = "settings.minimumWageText"
        static let firstDayOfWeek = "settings.firstDayOfWeek"
        static let defaultEntryMode = "settings.defaultEntryMode"
        static let monthlyExportReminder = "settings.monthlyExportReminder"
        static let hasCompletedFirstRun = "settings.hasCompletedFirstRun"
        static let savedShiftCount = "settings.savedShiftCount"
        static let hasSavedFirstShift = "settings.hasSavedFirstShift"
        static let hasRequestedTracking = "settings.hasRequestedTracking"
    }
}
