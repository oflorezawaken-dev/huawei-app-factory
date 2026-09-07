import SwiftData
import SwiftUI

struct ItemListView: View {
    @Query(sort: \Item.createdAt) private var items: [Item]
    @Environment(\.modelContext) private var context
    // One sheet, not two: SwiftUI honours a single .sheet per view, so having
    // both .sheet(isPresented:) and .sheet(item:) silently disables one.
    @State private var target: EditTarget?

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView("all.empty.title", systemImage: "plus.circle",
                                           description: Text("all.empty.body"))
                        .accessibilityIdentifier("all.empty")
                } else {
                    List {
                        ForEach(items) { item in
                            Button { target = .existing(item) } label: { ItemRow(item: item) }
                                .accessibilityIdentifier("all.row.\(item.title)")
                        }
                        .onDelete { offsets in
                            for index in offsets { context.delete(items[index]) }
                        }
                    }
                    .accessibilityIdentifier("all.list")
                }
            }
            .navigationTitle("tab.all")
            .toolbar {
                Button { target = .new } label: { Label("all.add", systemImage: "plus") }
                    .accessibilityIdentifier("all.add")
            }
            .sheet(item: $target) { target in
                ItemEditView(item: target.item)
            }
        }
    }
}

private enum EditTarget: Identifiable {
    case new
    case existing(Item)

    var id: String {
        switch self {
        case .new: return "new"
        case .existing(let item): return item.persistentModelID.storeIdentifier ?? item.title
        }
    }

    var item: Item? {
        switch self {
        case .new: return nil
        case .existing(let item): return item
        }
    }
}
