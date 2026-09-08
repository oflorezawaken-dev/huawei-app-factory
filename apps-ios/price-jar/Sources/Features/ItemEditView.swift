import PhotosUI
import SwiftData
import SwiftUI

/// S012 Add or Edit Item. No advertising of any kind.
struct ItemEditView: View {
    let item: Item?
    /// Filled in when this view is reached from an unknown-barcode scan.
    var prefilledBarcode: String?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ItemCategory = .other
    @State private var packageSizeText = "1"
    @State private var unit: MeasurementUnit = .item
    @State private var displayUnit: DisplayUnit = .perItem
    @State private var barcode = ""
    @State private var photoData: Data?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false

    private var packageSize: Decimal? {
        guard let value = DecimalParsing.parse(packageSizeText), value > 0 else { return nil }
        return value
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && packageSize != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("edit.itemDetails") {
                    TextField("edit.name", text: $name)
                        .accessibilityIdentifier("edit.name")
                    TextField("edit.brand", text: $brand)
                        .accessibilityIdentifier("edit.brand")
                    Picker("edit.category", selection: $category) {
                        ForEach(ItemCategory.allCases) { category in
                            Text(LocalizedStringKey(category.localizationKey)).tag(category)
                        }
                    }
                    .accessibilityIdentifier("edit.category")
                }

                Section("edit.packaging") {
                    HStack {
                        Text("edit.packageSize")
                        TextField("edit.packageSize", text: $packageSizeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("edit.packageSize")
                    }
                    Picker("edit.unit", selection: $unit) {
                        ForEach(MeasurementUnit.units(for: unit.dimension)) { unitCase in
                            Text(LocalizedStringKey(unitCase.localizationKey)).tag(unitCase)
                        }
                    }
                    .accessibilityIdentifier("edit.unit")
                    Picker("edit.dimension", selection: dimensionBinding) {
                        Text("dimension.mass").tag(MeasurementUnit.Dimension.mass)
                        Text("dimension.volume").tag(MeasurementUnit.Dimension.volume)
                        Text("dimension.count").tag(MeasurementUnit.Dimension.count)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("edit.dimension")
                    Picker("edit.displayUnit", selection: $displayUnit) {
                        ForEach(DisplayUnit.displayUnits(for: unit.dimension)) { displayUnitCase in
                            Text(LocalizedStringKey(displayUnitCase.localizationKey)).tag(displayUnitCase)
                        }
                    }
                    .accessibilityIdentifier("edit.displayUnit")
                }

                Section("edit.identification") {
                    TextField("edit.barcode", text: $barcode)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("edit.barcode")
                    PhotosPicker("edit.photo", selection: $photoPickerItem, matching: .images)
                        .accessibilityIdentifier("edit.photo")
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .accessibilityIdentifier("edit.photoPreview")
                    }
                }

                if item != nil {
                    Section {
                        Button("edit.delete", role: .destructive) { showDeleteConfirmation = true }
                            .accessibilityIdentifier("edit.delete")
                    }
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
                        .disabled(!isValid)
                        .accessibilityIdentifier("edit.save")
                }
            }
            .onAppear(perform: load)
            .onChange(of: unit) { _, newUnit in
                if displayUnit.dimension != newUnit.dimension {
                    displayUnit = DisplayUnit.systemDefault(for: newUnit.dimension, metric: settings.measurementSystem == .metric)
                }
            }
            .task(id: photoPickerItem) {
                guard let photoPickerItem, let data = try? await photoPickerItem.loadTransferable(type: Data.self) else { return }
                photoData = data
            }
            .confirmationDialog(
                Text("edit.deleteConfirm.title \(item?.priceEntries.count ?? 0)"),
                isPresented: $showDeleteConfirmation, titleVisibility: .visible
            ) {
                Button("edit.delete", role: .destructive, action: deleteItem)
                Button("edit.cancel", role: .cancel) {}
            }
        }
    }

    private var dimensionBinding: Binding<MeasurementUnit.Dimension> {
        Binding(
            get: { unit.dimension },
            set: { newDimension in
                unit = MeasurementUnit.units(for: newDimension).first ?? .item
            }
        )
    }

    private func load() {
        barcode = prefilledBarcode ?? ""
        guard let item else { return }
        name = item.name
        brand = item.brand
        category = item.category
        packageSizeText = NSDecimalNumber(decimal: item.defaultPackageSize).stringValue
        unit = item.defaultUnit
        displayUnit = item.preferredDisplayUnit
        barcode = item.barcode ?? prefilledBarcode ?? ""
        photoData = item.photoData
    }

    private func save() {
        guard let packageSize else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedBrand = brand.trimmingCharacters(in: .whitespaces)
        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespaces)
        if let item {
            item.name = trimmedName
            item.brand = trimmedBrand
            item.category = category
            item.defaultPackageSize = packageSize
            item.defaultUnit = unit
            item.preferredDisplayUnit = displayUnit
            item.barcode = trimmedBarcode.isEmpty ? nil : trimmedBarcode
            item.photoData = photoData
        } else {
            let newItem = Item(name: trimmedName, brand: trimmedBrand, category: category,
                                defaultPackageSize: packageSize, defaultUnit: unit,
                                preferredDisplayUnit: displayUnit,
                                barcode: trimmedBarcode.isEmpty ? nil : trimmedBarcode,
                                photoData: photoData)
            context.insert(newItem)
        }
        dismiss()
    }

    private func deleteItem() {
        guard let item else { return }
        context.delete(item)
        dismiss()
    }
}
