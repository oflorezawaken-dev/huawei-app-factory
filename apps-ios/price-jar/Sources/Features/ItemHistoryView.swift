import Charts
import SwiftData
import SwiftUI

/// S002 Item History -- everything known about one item's prices, and the
/// trend chart.
struct ItemHistoryView: View {
    @Bindable var item: Item

    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @State private var showEdit = false
    @State private var showRecordPrice = false
    @State private var entryPendingDeletion: PriceEntry?

    private var entries: [PriceEntry] { item.recordedEntries }

    private var bestEntry: PriceEntry? {
        entries.min { $0.unitPrice < $1.unitPrice }
    }

    private var medianDisplayPrice: Decimal? {
        VerdictEngine.median(of: entries.map(\.unitPrice)).map {
            UnitNormalization.displayUnitPrice(baseUnitPrice: $0, displayUnit: item.preferredDisplayUnit)
        }
    }

    private var sixMonthsAgoChange: (percent: Decimal, current: Decimal)? {
        guard let now = entries.map(\.date).max(),
              let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) else { return nil }
        let older = entries.filter { $0.date <= sixMonthsAgo }
        guard let oldest = older.max(by: { $0.date < $1.date }),
              let newest = entries.max(by: { $0.date < $1.date }),
              oldest.unitPrice != 0 else { return nil }
        let percent = UnitNormalization.rounded(((newest.unitPrice - oldest.unitPrice) / oldest.unitPrice) * 100, scale: 1)
        return (percent, newest.displayUnitPrice)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                List {
                    header
                    summary
                    chart
                    Section("history.entries") {
                        ForEach(entries) { entry in
                            EntryRow(entry: entry, currencySymbol: settings.currencySymbol)
                                .accessibilityIdentifier("history.entry.\(entry.persistentModelID.hashValue)")
                                .swipeActions {
                                    Button("edit.delete", role: .destructive) { entryPendingDeletion = entry }
                                }
                        }
                    }
                }
                .accessibilityIdentifier("history.list")
            }
        }
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("history.edit") { showEdit = true }
                    .accessibilityIdentifier("history.editItem")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("history.recordPrice", systemImage: "plus") { showRecordPrice = true }
                    .accessibilityIdentifier("history.recordPrice")
            }
        }
        .sheet(isPresented: $showEdit) { ItemEditView(item: item) }
        .sheet(isPresented: $showRecordPrice) { RecordPriceView(item: item) }
        .alert("history.deleteEntry.title", isPresented: Binding(
            get: { entryPendingDeletion != nil }, set: { if !$0 { entryPendingDeletion = nil } }
        )) {
            Button("edit.delete", role: .destructive) {
                if let entry = entryPendingDeletion { context.delete(entry) }
                entryPendingDeletion = nil
            }
            Button("edit.cancel", role: .cancel) { entryPendingDeletion = nil }
        }
        .pjBannerFooter()
    }

    @ViewBuilder
    private var header: some View {
        Section {
            HStack(spacing: 12) {
                if let data = item.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                        .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: item.category.systemImage)
                        .frame(width: 56, height: 56)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading) {
                    if !item.brand.isEmpty { Text(item.brand).foregroundStyle(.secondary) }
                    Text(LocalizedStringKey(item.category.localizationKey)).font(.caption).foregroundStyle(.secondary)
                    Text(LocalizedStringKey(item.preferredDisplayUnit.localizationKey)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("history.header")
    }

    @ViewBuilder
    private var summary: some View {
        Section("history.summary") {
            if let bestEntry {
                LabeledContent("history.best") {
                    Text(PriceFormatting.string(bestEntry.displayUnitPrice, symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit) + " " + (bestEntry.store?.name ?? ""))
                }
                .accessibilityIdentifier("history.best")
            }
            if let medianDisplayPrice {
                LabeledContent("history.median") {
                    Text(PriceFormatting.string(medianDisplayPrice, symbol: settings.currencySymbol, displayUnit: item.preferredDisplayUnit))
                }
                .accessibilityIdentifier("history.median")
            }
            if let change = sixMonthsAgoChange {
                LabeledContent("history.sixMonthChange") {
                    Text(PriceFormatting.percent(change.percent))
                        .foregroundStyle(change.percent > 0 ? .red : .green)
                }
                .accessibilityIdentifier("history.sixMonthChange")
            }
        }
    }

    @ViewBuilder
    private var chart: some View {
        if entries.count > 1 {
            Section("history.chart") {
                Chart(entries.sorted { $0.date < $1.date }) { entry in
                    LineMark(x: .value("history.chart.date", entry.date),
                             y: .value("history.chart.price", NSDecimalNumber(decimal: entry.displayUnitPrice).doubleValue))
                    PointMark(x: .value("history.chart.date", entry.date),
                              y: .value("history.chart.price", NSDecimalNumber(decimal: entry.displayUnitPrice).doubleValue))
                }
                .frame(height: 160)
                .accessibilityIdentifier("history.chart")
                .accessibilityLabel(Text("history.chart.accessibilityLabel"))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("history.empty.title", systemImage: "chart.line.uptrend.xyaxis",
                                   description: Text("history.empty.body"))
            Button("history.recordPrice") { showRecordPrice = true }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("history.empty.recordPrice")
        }
        .accessibilityIdentifier("history.empty")
    }
}

private struct EntryRow: View {
    let entry: PriceEntry
    let currencySymbol: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.store?.name ?? "")
                Text(entry.date, style: .date).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    if entry.isSale {
                        Text("badge.sale").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2)).clipShape(Capsule())
                            .accessibilityIdentifier("badge.sale")
                    }
                    if entry.isLoyalty {
                        Text("badge.loyalty").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2)).clipShape(Capsule())
                            .accessibilityIdentifier("badge.loyalty")
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(PriceFormatting.currencyAmount(entry.price, symbol: currencySymbol))
                    .font(.system(.body, design: .monospaced))
                Text(PriceFormatting.string(entry.displayUnitPrice, symbol: currencySymbol, displayUnit: entry.item?.preferredDisplayUnit ?? .perItem))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
