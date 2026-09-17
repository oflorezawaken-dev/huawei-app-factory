import Foundation

/// A labelled value inside a saved solver result or material list -- the
/// building block export walks over so it never has to know each solver's
/// internal shape.
struct LabeledQuantity: Equatable, Codable, Identifiable {
    var id: String { label }
    let label: String
    let quantity: Quantity
}

/// A solver result saved into a job (F004/F005/F006), carrying the "from what
/// you entered" restatement alongside its values so the record is never just
/// a bare number with no history behind it.
struct SavedSolverResult: Identifiable, Equatable, Codable {
    enum Kind: String, Codable { case roof, stair, areaVolume }

    let id: UUID
    let kind: Kind
    let title: String
    let inputsSummary: String
    let values: [LabeledQuantity]
    let createdAt: Date

    init(id: UUID = UUID(), kind: Kind, title: String, inputsSummary: String,
         values: [LabeledQuantity], createdAt: Date = .now) {
        self.id = id
        self.kind = kind
        self.title = title
        self.inputsSummary = inputsSummary
        self.values = values
        self.createdAt = createdAt
    }
}

/// One line of a saved material estimate: a label, the exact quantity and the
/// rounded-up purchasable count side by side (F007), and the unit -- never a
/// currency, a rate or a total.
struct MaterialLine: Equatable, Codable, Identifiable {
    var id: String { label }
    let label: String
    let exactQuantity: String
    let roundedQuantity: String
    let unit: String
}

struct SavedMaterialList: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let lines: [MaterialLine]
    let createdAt: Date

    init(id: UUID = UUID(), title: String, lines: [MaterialLine], createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.lines = lines
        self.createdAt = createdAt
    }
}
