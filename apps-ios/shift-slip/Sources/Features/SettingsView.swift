import SwiftData
import SwiftUI

/// S011: the user's own defaults, the purchase, the data, and the honest
/// explanation of what the app does. Carries no advertising.
struct SettingsView: View {
    @Environment(RemoveAdsStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var working = false
    @State private var deleteConfirmationText = ""
    @State private var showingDeleteConfirmation = false
    @State private var minimumWageText = ""

    private var privacyURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/shift-slip/privacy/") }
    private var supportURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/shift-slip/support/") }

    var body: some View {
        Form {
            Section("settings.section.record") {
                TextField("settings.employeename", text: Binding(
                    get: { settings.employeeName }, set: { settings.employeeName = $0 }))
                    .accessibilityIdentifier("settings.employeename")
                TextField("settings.currencycode", text: Binding(
                    get: { settings.currencyCode }, set: { settings.currencyCode = $0 }))
                    .textInputAutocapitalization(.characters)
                    .accessibilityIdentifier("settings.currencycode")
                TextField("settings.minimumwage", text: $minimumWageText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("settings.minimumwage")
                    .onAppear { minimumWageText = settings.minimumWage?.fixedPointString ?? "" }
                    .onChange(of: minimumWageText) { _, newValue in settings.minimumWage = DecimalParsing.parse(newValue) }
                Picker("settings.firstdayofweek", selection: Binding(
                    get: { settings.firstDayOfWeek }, set: { settings.firstDayOfWeek = $0 })) {
                    ForEach(1...7, id: \.self) { weekday in
                        Text(Calendar.current.weekdaySymbols[(weekday - 1) % 7]).tag(weekday)
                    }
                }
                .accessibilityIdentifier("settings.firstdayofweek")
                Picker("settings.defaultentrymode", selection: Binding(
                    get: { settings.defaultEntryMode }, set: { settings.defaultEntryMode = $0 })) {
                    Text("logshift.entrymode.times").tag(ShiftEntryMode.times)
                    Text("logshift.entrymode.hours").tag(ShiftEntryMode.hours)
                }
                .accessibilityIdentifier("settings.defaultentrymode")
            }

            Section("settings.ads") {
                if store.adsRemoved {
                    Label("settings.ads.removed", systemImage: "checkmark.circle")
                        .accessibilityIdentifier("settings.ads.removed")
                } else {
                    Button {
                        Task { working = true; await store.purchase(); working = false }
                    } label: {
                        HStack {
                            Text("settings.ads.remove")
                            Spacer()
                            if let price = store.product?.displayPrice { Text(price).foregroundStyle(.secondary) }
                        }
                    }
                    .disabled(working)
                    .accessibilityIdentifier("settings.ads.remove")

                    Button("settings.ads.restore") {
                        Task { working = true; await store.restore(); working = false }
                    }
                    .disabled(working)
                    .accessibilityIdentifier("settings.ads.restore")

                    if store.purchaseFailed {
                        Text("settings.ads.failed")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("settings.ads.failed")
                    }
                }
                Text("settings.ads.why")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("settings.export") {
                NavigationLink("settings.export.link") {
                    ExportView(jobFilter: nil, initialStart: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
                               initialEnd: .now)
                }
                .accessibilityIdentifier("settings.export.link")
                Toggle("settings.export.reminder", isOn: Binding(
                    get: { settings.monthlyExportReminderEnabled }, set: { settings.monthlyExportReminderEnabled = $0 }))
                    .accessibilityIdentifier("settings.export.reminder")
            }

            Section("settings.data") {
                Button("settings.removesampledata") {
                    SampleDataFactory.removeSampleData(from: context)
                }
                .accessibilityIdentifier("settings.removesampledata")

                Button("settings.deleteall", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .accessibilityIdentifier("settings.deleteall")
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
                Text("settings.privacy.explainer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("common.recordsnotadvice")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("settings.about") {
                LabeledContent("settings.about.version", value: Bundle.appVersion)
                    .accessibilityIdentifier("settings.about.version")
            }
        }
        .navigationTitle("tab.settings")
        .task { await store.loadProduct() }
        .alert("settings.deleteall.confirm.title", isPresented: $showingDeleteConfirmation) {
            TextField("settings.deleteall.confirm.field", text: $deleteConfirmationText)
                .accessibilityIdentifier("settings.deleteall.confirm.field")
            Button("settings.deleteall.confirm.action", role: .destructive) {
                if deleteConfirmationText.uppercased() == "DELETE" {
                    deleteAllData()
                }
                deleteConfirmationText = ""
            }
            Button("common.cancel", role: .cancel) { deleteConfirmationText = "" }
        } message: {
            Text("settings.deleteall.confirm.message")
        }
    }

    private func deleteAllData() {
        let jobs = (try? context.fetch(FetchDescriptor<Job>())) ?? []
        for job in jobs {
            for shift in job.shifts ?? [] {
                ClosoutPhotoStorage.delete(fileName: shift.closeoutPhotoFileName)
            }
            context.delete(job)
        }
    }
}

extension Bundle {
    static var appVersion: String {
        let short = main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
