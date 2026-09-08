import Foundation

/// Whether the device favours metric or imperial units, used only to pick a
/// sensible default display unit; it never converts a recorded price.
enum MeasurementSystem: String, CaseIterable, Identifiable, Sendable {
    case metric
    case imperial
    var id: String { rawValue }

    static var systemDefault: MeasurementSystem {
        Locale.current.measurementSystem == .us ? .imperial : .metric
    }
}

/// User-facing settings, persisted in this app's own UserDefaults suite.
/// Nothing here ever leaves the device; it is the "what stays on this
/// iPhone" surface named in Settings.
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        currencyCode = defaults.string(forKey: Keys.currencyCode) ?? Self.defaultCurrencyCode
        currencySymbol = defaults.string(forKey: Keys.currencySymbol) ?? Self.defaultCurrencySymbol
        measurementSystemRaw = defaults.string(forKey: Keys.measurementSystem) ?? MeasurementSystem.systemDefault.rawValue
        includeSaleAndLoyaltyInTypical = defaults.object(forKey: Keys.includeSaleLoyalty) as? Bool ?? false
        hasCompletedFirstRun = defaults.bool(forKey: Keys.hasCompletedFirstRun)
        hasSavedFirstPriceEntry = defaults.bool(forKey: Keys.hasSavedFirstPriceEntry)
        hasRequestedTracking = defaults.bool(forKey: Keys.hasRequestedTracking)
    }

    var currencyCode: String { didSet { defaults.set(currencyCode, forKey: Keys.currencyCode) } }
    var currencySymbol: String { didSet { defaults.set(currencySymbol, forKey: Keys.currencySymbol) } }

    private var measurementSystemRaw: String {
        didSet { defaults.set(measurementSystemRaw, forKey: Keys.measurementSystem) }
    }
    var measurementSystem: MeasurementSystem {
        get { MeasurementSystem(rawValue: measurementSystemRaw) ?? .metric }
        set { measurementSystemRaw = newValue.rawValue }
    }

    /// Sale and loyalty-card prices are excluded from the "typical price"
    /// baseline by default; this toggles that.
    var includeSaleAndLoyaltyInTypical: Bool { didSet { defaults.set(includeSaleAndLoyaltyInTypical, forKey: Keys.includeSaleLoyalty) } }

    var hasCompletedFirstRun: Bool { didSet { defaults.set(hasCompletedFirstRun, forKey: Keys.hasCompletedFirstRun) } }

    /// ATT is requested once, right after the first price entry is ever
    /// saved -- never at launch, never during first run.
    var hasSavedFirstPriceEntry: Bool { didSet { defaults.set(hasSavedFirstPriceEntry, forKey: Keys.hasSavedFirstPriceEntry) } }
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
        static let currencyCode = "settings.currencyCode"
        static let currencySymbol = "settings.currencySymbol"
        static let measurementSystem = "settings.measurementSystem"
        static let includeSaleLoyalty = "settings.includeSaleLoyaltyInTypical"
        static let hasCompletedFirstRun = "settings.hasCompletedFirstRun"
        static let hasSavedFirstPriceEntry = "settings.hasSavedFirstPriceEntry"
        static let hasRequestedTracking = "settings.hasRequestedTracking"
    }
}
