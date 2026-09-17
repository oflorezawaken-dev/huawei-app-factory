import SwiftData
import SwiftUI

enum MaterialCategory: String, CaseIterable, Identifiable {
    case concrete, framing, sheets, tile, paint, decking, roofing
    var id: String { rawValue }
}

/// S007: geometry to quantities of material -- counts and volumes, never
/// money. No currency field, no rate field and no money total anywhere on
/// this screen; every line shows the exact quantity alongside the rounded-up
/// purchasable count.
struct MaterialEstimatorView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context

    @State private var category: MaterialCategory = .concrete
    @State private var a = "" // generic numeric inputs, meaning depends on category
    @State private var b = ""
    @State private var c = ""
    @State private var draftLines: [MaterialLine] = []
    @State private var showingSaveSheet = false

    private func L(_ text: String) -> Length? { InputParsing.length(text, settings: settings) }
    private func R(_ text: String) -> Rational? { InputParsing.rational(text) }

    private var currentLine: MaterialLine? {
        switch category {
        case .concrete:
            guard let volumeArea = L(a), let width = L(b), let thickness = L(c) else { return nil }
            let volume = AreaVolumeSolver.slabVolume(length: volumeArea, width: width, thickness: thickness)
            let bags = MaterialEstimator.concreteBags(volume: volume, bagYieldCubicFeet: settings.concreteBagYieldCubicFeet)
            return MaterialLine(label: "material.concrete".localized,
                                 exactQuantity: decimalString(bags.exact), roundedQuantity: "\(bags.roundedUp)",
                                 unit: "material.unit.bags".localized)
        case .framing:
            guard let total = L(a) else { return nil }
            let spacing = L(b) ?? settings.studSpacing
            let result = MaterialEstimator.framing(total: total, spacing: spacing)
            return MaterialLine(label: "material.framing".localized,
                                 exactQuantity: decimalString(result.exactSpaces),
                                 roundedQuantity: "\(result.pieces)", unit: "material.unit.pieces".localized)
        case .sheets:
            guard let width = L(a), let height = L(b) else { return nil }
            let area = AreaVolumeSolver.rectangleArea(width: width, height: height)
            let result = MaterialEstimator.sheets(area: area, sheetWidth: settings.sheetWidth,
                                                   sheetHeight: settings.sheetHeight,
                                                   wastePercent: settings.tileWastePercent)
            return MaterialLine(label: "material.sheets".localized, exactQuantity: decimalString(result.exact),
                                 roundedQuantity: "\(result.roundedUp)", unit: "material.unit.sheets".localized)
        case .tile:
            guard let width = L(a), let height = L(b), let waste = R(c) else { return nil }
            let area = AreaVolumeSolver.rectangleArea(width: width, height: height)
            let result = MaterialEstimator.pieces(area: area, pieceWidth: Length(1, .feet), pieceHeight: Length(1, .feet),
                                                   wastePercent: waste)
            _ = area // area is the floor area; pieces use a 1x1 ft tile only as an illustrative default unit
            return MaterialLine(label: "material.tile".localized, exactQuantity: decimalString(result.exact),
                                 roundedQuantity: "\(result.roundedUp)", unit: "material.unit.tiles".localized)
        case .paint:
            guard let width = L(a), let height = L(b), let coverage = R(c) else { return nil }
            let area = AreaVolumeSolver.rectangleArea(width: width, height: height)
            let result = MaterialEstimator.paintContainers(area: area, coverageSquareFeetPerContainer: coverage)
            return MaterialLine(label: "material.paint".localized, exactQuantity: decimalString(result.exact),
                                 roundedQuantity: "\(result.roundedUp)", unit: "material.unit.containers".localized)
        case .decking:
            guard let coverageWidth = L(a), let boardWidth = L(b), let gap = L(c) else { return nil }
            let result = MaterialEstimator.deckingBoards(coverageWidth: coverageWidth, boardWidth: boardWidth, gap: gap)
            return MaterialLine(label: "material.decking".localized, exactQuantity: decimalString(result.exact),
                                 roundedQuantity: "\(result.roundedUp)", unit: "material.unit.boards".localized)
        case .roofing:
            guard let width = L(a), let height = L(b) else { return nil }
            let area = AreaVolumeSolver.rectangleArea(width: width, height: height)
            let result = MaterialEstimator.roofingSquares(area: area)
            return MaterialLine(label: "material.roofing".localized, exactQuantity: decimalString(result.exact),
                                 roundedQuantity: "\(result.roundedUp)", unit: "material.unit.squares".localized)
        }
    }

    var body: some View {
        Form {
            Section("material.category") {
                Picker("material.category", selection: $category) {
                    ForEach(MaterialCategory.allCases) { c in
                        Text(LocalizedStringKey("material.category.\(c.rawValue)")).tag(c)
                    }
                }
                .accessibilityIdentifier("material.categoryPicker")
            }

            Section("material.inputs") {
                Text(LocalizedStringKey("material.hint.\(category.rawValue)"))
                    .font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("material.hint")
                TextField("material.field.a", text: $a).keyboardType(.decimalPad)
                    .accessibilityIdentifier("material.field.a")
                TextField("material.field.b", text: $b).keyboardType(.decimalPad)
                    .accessibilityIdentifier("material.field.b")
                TextField("material.field.c", text: $c).keyboardType(.decimalPad)
                    .accessibilityIdentifier("material.field.c")
                Text("material.statement.noMoney").font(.footnote).foregroundStyle(.secondary)
            }

            if let currentLine {
                Section("material.result") {
                    materialRow(currentLine)
                    Button("material.addToList") { draftLines.append(currentLine) }
                        .accessibilityIdentifier("material.addToList")
                }
            }

            if !draftLines.isEmpty {
                Section("material.list") {
                    ForEach(draftLines) { line in materialRow(line) }
                        .onDelete { offsets in draftLines.remove(atOffsets: offsets) }
                    Button("solver.saveToJob") { showingSaveSheet = true }
                        .accessibilityIdentifier("material.saveToJob")
                }
            }
        }
        .navigationTitle("solvers.materials")
        .sheet(isPresented: $showingSaveSheet) {
            let saved = SavedMaterialList(title: "solvers.materials".localized, lines: draftLines)
            SaveResultSheet(onSaveNew: { name in
                let job = SiteJob(name: name, materialLists: [saved])
                context.insert(job)
            }, onSaveExisting: { job in
                job.materialLists.append(saved)
            })
        }
    }

    private func materialRow(_ line: MaterialLine) -> some View {
        HStack {
            Text(line.label)
            Spacer()
            Text(verbatim: "\(line.exactQuantity) / \(line.roundedQuantity) \(line.unit)")
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("material.line.\(line.label)")
    }

    private func decimalString(_ value: Rational) -> String {
        LengthFormatting.decimalString(value, decimalPlaces: 2)
    }
}
