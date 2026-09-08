import SwiftData
import SwiftUI

/// S001 Price Book -- the home tab.
struct PriceBookView: View {
    @Query(sort: \Item.name) private var items: [Item]
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory?
    @State private var sort: SortOption = .name
    // One sheet per view: both "add item" and "scan barcode" are driven from
    // this single Identifiable enum so the second one is never silently
    // ignored by SwiftUI.
    @State private var destination: Destination?

    enum SortOption: String, CaseIterable, Identifiable {
        case name, bestPrice, recentlyUpdated
        var id: String { rawValue }
    }

    private enum Destination: Identifiable {
        case addItem
        case scanner
        var id: String { switch self { case .addItem: "addItem"; case .scanner: "scanner" } }
    }

    private var filtered: [Item] {
        var result = items
        if let selectedCategory {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let needle = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(needle) || $0.brand.lowercased().contains(needle)
            }
        }
        switch sort {
        case .name:
            return result.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .bestPrice:
            return result.sorted { (bestPrice($0) ?? .greatestFiniteMagnitude) < (bestPrice($1) ?? .greatestFiniteMagnitude) }
        case .recentlyUpdated:
            return result.sorted { (lastUpdated($0) ?? .distantPast) > (lastUpdated($1) ?? .distantPast) }
        }
    }

    private func bestPrice(_ item: Item) -> Double? {
        // Only used to order rows; the value shown to the user always comes
        // from the Decimal-based normalisation engine.
        guard let entry = item.bestEntry else { return nil }
        return NSDecimalNumber(decimal: entry.displayUnitPrice).doubleValue
    }

    private func lastUpdated(_ item: Item) -> Date? {
        item.priceEntries.map(\.date).max()
    }

    var body: some View {
        NavigationStack {
            content
        }
        .pjBannerFooter()
    }

    @ViewBuilder
    private var content: some View {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    List {
                        categoryChips
                        ForEach(filtered) { item in
                            NavigationLink(value: item) {
                                ItemRow(item: item, currencySymbol: settings.currencySymbol)
                            }
                            .accessibilityIdentifier("priceBook.row.\(item.name)")
                        }
                        .onDelete(perform: delete)
                    }
                    .accessibilityIdentifier("priceBook.list")
                    .searchable(text: $searchText, prompt: Text("priceBook.search"))
                }
            }
            .navigationTitle("tab.priceBook")
            .navigationDestination(for: Item.self) { item in
                ItemHistoryView(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("priceBook.sort", selection: $sort) {
                            Text("priceBook.sort.name").tag(SortOption.name)
                            Text("priceBook.sort.bestPrice").tag(SortOption.bestPrice)
                            Text("priceBook.sort.recentlyUpdated").tag(SortOption.recentlyUpdated)
                        }
                    } label: {
                        Label("priceBook.sort", systemImage: "arrow.up.arrow.down")
                    }
                    .accessibilityIdentifier("priceBook.sort")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { destination = .scanner } label: {
                        Label("priceBook.scan", systemImage: "barcode.viewfinder")
                    }
                    .accessibilityIdentifier("priceBook.scan")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { destination = .addItem } label: {
                        Label("priceBook.add", systemImage: "plus")
                    }
                    .accessibilityIdentifier("priceBook.add")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        StoresView()
                    } label: {
                        Label("priceBook.manageStores", systemImage: "storefront")
                    }
                    .accessibilityIdentifier("priceBook.manageStores")
                }
            }
            .sheet(item: $destination) { destination in
                switch destination {
                case .addItem:
                    ItemEditView(item: nil)
                case .scanner:
                    BarcodeScannerView()
                }
            }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                CategoryChip(title: "priceBook.category.all", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                .accessibilityIdentifier("priceBook.category.all")
                ForEach(ItemCategory.allCases) { category in
                    CategoryChip(title: LocalizedStringKey(category.localizationKey), isSelected: selectedCategory == category) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                    .accessibilityIdentifier("priceBook.category.\(category.rawValue)")
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("priceBook.empty.title", systemImage: "book.closed",
                                   description: Text("priceBook.empty.body"))
            Button("priceBook.empty.loadSample") {
                SampleDataFactory.load(into: context)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("priceBook.empty.loadSample")
            Button("priceBook.add") { destination = .addItem }
                .accessibilityIdentifier("priceBook.empty.add")
        }
        .accessibilityIdentifier("priceBook.empty")
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(filtered[index]) }
    }
}

private struct CategoryChip: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ItemRow: View {
    let item: Item
    let currencySymbol: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name).font(.headline)
                    if item.isSample {
                        Text("common.sampleBadge")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Capsule())
                            .accessibilityIdentifier("badge.sample")
                    }
                }
                if !item.brand.isEmpty {
                    Text(item.brand).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let entry = item.bestEntry {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(PriceFormatting.string(entry.displayUnitPrice, symbol: currencySymbol, displayUnit: item.preferredDisplayUnit))
                        .font(.system(.body, design: .monospaced))
                    Text(entry.store?.name ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("priceBook.noPricesYet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
