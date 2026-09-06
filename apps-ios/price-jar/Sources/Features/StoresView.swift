import SwiftData
import SwiftUI

/// S006 Stores -- the user's own list of stores. No cap, no map, no chain
/// database.
struct StoresView: View {
    @Query(sort: \Store.name) private var stores: [Store]
    @Environment(\.modelContext) private var context

    @State private var destination: Destination?
    @State private var storePendingDeletion: Store?

    private enum Destination: Identifiable {
        case add
        case edit(Store)
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let store): return store.persistentModelID.hashValue.description
            }
        }
    }

    var body: some View {
        Group {
            if stores.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(stores) { store in
                        Button {
                            destination = .edit(store)
                        } label: {
                            row(for: store)
                        }
                        .accessibilityIdentifier("stores.row.\(store.name)")
                        .swipeActions {
                            Button("edit.delete", role: .destructive) { storePendingDeletion = store }
                        }
                    }
                }
                .accessibilityIdentifier("stores.list")
            }
        }
        .navigationTitle("tab.stores")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("stores.add", systemImage: "plus") { destination = .add }
                    .accessibilityIdentifier("stores.add")
            }
        }
        .sheet(item: $destination) { destination in
            switch destination {
            case .add: StoreEditView(store: nil)
            case .edit(let store): StoreEditView(store: store)
            }
        }
        .confirmationDialog(
            Text("stores.deleteConfirm.title \(storePendingDeletion?.priceEntries.count ?? 0)"),
            isPresented: Binding(get: { storePendingDeletion != nil }, set: { if !$0 { storePendingDeletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("stores.deleteConfirm.deleteEntries", role: .destructive) {
                if let store = storePendingDeletion {
                    for entry in store.priceEntries { context.delete(entry) }
                    context.delete(store)
                }
                storePendingDeletion = nil
            }
            Button("stores.deleteConfirm.reassign") {
                if let store = storePendingDeletion {
                    for entry in store.priceEntries { entry.store = nil }
                    context.delete(store)
                }
                storePendingDeletion = nil
            }
            Button("edit.cancel", role: .cancel) { storePendingDeletion = nil }
        }
        .pjBannerFooter()
    }

    private func row(for store: Store) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(store.name).foregroundStyle(.primary)
                if !store.note.isEmpty {
                    Text(store.note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("stores.entryCount \(store.recordedEntryCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("stores.empty.title", systemImage: "storefront",
                                   description: Text("stores.empty.body"))
            Button("stores.add") { destination = .add }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("stores.empty.add")
        }
        .accessibilityIdentifier("stores.empty")
    }
}

private struct StoreEditView: View {
    let store: Store?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("stores.name", text: $name)
                    .accessibilityIdentifier("stores.edit.name")
                TextField("stores.note", text: $note, axis: .vertical)
                    .accessibilityIdentifier("stores.edit.note")
            }
            .navigationTitle(store == nil ? "stores.new" : "stores.editTitle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                        .accessibilityIdentifier("stores.edit.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("edit.save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("stores.edit.save")
                }
            }
            .onAppear {
                name = store?.name ?? ""
                note = store?.note ?? ""
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let store {
            store.name = trimmedName
            store.note = note
        } else {
            context.insert(Store(name: trimmedName, note: note))
        }
        dismiss()
    }
}
