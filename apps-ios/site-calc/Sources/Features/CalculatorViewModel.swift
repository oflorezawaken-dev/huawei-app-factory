import Foundation
import SwiftData

/// Drives the calculator screen (S001): the pending entry, the tape, and the
/// running result. All arithmetic goes through `Quantity`/`TapeEngine`; this
/// class only wires keypad taps to those pure functions and republishes the
/// result for the view.
@Observable
final class CalculatorViewModel {
    private(set) var entry = EntryBuilder()
    private(set) var lines: [TapeLine] = []
    private(set) var pendingOperator: TapeOperator?
    var errorMessage: String?

    let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    var runningResult: Quantity? { lines.last?.runningResult }

    var runningResultText: String {
        guard let result = runningResult else { return "0" }
        return QuantityFormatting.display(result, precision: settings.fractionPrecision,
                                           system: settings.preferredSystem, metricUnit: settings.preferredMetricUnit)
    }

    // MARK: Keypad

    func digit(_ value: Int) { entry.digit(value) }
    func decimalPoint() { entry.decimalPoint() }
    func backspace() { entry.backspace() }
    func fractionSlash() { entry.fractionSlash() }
    func percent() { entry.percent() }
    func commitFeet() { entry.commitFeet() }
    func commitInches() { entry.commitInches() }

    func unit(_ unit: LengthUnit) {
        // Feet and inches build a composite entry; the others are a complete
        // entry on their own (F003: "any entry can be typed in ... metres,
        // centimetres or millimetres").
        switch unit {
        case .feet: entry.commitFeet()
        case .inches: entry.commitInches()
        case .yard, .meter, .centimeter, .millimeter:
            if let quantity = entry.finalizeDirect(unit: unit) {
                appendOrStart(quantity)
                entry.clear()
            }
        }
    }

    func onCentreKey() {
        applyOperator(.onCentre)
    }

    func applyOperator(_ op: TapeOperator) {
        guard let quantity = entry.finalizeFeetInchFraction() ?? completedDirectEntry() else {
            // No new entry typed: just change the pending operator for the
            // next value (lets a user retype an operator without penalty).
            pendingOperator = op
            return
        }
        appendOrStart(quantity, op: pendingOperator ?? op)
        pendingOperator = op
        entry.clear()
    }

    func equals() {
        if let quantity = entry.finalizeFeetInchFraction() {
            appendOrStart(quantity, op: pendingOperator ?? .add)
            entry.clear()
        }
        pendingOperator = nil
    }

    func clearEntry() {
        entry.clear()
    }

    func clearTape() {
        lines = []
        entry.clear()
        pendingOperator = nil
        errorMessage = nil
    }

    private func completedDirectEntry() -> Quantity? { nil }

    /// Adds a value from outside the keypad -- a solver's "send to tape"
    /// button (S004-S007) -- as a new tape line, labelled with its origin.
    func appendExternal(_ quantity: Quantity, label: String) {
        var line = TapeLine(operatorApplied: lines.isEmpty ? nil : .add, operand: quantity, label: label)
        line.label = label
        lines.append(line)
        recompute()
    }

    private func appendOrStart(_ quantity: Quantity, op: TapeOperator? = nil) {
        let line: TapeLine
        if lines.isEmpty {
            line = TapeLine(operatorApplied: nil, operand: quantity)
        } else {
            line = TapeLine(operatorApplied: op ?? .add, operand: quantity)
        }
        lines.append(line)
        recompute()
    }

    private func recompute() {
        lines = TapeEngine.recompute(lines)
        errorMessage = (lines.last?.failed == true) ? "tape.error.incompatible" : nil
    }

    // MARK: Editing (S002)

    func label(_ text: String, forLineID id: UUID) {
        guard let index = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[index].label = text
    }

    func correct(lineID id: UUID, newOperator: TapeOperator?, newOperand: Quantity) {
        guard let index = lines.firstIndex(where: { $0.id == id }) else { return }
        lines[index].operatorApplied = newOperator
        lines[index].operand = newOperand
        recompute()
    }

    func deleteLine(_ id: UUID) {
        lines.removeAll { $0.id == id }
        recompute()
    }

    // MARK: Saving into a job

    func saveTape(intoNewJobNamed name: String, context: ModelContext) {
        let job = SiteJob(name: name, tapeLines: lines)
        context.insert(job)
    }

    func saveTape(into job: SiteJob) {
        job.tapeLines = lines
    }

    func loadTape(from job: SiteJob) {
        lines = job.tapeLines
    }
}
