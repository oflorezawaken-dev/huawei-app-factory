import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// S011 Settings. No advertising of any kind.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(RemoveAdsStore.self) private var removeAdsStore
    @Environment(AppSettings.self) private var settings
    @Query private var items: [Item]
    @Query private var stores: [Store]

    @State private var working = false
    @State private var showDeleteAllConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var exportedCSV: CSVDocumentExport?
    @State private var showSampleDataRemoved = false

    private var privacyURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/price-jar/privacy/") }
    private var supportURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/price-jar/support/") }

    private var hasSampleData: Bool { items.contains { $0.isSample } }

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.currency") {
                    Picker("settings.currency.code", selection: currencyCodeBinding) {
                        ForEach(CurrencyCatalog.commonCodes, id: \.self) { code in Text(code).tag(code) }
                    }
                    .accessibilityIdentifier("settings.currency.code")
                }

                Section("settings.units") {
                    Picker("settings.units.system", selection: measurementSystemBinding) {
                        Text("settings.units.metric").tag(MeasurementSystem.metric)
                        Text("settings.units.imperial").tag(MeasurementSystem.imperial)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.units.system")
                    Toggle("settings.includeSaleLoyalty", isOn: includeSaleLoyaltyBinding)
                        .accessibilityIdentifier("settings.includeSaleLoyalty")
                }

                Section("settings.ads") {
                    if removeAdsStore.adsRemoved {
                        Label("settings.ads.removed", systemImage: "checkmark.circle")
                            .accessibilityIdentifier("settings.ads.removed")
                    } else {
                        Button {
                            Task { working = true; await removeAdsStore.purchase(); working = false }
                        } label: {
                            HStack {
                                Text("settings.ads.remove")
                                Spacer()
                                if let price = removeAdsStore.product?.displayPrice {
                                    Text(price).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(working)
                        .accessibilityIdentifier("settings.ads.remove")

                        Button("settings.ads.restore") {
                            Task { working = true; await removeAdsStore.restore(); working = false }
                        }
                        .disabled(working)
                        .accessibilityIdentifier("settings.ads.restore")

                        if removeAdsStore.purchaseFailed {
                            Text("settings.ads.failed")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("settings.ads.failed")
                        }
                    }
                    Text("settings.ads.explainer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.ads.explainer")
                }

                Section("settings.data") {
                    Button("settings.export", action: exportCSV)
                        .accessibilityIdentifier("settings.export")

                    if hasSampleData {
                        Button("settings.removeSampleData", role: .destructive, action: removeSampleData)
                            .accessibilityIdentifier("settings.removeSampleData")
                    }
                    if showSampleDataRemoved {
                        Text("settings.removeSampleData.done")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("settings.deleteAll", role: .destructive) { showDeleteAllConfirmation = true }
                        .accessibilityIdentifier("settings.deleteAll")

                    Text("settings.data.explainer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("settings.data.explainer")
                }

                Section("settings.privacy") {
                    if let privacyURL {
                        Link("settings.privacy.policy", destination: privacyURL)
                            .accessibilityIdentifier("settings.privacy.policy")
                    }
                    if let supportURL {
                        Link("settings.support", destination: supportURL)
                            .accessibilityIdentifier("settings.support")
                    }
                }

                Section("settings.about") {
                    LabeledContent("settings.about.version", value: Bundle.appVersion)
                        .accessibilityIdentifier("settings.about.version")
                }
            }
            .navigationTitle("tab.settings")
            .task { await removeAdsStore.loadProduct() }
            .sheet(item: $exportedCSV) { export in
                ShareSheet(activityItems: [export.url])
            }
            .alert("settings.deleteAll.title", isPresented: $showDeleteAllConfirmation) {
                TextField("settings.deleteAll.confirmField", text: $deleteConfirmationText)
                    .accessibilityIdentifier("settings.deleteAll.confirmField")
                Button("settings.deleteAll.confirm", role: .destructive, action: deleteAll)
                    .disabled(deleteConfirmationText.uppercased() != "DELETE")
                Button("edit.cancel", role: .cancel) { deleteConfirmationText = "" }
            } message: {
                Text("settings.deleteAll.message")
            }
        }
    }

    private var currencyCodeBinding: Binding<String> {
        Binding(get: { settings.currencyCode }, set: {
            settings.currencyCode = $0
            settings.currencySymbol = CurrencyCatalog.symbol(for: $0)
        })
    }

    private var measurementSystemBinding: Binding<MeasurementSystem> {
        Binding(get: { settings.measurementSystem }, set: { settings.measurementSystem = $0 })
    }

    private var includeSaleLoyaltyBinding: Binding<Bool> {
        Binding(get: { settings.includeSaleAndLoyaltyInTypical }, set: { settings.includeSaleAndLoyaltyInTypical = $0 })
    }

    private func removeSampleData() {
        SampleDataFactory.removeAll(from: context)
        showSampleDataRemoved = true
    }

    private func exportCSV() {
        let rows: [CSVExport.Row] = items.flatMap { item in
            item.recordedEntries.map { entry in
                CSVExport.Row(itemName: item.name, brand: item.brand, category: item.category.rawValue,
                               storeName: entry.store?.name ?? "", date: entry.date, packageSize: entry.packageSize,
                               unit: entry.unit.rawValue, paidPrice: entry.price, unitPrice: entry.unitPrice,
                               currencyCode: settings.currencyCode, isSale: entry.isSale, isLoyalty: entry.isLoyalty)
            }
        }
        let data = CSVExport.data(rows: rows)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PriceJar-export.csv")
        try? data.write(to: url, options: .atomic)
        exportedCSV = CSVDocumentExport(url: url)
    }

    private func deleteAll() {
        for item in items { context.delete(item) }
        for store in stores { context.delete(store) }
        deleteConfirmationText = ""
    }
}

private struct CSVDocumentExport: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

extension Bundle {
    static var appVersion: String {
        let short = main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
