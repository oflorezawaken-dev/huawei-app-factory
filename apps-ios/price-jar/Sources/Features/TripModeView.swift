import SwiftData
import SwiftUI

/// S008 Trip Mode -- shop one-handed and record what you actually paid as
/// you go. All advertising is suppressed for the whole duration of a trip.
struct TripModeView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Query private var allItems: [Item]

    @State private var pricingEntry: TripEntry?
    @State private var priceText = ""
    @State private var showAddUnplanned = false
    @State private var unplannedSearch = ""
    @State private var showEndTripSummary = false

    private var entries: [TripEntry] { trip.entries.sorted { $0.createdAt < $1.createdAt } }

    private var runningTotal: Decimal {
        entries.compactMap { $0.pricePaid }.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                List {
                    ForEach(entries) { entry in
                        tripRow(entry)
                            .accessibilityIdentifier("trip.row.\(entry.item?.name ?? "")")
                    }
                }
                .accessibilityIdentifier("trip.list")
            }
            .navigationTitle(trip.store?.name ?? "")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("trip.addUnplanned") { showAddUnplanned = true }
                        .accessibilityIdentifier("trip.addUnplanned")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("trip.end", action: endTrip)
                        .accessibilityIdentifier("trip.end")
                }
            }
            .sheet(item: $pricingEntry) { entry in
                priceSheet(for: entry)
            }
            .sheet(isPresented: $showAddUnplanned) { addUnplannedSheet }
            .fullScreenCover(isPresented: $showEndTripSummary, onDismiss: { dismiss() }) {
                TripSummaryView(trip: trip)
            }
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("trip.runningTotal \(PriceFormatting.currencyAmount(runningTotal, symbol: settings.currencySymbol))")
                .font(.title2.bold())
                .accessibilityIdentifier("trip.runningTotal")
            Text("trip.estimateComparison \(PriceFormatting.currencyAmount(trip.estimatedTotal, symbol: settings.currencySymbol))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("trip.estimateComparison")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
    }

    private func tripRow(_ entry: TripEntry) -> some View {
        Button {
            pricingEntry = entry
            priceText = entry.pricePaid.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        } label: {
            HStack {
                Image(systemName: entry.isTicked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(entry.isTicked ? .green : .secondary)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(entry.item?.name ?? "")
                        .font(.title3)
                    if entry.isNewBest {
                        Text("trip.newBest").font(.caption).foregroundStyle(.green)
                    }
                }
                Spacer()
                if let pricePaid = entry.pricePaid {
                    Text(PriceFormatting.currencyAmount(pricePaid, symbol: settings.currencySymbol))
                        .font(.system(.title3, design: .monospaced))
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func priceSheet(for entry: TripEntry) -> some View {
        NavigationStack {
            Form {
                TextField("record.price", text: $priceText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("trip.priceField")
            }
            .navigationTitle(entry.item?.name ?? "")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { pricingEntry = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("record.save") { confirmPrice(for: entry) }
                        .disabled(DecimalParsing.parse(priceText) == nil)
                        .accessibilityIdentifier("trip.priceConfirm")
                }
            }
        }
    }

    private var addUnplannedSheet: some View {
        NavigationStack {
            List(unplannedCandidates) { item in
                Button(item.name) {
                    let entry = TripEntry(trip: trip, item: item, wasPlanned: false, quantity: 1,
                                           packageSizeAtPurchase: item.defaultPackageSize, unit: item.defaultUnit)
                    trip.entries.append(entry)
                    showAddUnplanned = false
                }
                .accessibilityIdentifier("trip.addUnplanned.row.\(item.name)")
            }
            .searchable(text: $unplannedSearch)
            .navigationTitle("trip.addUnplanned")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { showAddUnplanned = false }
                }
            }
        }
    }

    private var unplannedCandidates: [Item] {
        let existingIDs = Set(trip.entries.compactMap(\.item?.persistentModelID))
        let candidates = allItems.filter { !existingIDs.contains($0.persistentModelID) }
        guard !unplannedSearch.trimmingCharacters(in: .whitespaces).isEmpty else { return candidates }
        let needle = unplannedSearch.lowercased()
        return candidates.filter { $0.name.lowercased().contains(needle) }
    }

    private func confirmPrice(for entry: TripEntry) {
        guard let price = DecimalParsing.parse(priceText) else { return }
        let previousBest = entry.item?.bestEntry?.unitPrice
        entry.pricePaid = price
        entry.isTicked = true
        if let unitPrice = entry.unitPrice, let previousBest {
            entry.isNewBest = unitPrice < previousBest
        } else {
            entry.isNewBest = entry.unitPrice != nil
        }

        if let item = entry.item {
            let priceEntry = PriceEntry(item: item, store: trip.store, price: price,
                                         packageSize: entry.packageSizeAtPurchase, unit: entry.unit, date: trip.date)
            context.insert(priceEntry)
        }
        pricingEntry = nil
    }

    private func endTrip() {
        trip.total = runningTotal
        trip.isSaved = true
        showEndTripSummary = true
    }
}
