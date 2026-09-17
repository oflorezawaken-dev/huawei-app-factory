import Foundation
import SwiftData

/// A named job (F008): a tape, any solver results saved into it, and its
/// material lists, in SwiftData on the device. The tape/solver/material
/// payloads are stored as JSON blobs rather than SwiftData relationships --
/// they are export-shaped data (walked linearly for CSV/PDF, never queried by
/// field), and this keeps the schema simple without making the persistence
/// any less real: every byte still round-trips through SwiftData on disk.
@Model
final class SiteJob {
    var name: String
    var note: String
    var createdAt: Date
    var updatedAt: Date
    var isSample: Bool

    private var tapeLinesData: Data
    private var solverResultsData: Data
    private var materialListsData: Data

    init(name: String, note: String = "", isSample: Bool = false,
         tapeLines: [TapeLine] = [], solverResults: [SavedSolverResult] = [],
         materialLists: [SavedMaterialList] = [], createdAt: Date = .now) {
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isSample = isSample
        self.tapeLinesData = (try? JSONEncoder().encode(tapeLines)) ?? Data()
        self.solverResultsData = (try? JSONEncoder().encode(solverResults)) ?? Data()
        self.materialListsData = (try? JSONEncoder().encode(materialLists)) ?? Data()
    }

    var tapeLines: [TapeLine] {
        get { (try? JSONDecoder().decode([TapeLine].self, from: tapeLinesData)) ?? [] }
        set {
            tapeLinesData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = .now
        }
    }

    var solverResults: [SavedSolverResult] {
        get { (try? JSONDecoder().decode([SavedSolverResult].self, from: solverResultsData)) ?? [] }
        set {
            solverResultsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = .now
        }
    }

    var materialLists: [SavedMaterialList] {
        get { (try? JSONDecoder().decode([SavedMaterialList].self, from: materialListsData)) ?? [] }
        set {
            materialListsData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = .now
        }
    }

    /// Shown on the Jobs list row (S008) and named in the delete confirmation.
    var lineCount: Int {
        tapeLines.count + solverResults.reduce(0) { $0 + $1.values.count }
            + materialLists.reduce(0) { $0 + $1.lines.count }
    }
}
