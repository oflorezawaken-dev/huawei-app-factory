import SwiftData
import SwiftUI

/// S013 First Run. No advertising, no tracking prompt of any kind here --
/// the app has not done anything yet, so nothing has earned that question.
struct FirstRunView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @State private var currencyCode: String
    @State private var measurementSystem: MeasurementSystem

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
        _currencyCode = State(initialValue: AppSettings.defaultCurrencyCode)
        _measurementSystem = State(initialValue: MeasurementSystem.systemDefault)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("firstrun.line1", systemImage: "book.closed")
                            .accessibilityIdentifier("firstrun.line1")
                        Label("firstrun.line2", systemImage: "chart.line.uptrend.xyaxis")
                            .accessibilityIdentifier("firstrun.line2")
                        Label("firstrun.line3", systemImage: "checkmark.seal")
                            .accessibilityIdentifier("firstrun.line3")
                    }
                    .font(.title3)

                    Text("firstrun.barcodeNote")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("firstrun.barcodeNote")

                    VStack(alignment: .leading, spacing: 12) {
                        Text("firstrun.confirmSettings").font(.headline)
                        Picker("firstrun.currency", selection: $currencyCode) {
                            ForEach(CurrencyCatalog.commonCodes, id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                        .accessibilityIdentifier("firstrun.currency")
                        Picker("firstrun.measurementSystem", selection: $measurementSystem) {
                            Text("settings.units.metric").tag(MeasurementSystem.metric)
                            Text("settings.units.imperial").tag(MeasurementSystem.imperial)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("firstrun.measurementSystem")
                    }

                    VStack(spacing: 12) {
                        Button {
                            applySettings()
                            SampleDataFactory.load(into: context)
                            finish()
                        } label: {
                            Text("firstrun.loadSample").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("firstrun.loadSample")

                        Button {
                            applySettings()
                            finish()
                        } label: {
                            Text("firstrun.startEmpty").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("firstrun.startEmpty")
                    }
                }
                .padding()
            }
            .navigationTitle("firstrun.title")
        }
        .interactiveDismissDisabled()
    }

    private func applySettings() {
        settings.currencyCode = currencyCode
        settings.currencySymbol = CurrencyCatalog.symbol(for: currencyCode)
        settings.measurementSystem = measurementSystem
    }

    private func finish() {
        settings.hasCompletedFirstRun = true
        isPresented = false
    }
}

enum CurrencyCatalog {
    static let commonCodes = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL", "TRY", "SAR"]

    static func symbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }
}
