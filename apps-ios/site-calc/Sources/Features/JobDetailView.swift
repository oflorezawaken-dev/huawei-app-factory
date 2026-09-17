import SwiftData
import SwiftUI

/// S009: one job's tape, solver results and material lists in one place, and
/// the way out to export. Carries the banner.
struct JobDetailView: View {
    @Bindable var job: SiteJob
    @Environment(AppSettings.self) private var settings
    @Environment(CalculatorViewModel.self) private var calculator
    @Environment(\.dismiss) private var dismiss
    @State private var showingExport = false

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("jobDetail.info") {
                    TextField("job.name", text: $job.name).accessibilityIdentifier("jobDetail.name")
                    TextField("jobDetail.note", text: $job.note, axis: .vertical)
                        .accessibilityIdentifier("jobDetail.note")
                    Text(job.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                }

                if !job.tapeLines.isEmpty {
                    Section("jobDetail.tape") {
                        ForEach(job.tapeLines) { line in
                            HStack {
                                Text(line.label.isEmpty ? "tape.unlabeled".localized : line.label)
                                Spacer()
                                if let result = line.runningResult {
                                    Text(QuantityFormatting.display(result, precision: settings.fractionPrecision,
                                                                     system: settings.preferredSystem,
                                                                     metricUnit: settings.preferredMetricUnit))
                                }
                            }
                        }
                    }
                }

                ForEach(job.solverResults) { result in
                    Section(result.title) {
                        ForEach(result.values) { value in
                            LabeledContent(value.label,
                                           value: QuantityFormatting.display(value.quantity,
                                                                              precision: settings.fractionPrecision,
                                                                              system: settings.preferredSystem,
                                                                              metricUnit: settings.preferredMetricUnit))
                        }
                    }
                }

                ForEach(job.materialLists) { list in
                    Section(list.title) {
                        ForEach(list.lines) { line in
                            LabeledContent(line.label, value: "\(line.roundedQuantity) \(line.unit)")
                        }
                    }
                }

                Section {
                    Button("jobDetail.continueOnCalculator") {
                        calculator.loadTape(from: job)
                        dismiss()
                    }
                    .accessibilityIdentifier("jobDetail.continueOnCalculator")
                    Button("jobDetail.export") { showingExport = true }
                        .accessibilityIdentifier("jobDetail.export")
                }
            }
            AdBannerFooter()
        }
        .navigationTitle(job.name)
        .sheet(isPresented: $showingExport) {
            ExportView(job: job)
        }
    }
}
