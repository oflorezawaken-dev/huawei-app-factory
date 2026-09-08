import SwiftData
import SwiftUI
import UIKit

/// S009 Trip Summary -- closes the loop after a trip is saved. The one place
/// the interstitial is allowed: once per session, never before this screen,
/// and only after the trip has actually been saved.
struct TripSummaryView: View {
    let trip: Trip

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(RemoveAdsStore.self) private var removeAdsStore
    @Environment(InterstitialAdController.self) private var interstitial

    private var newBestEntries: [TripEntry] { trip.entries.filter(\.isNewBest) }
    private var pricedEntries: [TripEntry] { trip.entries.filter { $0.pricePaid != nil } }
    private var difference: Decimal { trip.total - trip.estimatedTotal }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.store?.name ?? "").font(.title2.bold())
                        Text(trip.date, style: .date).foregroundStyle(.secondary)
                        Text("tripSummary.itemCount \(trip.itemCount)")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("tripSummary.header")

                    LabeledContent("tripSummary.total") {
                        Text(PriceFormatting.currencyAmount(trip.total, symbol: settings.currencySymbol))
                            .font(.system(.title3, design: .monospaced))
                    }
                    .accessibilityIdentifier("tripSummary.total")

                    LabeledContent("tripSummary.estimateVsActual") {
                        Text(PriceFormatting.currencyAmount(difference, symbol: settings.currencySymbol))
                            .foregroundStyle(difference > 0 ? .red : .green)
                    }
                    .accessibilityIdentifier("tripSummary.estimateVsActual")

                    if !newBestEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("tripSummary.newBests").font(.headline)
                            ForEach(newBestEntries) { entry in
                                Text(entry.item?.name ?? "")
                            }
                        }
                        .accessibilityIdentifier("tripSummary.newBests")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("tripSummary.recorded").font(.headline)
                        ForEach(pricedEntries) { entry in
                            HStack {
                                Text(entry.item?.name ?? "")
                                Spacer()
                                if let price = entry.pricePaid {
                                    Text(PriceFormatting.currencyAmount(price, symbol: settings.currencySymbol))
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("tripSummary.recorded")

                    Button("tripSummary.done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("tripSummary.done")
                }
                .padding()
            }
            .navigationTitle("tripSummary.title")
        }
        .task {
            guard !UITestMode.isActive, !removeAdsStore.adsRemoved else { return }
            let viewController = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
                .first { $0.isKeyWindow }?.rootViewController
            await interstitial.presentIfAllowed(from: viewController, activityLog: AdActivityLog.shared)
        }
    }
}
