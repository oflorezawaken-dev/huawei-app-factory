package com.huaweiappfactory.sudoku.domain

/**
 * One puzzle in progress. Plain Kotlin with no Android dependency, so every rule in
 * the specification is unit-testable: givens are immutable, entering a value clears
 * that cell's notes, a wrong entry counts as one mistake, and undo restores the board
 * together with the mistake and hint counters.
 */
class SudokuGame(
    val difficulty: Difficulty,
    givens: IntArray,
    solution: IntArray,
    entries: IntArray = givens.copyOf(),
    notes: IntArray = IntArray(SudokuBoard.CELLS),
    mistakes: Int = 0,
    hintsUsed: Int = 0,
    elapsedSeconds: Int = 0
) {

    val givens: IntArray = givens.copyOf()
    val solution: IntArray = solution.copyOf()

    private val cells: IntArray = entries.copyOf()
    private val pencil: IntArray = notes.copyOf()
    private val history = ArrayDeque<Change>()

    var mistakes: Int = mistakes
        private set
    var hintsUsed: Int = hintsUsed
        private set
    var elapsedSeconds: Int = elapsedSeconds

    val hintsLeft: Int get() = (HINTS_PER_PUZZLE - hintsUsed).coerceAtLeast(0)
    val canUndo: Boolean get() = history.isNotEmpty()

    fun entries(): IntArray = cells.copyOf()
    fun notes(): IntArray = pencil.copyOf()

    fun valueAt(index: Int): Int = cells[index]
    fun notesAt(index: Int): Int = pencil[index]
    fun isGiven(index: Int): Boolean = givens[index] != 0
    fun isEditable(index: Int): Boolean = !isGiven(index)

    /** Cells whose value repeats in their row, column or box. */
    fun conflicts(): Set<Int> = SudokuBoard.conflicts(cells)

    /** How many of [value] are still missing from the board (0 means the digit is done). */
    fun remaining(value: Int): Int = (SudokuBoard.SIZE - SudokuBoard.countOf(cells, value)).coerceAtLeast(0)

    fun isSolved(): Boolean = cells.contentEquals(solution)

    /** True once [mistakes] reaches the limit; only meaningful when the player enabled it. */
    fun isOutOfMistakes(): Boolean = mistakes >= MISTAKE_LIMIT

    fun progress(): Float {
        val editable = cells.indices.count { isEditable(it) }
        if (editable == 0) return 1f
        val filled = cells.indices.count { isEditable(it) && cells[it] != 0 }
        return filled.toFloat() / editable
    }

    /**
     * Writes [value] into [index]. Returns the result so the caller can react
     * (mistake feedback, win screen) without re-deriving state.
     */
    fun setValue(index: Int, value: Int): MoveResult {
        if (!isEditable(index) || value !in 1..9) return MoveResult.REJECTED
        if (cells[index] == value) return MoveResult.NO_CHANGE
        record(index)
        cells[index] = value
        pencil[index] = 0
        val correct = solution[index] == value
        if (!correct) mistakes++
        return when {
            !correct -> MoveResult.WRONG
            isSolved() -> MoveResult.SOLVED
            else -> MoveResult.CORRECT
        }
    }

    /** Adds or removes the pencil mark for [value]. Ignored on a cell that holds a value. */
    fun toggleNote(index: Int, value: Int): MoveResult {
        if (!isEditable(index) || value !in 1..9) return MoveResult.REJECTED
        if (cells[index] != 0) return MoveResult.REJECTED
        record(index)
        pencil[index] = pencil[index] xor SudokuBoard.noteBit(value)
        return MoveResult.NOTE
    }

    /** Clears the value and the notes of [index]. */
    fun erase(index: Int): MoveResult {
        if (!isEditable(index)) return MoveResult.REJECTED
        if (cells[index] == 0 && pencil[index] == 0) return MoveResult.NO_CHANGE
        record(index)
        cells[index] = 0
        pencil[index] = 0
        return MoveResult.CORRECT
    }

    /**
     * Fills [index] (or, when it is null or not editable, a random empty editable cell)
     * with its solution value. A hint never counts as a mistake.
     */
    fun hint(index: Int? = null): MoveResult {
        if (hintsLeft <= 0) return MoveResult.REJECTED
        val target = when {
            index != null && isEditable(index) && cells[index] != solution[index] -> index
            else -> cells.indices.firstOrNull { isEditable(it) && cells[it] != solution[it] }
        } ?: return MoveResult.REJECTED
        record(target)
        cells[target] = solution[target]
        pencil[target] = 0
        hintsUsed++
        return if (isSolved()) MoveResult.SOLVED else MoveResult.HINT
    }

    /** Reverses the last change, including the mistake and hint counters. */
    fun undo(): Boolean {
        val change = history.removeLastOrNull() ?: return false
        cells[change.index] = change.value
        pencil[change.index] = change.notes
        mistakes = change.mistakes
        hintsUsed = change.hintsUsed
        return true
    }

    private fun record(index: Int) {
        if (history.size >= MAX_HISTORY) history.removeFirst()
        history.addLast(Change(index, cells[index], pencil[index], mistakes, hintsUsed))
    }

    private data class Change(
        val index: Int,
        val value: Int,
        val notes: Int,
        val mistakes: Int,
        val hintsUsed: Int
    )

    companion object {
        const val HINTS_PER_PUZZLE = 3
        const val MISTAKE_LIMIT = 3
        private const val MAX_HISTORY = 300

        fun from(puzzle: Puzzle): SudokuGame =
            SudokuGame(puzzle.difficulty, puzzle.givens, puzzle.solution)
    }
}

enum class MoveResult {
    /** The move was not allowed (given cell, no hints left, note on a filled cell). */
    REJECTED,

    /** Nothing changed, so nothing was recorded for undo. */
    NO_CHANGE,

    /** A correct value, or an erase. */
    CORRECT,

    /** A value that contradicts the solution; the mistake counter went up. */
    WRONG,

    /** A pencil mark was toggled. */
    NOTE,

    /** A hint filled a cell. */
    HINT,

    /** The board now matches the solution. */
    SOLVED
}
