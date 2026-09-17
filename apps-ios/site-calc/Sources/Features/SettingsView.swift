import SwiftData
import SwiftUI

/// S011: the user's own defaults, the purchase, the data, the reference
/// constants, and the honest account of what the app does. Carries the
/// banner (one of only three screens allowed to).
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(RemoveAdsStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var jobs: [SiteJob]

    @State private var working = false
    @State private var maxRiserText = ""
    @State private var minTreadText = ""
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var showingRemoveAds = false

    private var privacyURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/site-calc/privacy/") }
    private var supportURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/site-calc/support/") }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section("settings.display") {
                        Picker("settings.system", selection: systemBinding) {
                            Text("settings.system.imperial").tag(MeasurementSystem.imperial)
                            Text("settings.system.metric").tag(MeasurementSystem.metric)
                        }
                        .accessibilityIdentifier("settings.system")
                        Picker("settings.precision", selection: precisionBinding) {
                            ForEach(FractionPrecision.allCases, id: \.self) { p in
                                Text(verbatim: "1/\(p.denominator)").tag(p)
                            }
                        }
                        .accessibilityIdentifier("settings.precision")
                    }

                    Section("settings.stairLimits") {
                        TextField("stair.maxRiser", text: $maxRiserText).keyboardType(.decimalPad)
                            .accessibilityIdentifier("settings.maxRiser")
                            .onChange(of: maxRiserText) { _, new in
                                settings.maxRiserHeight = InputParsing.length(new, settings: settings, defaultUnit: .inches)
                            }
                        TextField("stair.minTread", text: $minTreadText).keyboardType(.decimalPad)
                            .accessibilityIdentifier("settings.minTread")
                            .onChange(of: minTreadText) { _, new in
                                settings.minTreadDepth = InputParsing.length(new, settings: settings, defaultUnit: .inches)
                            }
                    }

                    Section("settings.estimatorDefaults") {
                        LabeledContent("settings.studSpacing",
                                       value: LengthFormatting.feetInchFraction(settings.studSpacing, precision: .sixteenth))
                        LabeledContent("settings.sheetSize",
                                       value: "\(Int(boundaryValue(of: settings.sheetWidth.converted(to: .feet))))x" +
                                       "\(Int(boundaryValue(of: settings.sheetHeight.converted(to: .feet)))) ft")
                        LabeledContent("settings.tileWaste", value: "\(settings.tileWastePercent.description)%")
                        LabeledContent("settings.bagYield",
                                       value: "\(boundaryValue(of: settings.concreteBagYieldCubicFeet)) ft3")
                    }

                    Section("settings.ads") {
                        if store.adsRemoved {
                            Label("settings.ads.removed", systemImage: "checkmark.circle")
                                .accessibilityIdentifier("settings.ads.removed")
                        } else {
                            Button("settings.ads.remove") { showingRemoveAds = true }
                                .accessibilityIdentifier("settings.ads.remove")
                            Button("settings.ads.restore") {
                                Task { working = true; await store.restore(); working = false }
                            }
                            .disabled(working)
                            .accessibilityIdentifier("settings.ads.restore")
                        }
                    }

                    Section("settings.data") {
                        Button("settings.removeSample", role: .destructive) { removeSampleJob() }
                            .disabled(!jobs.contains { $0.isSample })
                            .accessibilityIdentifier("settings.removeSample")
                        Button("settings.deleteAll", role: .destructive) { showingDeleteConfirmation = true }
                            .accessibilityIdentifier("settings.deleteAll")
                    }

                    Section("settings.reference") {
                        Text("settings.reference.lumber").font(.footnote)
                        Text("settings.reference.sheets").font(.footnote)
                        Text("settings.reference.bagYields").font(.footnote)
                        Text("settings.reference.cubicYard").font(.footnote)
                        Text("settings.reference.roofingSquare").font(.footnote)
                        Text("settings.statement.noRegulatoryValues")
                            .font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("settings.statement.noRegulatoryValues")
                    }

                    Section("settings.privacy") {
                        Text("settings.privacy.explainer").font(.footnote).foregroundStyle(.secondary)
                        Text("settings.privacy.whyAds").font(.footnote).foregroundStyle(.secondary)
                        if let privacyURL { Link("settings.privacy.policy", destination: privacyURL) }
                        if let supportURL { Link("settings.support", destination: supportURL) }
                    }

                    Section("settings.about") {
                        LabeledContent("settings.about.version", value: Bundle.appVersion)
                    }
                }
                AdBannerFooter()
            }
            .navigationTitle("tab.settings")
            .onAppear {
                if maxRiserText.isEmpty, let existing = settings.maxRiserHeight {
                    maxRiserText = LengthFormatting.decimal(existing, unit: .inches, decimalPlaces: 3)
                }
                if minTreadText.isEmpty, let existing = settings.minTreadDepth {
                    minTreadText = LengthFormatting.decimal(existing, unit: .inches, decimalPlaces: 3)
                }
            }
            .sheet(isPresented: $showingRemoveAds) { RemoveAdsView() }
            .alert("settings.deleteAll.title", isPresented: $showingDeleteConfirmation) {
                TextField("settings.deleteAll.typeDelete", text: $deleteConfirmationText)
                Button("settings.deleteAll.confirm", role: .destructive) {
                    if deleteConfirmationText.uppercased() == "DELETE" { deleteAllData() }
                    deleteConfirmationText = ""
                }
                Button("edit.cancel", role: .cancel) { deleteConfirmationText = "" }
            } message: {
                Text("settings.deleteAll.message")
            }
        }
    }

    private var systemBinding: Binding<MeasurementSystem> {
        Binding(get: { settings.preferredSystem }, set: { settings.preferredSystem = $0 })
    }
    private var precisionBinding: Binding<FractionPrecision> {
        Binding(get: { settings.fractionPrecision }, set: { settings.fractionPrecision = $0 })
    }

    private func removeSampleJob() {
        for job in jobs where job.isSample { context.delete(job) }
    }

    private func deleteAllData() {
        for job in jobs { context.delete(job) }
    }
}

extension Bundle {
    static var appVersion: String {
        let short = main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
