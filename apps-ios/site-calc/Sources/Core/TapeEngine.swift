import Foundation

/// The operator that carried a tape line's entry into the running result.
/// The first line of a tape has no operator: it simply starts the total.
enum TapeOperator: String, Codable, CaseIterable {
    case add, subtract, multiply, divide, onCentre
}

/// One line of the tape (F002): the value as entered, the operator that
/// combined it with the running result above it, an optional label, and the
/// recomputed running result. `runningResult` and `onCentreResult` are always
/// derived by `TapeEngine.recompute` -- nothing on the tape is ever computed
/// twice by two different code paths.
struct TapeLine: Identifiable, Equatable, Codable {
    let id: UUID
    var operatorApplied: TapeOperator?
    var operand: Quantity
    var label: String
    var runningResult: Quantity?
    var onCentreResult: OnCentreResultSnapshot?
    /// Set when a correction to this or an earlier line broke the chain here.
    var failed: Bool

    init(id: UUID = UUID(), operatorApplied: TapeOperator?, operand: Quantity, label: String = "") {
        self.id = id
        self.operatorApplied = operatorApplied
        self.operand = operand
        self.label = label
        self.runningResult = nil
        self.onCentreResult = nil
        self.failed = false
    }
}

/// A Codable snapshot of an on-centre result (OnCentreCalculator.Result itself
/// is not Codable, since it is a plain computation output, not tape state).
struct OnCentreResultSnapshot: Equatable, Codable {
    let exactSpaces: Rational
    let spaces: Int
    let pieces: Int
    let remainder: Length

    init(_ result: OnCentreCalculator.Result) {
        exactSpaces = result.exactSpaces
        spaces = result.spaces
        pieces = result.pieces
        remainder = result.remainder
    }
}

/// Recomputes a tape top to bottom. Every line below a correction recomputes
/// -- this function is the entire implementation of that behaviour, called
/// after any edit so there is exactly one recompute path for the whole tape.
enum TapeEngine {
    static func recompute(_ lines: [TapeLine]) -> [TapeLine] {
        var out: [TapeLine] = []
        var result: Quantity?
        var broken = false

        for (index, original) in lines.enumerated() {
            var line = original
            if index == 0 {
                result = line.operand
                line.runningResult = result
                line.onCentreResult = nil
                line.failed = false
            } else if broken {
                line.runningResult = nil
                line.onCentreResult = nil
                line.failed = true
            } else if let current = result, let op = line.operatorApplied {
                do {
                    if op == .onCentre {
                        guard case .length(let total) = current, case .length(let spacing) = line.operand else {
                            throw Quantity.ArithmeticError.incompatibleOperands
                        }
                        guard !spacing.inches.isZero else { throw Quantity.ArithmeticError.divisionByZero }
                        let ocResult = OnCentreCalculator.compute(total: total, spacing: spacing)
                        line.onCentreResult = OnCentreResultSnapshot(ocResult)
                        result = .count(ocResult.exactSpaces)
                        line.runningResult = result
                        line.failed = false
                    } else {
                        let next: Quantity
                        switch op {
                        case .add: next = try Quantity.add(current, line.operand)
                        case .subtract: next = try Quantity.subtract(current, line.operand)
                        case .multiply: next = try Quantity.multiply(current, line.operand)
                        case .divide: next = try Quantity.divide(current, line.operand)
                        case .onCentre: fatalError("handled above")
                        }
                        result = next
                        line.runningResult = next
                        line.onCentreResult = nil
                        line.failed = false
                    }
                } catch {
                    line.runningResult = nil
                    line.onCentreResult = nil
                    line.failed = true
                    broken = true
                    result = nil
                }
            } else {
                line.runningResult = nil
                line.failed = true
                broken = true
            }
            out.append(line)
        }
        return out
    }
}
