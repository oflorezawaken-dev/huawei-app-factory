import SwiftUI

struct SettingsView: View {
    @Environment(RemoveAdsStore.self) private var store
    @State private var working = false

    private var privacyURL: URL? { URL(string: "https://oflorezawaken-dev.github.io/huawei-app-factory/") }

    var body: some View {
        NavigationStack {
            Form {
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
                }

                Section("settings.privacy") {
                    if let privacyURL {
                        Link("settings.privacy.policy", destination: privacyURL)
                            .accessibilityIdentifier("settings.privacy.policy")
                    }
                    Text("settings.privacy.explainer")
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
