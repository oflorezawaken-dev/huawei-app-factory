import SwiftData
import SwiftUI

/// S007 Shopping List -- plan a basket, see its estimated cost, and which
/// store is cheapest for it.
struct ShoppingListView: View {
    @Query private var lists: [ShoppingList]
    @Query(sort: \Store.name) private var stores: [Store]
    @Query private var allItems: [Item]
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @State private var destination: Destination?
    @State private var freeTextEntry = ""
    @State private var storeForTrip: Store?
    @State private var activeTrip: Trip?

    private enum Destination: Identifiable {
        case addFromBook
        var id: String { "addFromBook" }
    }

    private var list: ShoppingList {
        if let existing = lists.first { return existing }
        let created = ShoppingList()
        context.insert(created)
        return created
    }

    private var entries: [ShoppingListEntry] { list.entries.sorted { $0.createdAt < $1.createdAt } }

    private func estimate(at store: Store) -> BasketEstimator.Result {
        let lines = entries.map { entry -> BasketLine in
            let bestAtStore = entry.item?.priceEntries
                .filter { $0.store === store }
                .map(\.unitPrice)
                .min()
            return BasketLine(quantity: entry.quantity,
                               defaultPackageSize: entry.item?.defaultPackageSize ?? 1,
                               defaultUnit: entry.item?.defaultUnit ?? .item,
                               bestUnitPriceAtStore: bestAtStore)
        }
        return BasketEstimator.estimate(lines: lines)
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("shoppingList.items") {
                            ForEach(entries) { entry in
                                HStack {
                                    Text(entry.displayName)
                                    Spacer()
                                    Stepper(value: quantityBinding(for: entry), in: 1...99) {
                                        Text("\(NSDecimalNumber(decimal: entry.quantity).intValue)")
                                    }
                                    .fixedSize()
                                }
                                .accessibilityIdentifier("shoppingList.row.\(entry.displayName)")
                            }
                            .onDelete(perform: deleteEntries)

                            HStack {
                                TextField("shoppingList.addFreeText", text: $freeTextEntry)
                                    .accessibilityIdentifier("shoppingList.freeTextField")
                                Button("shoppingList.addFreeText.button") { addFreeText() }
                                    .disabled(freeTextEntry.trimmingCharacters(in: .whitespaces).isEmpty)
                                    .accessibilityIdentifier("shoppingList.addFreeText.button")
                            }
                        }

                        Section("shoppingList.comparison") {
                            ForEach(stores) { store in
                                comparisonRow(for: store)
                            }
                            if stores.isEmpty {
                                Text("shoppingList.noStores").foregroundStyle(.secondary)
                            }
                        }

                        Section {
                            Picker("shoppingList.startTrip.store", selection: $storeForTrip) {
                                Text("record.noStore").tag(Store?.none)
                                ForEach(stores) { store in Text(store.name).tag(Store?.some(store)) }
                            }
                            .accessibilityIdentifier("shoppingList.startTrip.store")
                            Button("shoppingList.startTrip", action: startTrip)
                                .disabled(storeForTrip == nil)
                                .accessibilityIdentifier("shoppingList.startTrip")
                        }
                    }
                    .accessibilityIdentifier("shoppingList.list")
                }
            }
            .navigationTitle("tab.shoppingList")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("shoppingList.addFromBook", systemImage: "plus") { destination = .addFromBook }
                        .accessibilityIdentifier("shoppingList.addFromBook")
                }
            }
            .sheet(item: $destination) { _ in addFromBookSheet }
            .fullScreenCover(item: $activeTrip) { trip in
                TripModeView(trip: trip)
            }
        }
    }

    private func comparisonRow(for store: Store) -> some View {
        let result = estimate(at: store)
        return HStack {
            Text(store.name)
            Spacer()
            VStack(alignment: .trailing) {
                Text(PriceFormatting.currencyAmount(result.estimatedTotal, symbol: settings.currencySymbol))
                    .font(.system(.body, design: .monospaced))
                Text("shoppingList.coverage \(result.pricedCount) \(result.totalCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("shoppingList.comparison.\(store.name)")
    }

    private var addFromBookSheet: some View {
        NavigationStack {
            List(allItems) { item in
                Button(item.name) {
                    context.insert(ShoppingListEntry(list: list, item: item))
                    destination = nil
                }
                .accessibilityIdentifier("shoppingList.addFromBook.row.\(item.name)")
            }
            .navigationTitle("shoppingList.addFromBook")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { destination = nil }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("shoppingList.empty.title", systemImage: "cart",
                                   description: Text("shoppingList.empty.body"))
            Button("shoppingList.addFromBook") { destination = .addFromBook }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("shoppingList.empty.add")
        }
        .accessibilityIdentifier("shoppingList.empty")
    }

    private func quantityBinding(for entry: ShoppingListEntry) -> Binding<Int> {
        Binding(
            get: { NSDecimalNumber(decimal: entry.quantity).intValue },
            set: { entry.quantity = Decimal($0) }
        )
    }

    private func addFreeText() {
        let trimmed = freeTextEntry.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        context.insert(ShoppingListEntry(list: list, item: nil, freeTextName: trimmed))
        freeTextEntry = ""
    }

    private func deleteEntries(_ offsets: IndexSet) {
        for index in offsets { context.delete(entries[index]) }
    }

    private func startTrip() {
        guard let storeForTrip else { return }
        let result = estimate(at: storeForTrip)
        let trip = Trip(store: storeForTrip, estimatedTotal: result.estimatedTotal)
        for entry in entries {
            trip.entries.append(TripEntry(trip: trip, item: entry.item, wasPlanned: true,
                                           quantity: entry.quantity,
                                           packageSizeAtPurchase: entry.item?.defaultPackageSize ?? 1,
                                           unit: entry.item?.defaultUnit ?? .item))
        }
        context.insert(trip)
        activeTrip = trip
    }
}
