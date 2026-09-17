import SwiftData
import SwiftUI

enum AreaVolumeShape: String, CaseIterable, Identifiable {
    case room, wall, slab, rectFooting, circularFooting, column, circle, segment, arc
    var id: String { rawValue }
}

/// S006: shapes to quantities, in whichever unit system the user is working
/// in. No advertising of any kind.
struct AreaVolumeView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(CalculatorViewModel.self) private var calculator
    @Environment(\.modelContext) private var context

    @State private var shape: AreaVolumeShape = .room
    @State private var a = ""
    @State private var b = ""
    @State private var c = ""
    @State private var d = ""
    @State private var showingSaveSheet = false

    private func L(_ text: String) -> Length? { InputParsing.length(text, settings: settings) }

    private var quantity: Quantity? {
        switch shape {
        case .room:
            guard let w = L(a), let h = L(b) else { return nil }
            return .area(AreaVolumeSolver.rectangleArea(width: w, height: h))
        case .wall:
            guard let w = L(a), let h = L(b) else { return nil }
            var openings: [(width: Length, height: Length)] = []
            if let ow = L(c), let oh = L(d) { openings = [(ow, oh)] }
            return .area(AreaVolumeSolver.wallArea(width: w, height: h, openings: openings))
        case .slab:
            guard let l = L(a), let w = L(b), let t = L(c) else { return nil }
            return .volume(AreaVolumeSolver.slabVolume(length: l, width: w, thickness: t))
        case .rectFooting:
            guard let l = L(a), let w = L(b), let depth = L(c) else { return nil }
            return .volume(AreaVolumeSolver.rectangularFootingVolume(length: l, width: w, depth: depth))
        case .circularFooting:
            guard let r = L(a), let depth = L(b) else { return nil }
            return .volume(AreaVolumeSolver.circularFootingVolume(radius: r, depth: depth))
        case .column:
            guard let w = L(a), let depth = L(b), let h = L(c) else { return nil }
            return .volume(AreaVolumeSolver.columnVolume(width: w, depth: depth, height: h))
        case .circle:
            guard let r = L(a) else { return nil }
            return .area(AreaVolumeSolver.circleArea(radius: r))
        case .segment:
            guard let r = L(a), let angle = InputParsing.rational(b) else { return nil }
            return .area(AreaVolumeSolver.segmentArea(radius: r, includedAngleDegrees: angle))
        case .arc:
            guard let r = L(a), let angle = InputParsing.rational(b) else { return nil }
            return .length(AreaVolumeSolver.arcLength(radius: r, includedAngleDegrees: angle))
        }
    }

    var body: some View {
        Form {
            Section("areaVolume.shape") {
                Picker("areaVolume.shape", selection: $shape) {
                    ForEach(AreaVolumeShape.allCases) { s in
                        Text(localized("areaVolume.shape." + s.rawValue)).tag(s)
                    }
                }
                .accessibilityIdentifier("areaVolume.shapePicker")
            }

            Section("areaVolume.inputs") {
                Text(localized("areaVolume.hint." + shape.rawValue))
                    .font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("areaVolume.hint")
                ForEach(fieldLabels, id: \.self) { label in
                    fieldEditor(for: label)
                }
            }

            if let quantity {
                Section("areaVolume.result") {
                    LabeledContent("areaVolume.result",
                                   value: QuantityFormatting.display(quantity, precision: settings.fractionPrecision,
                                                                      system: settings.preferredSystem,
                                                                      metricUnit: settings.preferredMetricUnit))
                        .accessibilityIdentifier("areaVolume.result.value")
                    Text(localized("solver.fromWhatYouEntered",
                                    [a, b, c, d].filter { !$0.isEmpty }.joined(separator: ", ")))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button("solver.sendToTape") {
                        calculator.appendExternal(quantity, label: "areaVolume.result".localized)
                    }
                    .accessibilityIdentifier("areaVolume.sendToTape")
                    Button("solver.sendToEstimator") { }
                        .accessibilityIdentifier("areaVolume.sendToEstimator")
                    Button("solver.saveToJob") { showingSaveSheet = true }
                        .accessibilityIdentifier("areaVolume.saveToJob")
                }
            }
        }
        .keyboardDoneToolbar()
        .navigationTitle("solvers.areaVolume")
        .onChange(of: shape) { _, _ in a = ""; b = ""; c = ""; d = "" }
        .sheet(isPresented: $showingSaveSheet) {
            if let quantity {
                let saved = SavedSolverResult(kind: .areaVolume, title: "solvers.areaVolume".localized,
                                               inputsSummary: localized("solver.fromWhatYouEntered",
                                                   [a, b, c, d].filter { !$0.isEmpty }.joined(separator: ", ")),
                                               values: [LabeledQuantity(label: "areaVolume.result".localized,
                                                                        quantity: quantity)])
                SaveResultSheet(onSaveNew: { name in
                    let job = SiteJob(name: name, solverResults: [saved])
                    context.insert(job)
                }, onSaveExisting: { job in
                    job.solverResults.append(saved)
                })
            }
        }
    }

    private var fieldLabels: [String] {
        switch shape {
        case .room: return ["a", "b"]
        case .wall: return ["a", "b", "c", "d"]
        case .slab, .rectFooting, .column: return ["a", "b", "c"]
        case .circularFooting: return ["a", "b"]
        case .circle: return ["a"]
        case .segment, .arc: return ["a", "b"]
        }
    }

    @ViewBuilder
    private func fieldEditor(for key: String) -> some View {
        let binding: Binding<String> = {
            switch key {
            case "a": return $a
            case "b": return $b
            case "c": return $c
            default: return $d
            }
        }()
        TextField(localized("areaVolume.field." + key), text: binding)
            .keyboardType(.decimalPad)
            .accessibilityIdentifier("areaVolume.field.\(key)")
    }
}
