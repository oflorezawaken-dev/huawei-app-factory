import Foundation
import SwiftData

@Model
final class Trip {
    var store: Store?
    var date: Date
    /// The sum of what was actually ticked off and priced; nil fields on
    /// unticked entries do not contribute.
    var total: Decimal
    /// What the shopping list estimated before the trip started, for the
    /// "estimate vs actual" card on the summary.
    var estimatedTotal: Decimal
    var isSample: Bool
    var createdAt: Date
    /// Set once the trip is saved (End Trip tapped); an in-progress trip is
    /// still just a Trip row so Trip Mode can be resumed, but ads and the
    /// interstitial only ever look at saved trips.
    var isSaved: Bool

    @Relationship(deleteRule: .cascade, inverse: \TripEntry.trip)
    var entries: [TripEntry] = []

    init(store: Store?, date: Date = .now, total: Decimal = 0, estimatedTotal: Decimal = 0,
         isSample: Bool = false, isSaved: Bool = false, createdAt: Date = .now) {
        self.store = store
        self.date = date
        self.total = total
        self.estimatedTotal = estimatedTotal
        self.isSample = isSample
        self.isSaved = isSaved
        self.createdAt = createdAt
    }

    var itemCount: Int { entries.filter(\.isTicked).count }
    var newBestCount: Int { entries.filter(\.isNewBest).count }
}

@Model
final class TripEntry {
    var trip: Trip?
    var item: Item?
    /// True for rows copied in from the shopping list; false for "add an
    /// unplanned item" rows created inside Trip Mode itself.
    var wasPlanned: Bool
    var quantity: Decimal
    var isTicked: Bool
    var pricePaid: Decimal?
    var packageSizeAtPurchase: Decimal
    var unitRaw: String
    /// Computed and stored at the moment the entry is ticked, so the trip
    /// summary's "new best prices found on this trip" never has to
    /// recompute history after other entries have already been saved.
    var isNewBest: Bool
    var createdAt: Date

    init(trip: Trip?, item: Item?, wasPlanned: Bool, quantity: Decimal = 1,
         packageSizeAtPurchase: Decimal, unit: MeasurementUnit,
         isTicked: Bool = false, pricePaid: Decimal? = nil, isNewBest: Bool = false,
         createdAt: Date = .now) {
        self.trip = trip
        self.item = item
        self.wasPlanned = wasPlanned
        self.quantity = quantity
        self.packageSizeAtPurchase = packageSizeAtPurchase
        self.unitRaw = unit.rawValue
        self.isTicked = isTicked
        self.pricePaid = pricePaid
        self.isNewBest = isNewBest
        self.createdAt = createdAt
    }

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .item }
        set { unitRaw = newValue.rawValue }
    }

    var unitPrice: Decimal? {
        guard let pricePaid else { return nil }
        return try? UnitNormalization.unitPrice(price: pricePaid, packageSize: packageSizeAtPurchase, unit: unit)
    }
}
