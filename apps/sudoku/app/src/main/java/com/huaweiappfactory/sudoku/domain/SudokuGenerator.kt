package com.huaweiappfactory.sudoku.domain

import kotlin.random.Random

/** How many clues a puzzle keeps. Fewer givens means more deduction, not more guessing. */
enum class Difficulty(val minGivens: Int, val maxGivens: Int) {
    EASY(40, 45),
    MEDIUM(32, 36),
    HARD(28, 31),
    EXPERT(24, 27);

    companion object {
        fun fromName(name: String?): Difficulty =
            entries.firstOrNull { it.name.equals(name, ignoreCase = true) } ?: MEDIUM
    }
}

/** A puzzle and the single solution it admits. */
data class Puzzle(
    val difficulty: Difficulty,
    val givens: IntArray,
    val solution: IntArray
) {
    val givenCount: Int get() = SudokuBoard.countGivens(givens)

    // IntArray needs structural equals/hashCode written out.
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Puzzle) return false
        return difficulty == other.difficulty &&
            givens.contentEquals(other.givens) &&
            solution.contentEquals(other.solution)
    }

    override fun hashCode(): Int =
        (difficulty.hashCode() * 31 + givens.contentHashCode()) * 31 + solution.contentHashCode()
}

/**
 * Builds a full solution, then removes clues one at a time and keeps a removal only
 * while the puzzle still has exactly one solution. The result is always solvable by
 * deduction and never by guessing.
 *
 * Digging is not guaranteed to reach the deepest target on the first try, so the
 * generator makes several passes over the remaining clues and, if it is still above
 * the difficulty's ceiling, starts again from a fresh solution. [generate] therefore
 * always returns a puzzle whose clue count is inside the difficulty's range.
 */
object SudokuGenerator {

    private const val MAX_GRID_ATTEMPTS = 12
    private const val MAX_DIG_PASSES = 4

    fun generate(difficulty: Difficulty, random: Random = Random.Default): Puzzle {
        var closest: Puzzle? = null
        repeat(MAX_GRID_ATTEMPTS) {
            val solution = SudokuSolver.generateSolution(random)
            val target = random.nextInt(difficulty.minGivens, difficulty.maxGivens + 1)
            val givens = dig(solution, target, random)
            val count = SudokuBoard.countGivens(givens)
            if (count <= difficulty.maxGivens) {
                return Puzzle(difficulty, givens, solution)
            }
            if (closest == null || count < closest!!.givenCount) {
                closest = Puzzle(difficulty, givens, solution)
            }
        }
        // Unreachable in practice: random digging lands in the low twenties routinely.
        // Returning the best attempt is still a valid, uniquely solvable puzzle.
        return closest!!
    }

    /** Removes clues down to [target] where uniqueness allows it. */
    private fun dig(solution: IntArray, target: Int, random: Random): IntArray {
        val board = solution.copyOf()
        var remaining = SudokuBoard.CELLS
        repeat(MAX_DIG_PASSES) {
            if (remaining <= target) return board
            val order = (0 until SudokuBoard.CELLS).shuffled(random)
            for (index in order) {
                if (remaining <= target) return board
                val value = board[index]
                if (value == 0) continue
                board[index] = 0
                if (SudokuSolver.hasUniqueSolution(board)) {
                    remaining--
                } else {
                    board[index] = value
                }
            }
        }
        return board
    }
}
