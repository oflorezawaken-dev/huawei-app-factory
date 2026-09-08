import SwiftData
import SwiftUI

struct ItemEditView: View {
    let item: Item?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var detail = ""
    // Held as text, not Int: a numeric binding cannot represent "empty" while
    // the field is being cleared, which is how the AppGallery build shipped a
    // field the user could not erase (lesson 9 of the handoff).
    @State private var intervalText = "7"

    private var interval: Int? {
        guard let value = Int(intervalText), value > 0, value <= 365 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("edit.title", text: $title)
                    .accessibilityIdentifier("edit.title")
                TextField("edit.detail", text: $detail, axis: .vertical)
                    .accessibilityIdentifier("edit.detail")
                TextField("edit.interval", text: $intervalText)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("edit.interval")
                if interval == nil {
                    Text("edit.interval.invalid")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("edit.interval.error")
                }
            }
            .navigationTitle(item == nil ? "edit.new" : "edit.existing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                        .accessibilityIdentifier("edit.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("edit.save", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || interval == nil)
                        .accessibilityIdentifier("edit.save")
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let item else { return }
        title = item.title
        detail = item.detail
        intervalText = String(item.intervalDays)
    }

    private func save() {
        guard let interval else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let item {
            item.title = trimmed
            item.detail = detail
            item.intervalDays = interval
        } else {
            context.insert(Item(title: trimmed, detail: detail, intervalDays: interval))
        }
        dismiss()
    }
}
