import SwiftUI
import UIKit

enum ExportFormat: String, CaseIterable, Identifiable {
    case pdf, csv, both
    var id: String { rawValue }
}

/// S010: get a job out as a PDF or a CSV, free, and only then show an ad.
/// The interstitial is presented only after `FileManager.fileExists` confirms
/// the write really happened, and only after the share sheet is dismissed.
struct ExportView: View {
    let job: SiteJob

    @Environment(AppSettings.self) private var settings
    @Environment(RemoveAdsStore.self) private var adsStore
    @Environment(\.dismiss) private var dismiss
    @State private var format: ExportFormat = .pdf
    @State private var shareURLs: [URL] = []
    @State private var showingShareSheet = false

    private let interstitial = InterstitialAdController()

    var body: some View {
        NavigationStack {
            Form {
                Section("export.format") {
                    Picker("export.format", selection: $format) {
                        Text("export.format.pdf").tag(ExportFormat.pdf)
                        Text("export.format.csv").tag(ExportFormat.csv)
                        Text("export.format.both").tag(ExportFormat.both)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("export.formatPicker")
                }
                Section("export.contents") {
                    Text("export.contents.description")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("export.statement.free")
                        .font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("export.statement.free")
                }
                Section {
                    Button("export.action") { performExport() }
                        .accessibilityIdentifier("export.action")
                }
            }
            .navigationTitle("jobDetail.export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("edit.cancel") { dismiss() }
                }
            }
            .onAppear { interstitial.preload() }
            .sheet(isPresented: $showingShareSheet, onDismiss: presentInterstitialIfEligible) {
                ShareSheet(items: shareURLs)
            }
        }
    }

    private func performExport() {
        var urls: [URL] = []
        let directory = FileManager.default.temporaryDirectory
        let base = job.name.replacingOccurrences(of: "/", with: "-")

        if format == .pdf || format == .both {
            let data = PDFExport.generate(job: job, precision: settings.fractionPrecision,
                                           system: settings.preferredSystem, metricUnit: settings.preferredMetricUnit)
            let url = directory.appendingPathComponent("\(base).pdf")
            try? data.write(to: url)
            urls.append(url)
        }
        if format == .csv || format == .both {
            let text = CSVExport.generate(job: job, precision: settings.fractionPrecision,
                                           system: settings.preferredSystem, metricUnit: settings.preferredMetricUnit)
            let url = directory.appendingPathComponent("\(base).csv")
            try? text.data(using: .utf8)?.write(to: url)
            urls.append(url)
        }
        shareURLs = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        showingShareSheet = !shareURLs.isEmpty
    }

    private func presentInterstitialIfEligible() {
        guard !adsStore.adsRemoved, !UITestMode.isActive, let first = shareURLs.first else { return }
        interstitial.presentIfFileExists(at: first, from: UIApplication.shared.topViewController())
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [URL]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

extension UIApplication {
    func topViewController() -> UIViewController? {
        connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
            .first { $0.isKeyWindow }?.rootViewController
    }
}
