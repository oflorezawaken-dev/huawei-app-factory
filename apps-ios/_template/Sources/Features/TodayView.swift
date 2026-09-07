import SwiftData
import SwiftUI

struct TodayView: View {
    @Query(sort: \Item.createdAt) private var items: [Item]
    @Environment(\.modelContext) private var context

    private var due: [Item] { items.filter { $0.isDue() } }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView("today.empty.title", systemImage: "tray",
                                           description: Text("today.empty.body"))
                        .accessibilityIdentifier("today.empty")
                } else if due.isEmpty {
                    ContentUnavailableView("today.done.title", systemImage: "checkmark.circle",
                                           description: Text("today.done.body"))
                        .accessibilityIdentifier("today.done")
                } else {
                    List(due) { item in
                        Button {
                            item.lastDone = .now
                        } label: {
                            ItemRow(item: item)
                        }
                        .accessibilityIdentifier("today.row.\(item.title)")
                    }
                    .accessibilityIdentifier("today.list")
                }
            }
            .navigationTitle("tab.today")
        }
    }
}

struct ItemRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title).font(.headline)
            if !item.detail.isEmpty {
                Text(item.detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
