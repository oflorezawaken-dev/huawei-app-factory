import SwiftUI

/// S012: offer the one-time purchase and say plainly what it does and does
/// not do. No advertising of any kind.
struct RemoveAdsView: View {
    @Environment(RemoveAdsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var working = false

    var body: some View {
        NavigationStack {
            Form {
                Section("removeAds.whatItRemoves") {
                    Text("removeAds.removes.banner")
                    Text("removeAds.removes.interstitial")
                }
                Section("removeAds.whatItUnlocks") {
                    Text("removeAds.unlocks.nothing")
                        .accessibilityIdentifier("removeAds.unlocksNothing")
                }
                Section {
                    Button {
                        Task { working = true; await store.purchase(); working = false; if store.adsRemoved { dismiss() } }
                    } label: {
                        HStack {
                            Text("removeAds.buy")
                            Spacer()
                            if let price = store.product?.displayPrice { Text(price).foregroundStyle(.secondary) }
                        }
                    }
                    .disabled(working)
                    .accessibilityIdentifier("removeAds.buy")

                    Button("settings.ads.restore") {
                        Task { working = true; await store.restore(); working = false; if store.adsRemoved { dismiss() } }
                    }
                    .disabled(working)
                    .accessibilityIdentifier("removeAds.restore")

                    if store.purchaseFailed {
                        Text("settings.ads.failed").font(.footnote).foregroundStyle(.secondary)
                            .accessibilityIdentifier("removeAds.failed")
                    }
                }
            }
            .navigationTitle("removeAds.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("edit.cancel") { dismiss() } }
            }
            .task { await store.loadProduct() }
        }
    }
}
