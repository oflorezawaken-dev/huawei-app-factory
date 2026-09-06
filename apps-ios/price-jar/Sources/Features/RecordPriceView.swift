import SwiftData
import SwiftUI

/// S003 Record Price -- the ten-second entry form. No advertising of any kind.
/// Saving here does not write to SwiftData directly: it computes the verdict
/// against existing history and hands off to `VerdictView`, whose own "Save
/// this price" button is what actually inserts the entry (F005).
struct RecordPriceView: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Query private var stores: [Store]
    @FocusState private var priceFieldFocused: Bool

    @State private var priceText = ""
    @State private var selectedStore: Store?
    @State private var packageSizeText: String
    @State private var unit: MeasurementUnit
    @State private var date = Date.now
    @State private var isSale = false
    @State private var isLoyalty = false
    @State private var dimensionError = false
    @State private var pendingVerdict: PendingVerdict?

    init(item: Item) {
        self.item = item
        _packageSizeText = State(initialValue: NSDecimalNumber(decimal: item.defaultPackageSize).stringValue)
        _unit = State(initialValue: item.defaultUnit)
    }

    struct PendingVerdict: Identifiable {
        let id = UUID()
        let price: Decimal
        let packageSize: Decimal
        let unit: MeasurementUnit
        let store: Store?
        let date: Date
        let isSale: Bool
        let isLoyalty: Bool
    }

    private var price: Decimal? { DecimalParsing.parse(priceText).flatMap { $0 > 0 ? $0 : nil } }
    private var packageSize: Decimal? { DecimalParsing.parse(packageSizeText).flatMap { $0 > 0 ? $0 : nil } }

    private var liveUnitPrice: Decimal? {
        guard let price, let packageSize, unit.dimension == item.dimension else { return nil }
        return try? UnitNormalization.displayUnitPrice(price: price, packageSize: packageSize, unit: unit,
                                                        displayUnit: item.preferredDisplayUnit)
    }

    private var isValid: Bool { price != nil && packageSize != nil && unit.dimension == item.dimension }

    var body: some View {
        NavigationStack {
            Form {
                Section("record.price") {
                    TextField("record.price", text: $priceText)
                        .keyboardType(.decimalPad)
                        .focused($priceFieldFocused)
                        .accessibilityIdentifier("record.price")
                    if let liveUnitPrice {
                        Text(PriceFormatting.string(liveUnitPrice, symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("record.liveUnitPrice")
                    }
                }

                Section("record.details") {
                    Picker("record.store", selection: $selectedStore) {
                        Text("record.noStore").tag(Store?.none)
                        ForEach(stores) { store in Text(store.name).tag(Store?.some(store)) }
                    }
                    .accessibilityIdentifier("record.store")

                    HStack {
                        Text("record.packageSize")
                        TextField("record.packageSize", text: $packageSizeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("record.packageSize")
                    }
                    Picker("record.unit", selection: $unit) {
                        ForEach(MeasurementUnit.units(for: item.dimension)) { unitCase in
                            Text(LocalizedStringKey(unitCase.localizationKey)).tag(unitCase)
                        }
                    }
                    .accessibilityIdentifier("record.unit")

                    DatePicker("record.date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("record.date")
                    Toggle("record.sale", isOn: $isSale)
                        .accessibilityIdentifier("record.sale")
                    Toggle("record.loyalty", isOn: $isLoyalty)
                        .accessibilityIdentifier("record.loyalty")
                }

                if dimensionError {
                    Section {
                        Text("record.dimensionMismatch \(item.dimension.rawValue)")
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("record.dimensionMismatch")
                    }
                }
            }
            .navigationTitle("record.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                        .accessibilityIdentifier("record.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("record.save", action: checkPrice)
                        .disabled(price == nil || packageSize == nil)
                        .accessibilityIdentifier("record.save")
                }
            }
            .onAppear {
                if selectedStore == nil { selectedStore = item.recordedEntries.first?.store }
                priceFieldFocused = true
            }
            .sheet(item: $pendingVerdict) { pending in
                VerdictView(item: item, pending: pending, onSaved: { dismiss() })
            }
        }
    }

    private func checkPrice() {
        guard let price, let packageSize else { return }
        guard (try? UnitNormalization.validateDimension(entryUnit: unit, itemDimension: item.dimension)) != nil else {
            dimensionError = true
            return
        }
        dimensionError = false
        pendingVerdict = PendingVerdict(price: price, packageSize: packageSize, unit: unit,
                                         store: selectedStore, date: date, isSale: isSale, isLoyalty: isLoyalty)
    }
}
