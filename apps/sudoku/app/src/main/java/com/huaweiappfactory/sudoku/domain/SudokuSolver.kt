package com.huaweiappfactory.sudoku.domain

import kotlin.random.Random

/**
 * Backtracking solver with the minimum-remaining-values heuristic: it always
 * branches on the empty cell with the fewest candidates, which is what keeps
 * uniqueness checking fast enough to run 81 times per generated puzzle on a phone.
 *
 * Candidates are held as 9-bit masks, one per cell, so a placement costs 20 bit
 * operations instead of a rescan.
 */
object SudokuSolver {

    private const val ALL = 0x1FF // bits 0..8 = digits 1..9

    /** Returns a solved copy of [board], or null when it has no solution. */
    fun solve(board: IntArray, random: Random? = null): IntArray? {
        val work = board.copyOf()
        val candidates = candidatesOf(work) ?: return null
        return if (search(work, candidates, random, countOnly = false, limit = 1) > 0) work else null
    }

    /**
     * Counts solutions, stopping at [limit]. `1` means the puzzle is well posed;
     * `2` means it is ambiguous and must not be given to a player.
     */
    fun countSolutions(board: IntArray, limit: Int = 2): Int {
        val work = board.copyOf()
        val candidates = candidatesOf(work) ?: return 0
        return search(work, candidates, random = null, countOnly = true, limit = limit)
    }

    fun hasUniqueSolution(board: IntArray): Boolean = countSolutions(board, limit = 2) == 1

    /** Builds a complete, valid grid. Seed the [random] to make generation reproducible. */
    fun generateSolution(random: Random): IntArray {
        val board = IntArray(SudokuBoard.CELLS)
        val candidates = IntArray(SudokuBoard.CELLS) { ALL }
        check(search(board, candidates, random, countOnly = false, limit = 1) > 0) {
            "an empty grid always has a solution"
        }
        return board
    }

    /** Per-cell candidate masks for a partially filled board; null when it already contradicts itself. */
    private fun candidatesOf(board: IntArray): IntArray? {
        val candidates = IntArray(SudokuBoard.CELLS) { ALL }
        for (index in 0 until SudokuBoard.CELLS) {
            val value = board[index]
            if (value == 0) continue
            val bit = 1 shl (value - 1)
            if (candidates[index] and bit == 0) return null
            for (peer in SudokuBoard.peersOf(index)) {
                if (board[peer] == value) return null
                candidates[peer] = candidates[peer] and bit.inv()
            }
        }
        return candidates
    }

    /**
     * Depth-first search over [board]. Returns how many solutions were found, capped
     * at [limit]. When [countOnly] is false the board is left holding the first one.
     */
    private fun search(
        board: IntArray,
        candidates: IntArray,
        random: Random?,
        countOnly: Boolean,
        limit: Int
    ): Int {
        var best = -1
        var bestCount = 10
        for (index in 0 until SudokuBoard.CELLS) {
            if (board[index] != 0) continue
            val count = Integer.bitCount(candidates[index])
            if (count == 0) return 0
            if (count < bestCount) {
                bestCount = count
                best = index
                if (count == 1) break
            }
        }
        if (best == -1) return 1 // every cell filled

        val values = digitsOf(candidates[best]).let { if (random != null) it.shuffled(random) else it }
        var found = 0
        for (value in values) {
            val touched = place(board, candidates, best, value)
            val sub = search(board, candidates, random, countOnly, limit - found)
            if (sub > 0 && !countOnly) {
                return found + sub // keep the filled board
            }
            found += sub
            undo(board, candidates, best, value, touched)
            if (found >= limit) return found
        }
        return found
    }

    /** Writes [value] and removes it from every peer's candidates; returns the peers it changed. */
    private fun place(board: IntArray, candidates: IntArray, index: Int, value: Int): IntArray {
        val bit = 1 shl (value - 1)
        board[index] = value
        val touched = ArrayList<Int>(20)
        for (peer in SudokuBoard.peersOf(index)) {
            if (candidates[peer] and bit != 0) {
                candidates[peer] = candidates[peer] and bit.inv()
                touched += peer
            }
        }
        return touched.toIntArray()
    }

    private fun undo(board: IntArray, candidates: IntArray, index: Int, value: Int, touched: IntArray) {
        val bit = 1 shl (value - 1)
        board[index] = 0
        for (peer in touched) candidates[peer] = candidates[peer] or bit
    }

    private fun digitsOf(mask: Int): List<Int> {
        val digits = ArrayList<Int>(9)
        for (d in 1..9) if (mask and (1 shl (d - 1)) != 0) digits += d
        return digits
    }
}
