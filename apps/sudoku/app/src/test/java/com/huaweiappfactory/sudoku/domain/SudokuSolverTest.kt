package com.huaweiappfactory.sudoku.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

class SudokuSolverTest {

    /** The classic reference puzzle, with the single solution it is known to have. */
    private val knownPuzzle = board(
        "530070000" +
            "600195000" +
            "098000060" +
            "800060003" +
            "400803001" +
            "700020006" +
            "060000280" +
            "000419005" +
            "000080079"
    )

    private val knownSolution = board(
        "534678912" +
            "672195348" +
            "198342567" +
            "859761423" +
            "426853791" +
            "713924856" +
            "961537284" +
            "287419635" +
            "345286179"
    )

    @Test
    fun `solves a known hard puzzle to the known solution`() {
        val solved = SudokuSolver.solve(knownPuzzle)
        assertNotNull(solved)
        assertArrayEquals(knownSolution, solved!!)
    }

    @Test
    fun `the known puzzle has exactly one solution`() {
        assertEquals(1, SudokuSolver.countSolutions(knownPuzzle, limit = 2))
        assertTrue(SudokuSolver.hasUniqueSolution(knownPuzzle))
    }

    @Test
    fun `the reference solution is a valid grid`() {
        assertTrue(SudokuBoard.isValidSolution(knownSolution))
    }

    @Test
    fun `a board with a deadly rectangle has two solutions`() {
        // Two rows in the same band and two columns in different stacks, holding
        // a,b / b,a: blanking those four cells makes both fillings legal.
        val ambiguous = knownSolution.copyOf()
        val rectangle = findDeadlyRectangle(knownSolution)
        assertNotNull("the reference solution should contain such a rectangle", rectangle)
        rectangle!!.forEach { ambiguous[it] = 0 }

        assertEquals(2, SudokuSolver.countSolutions(ambiguous, limit = 2))
        assertFalse(SudokuSolver.hasUniqueSolution(ambiguous))
    }

    @Test
    fun `a contradictory board has no solution`() {
        val broken = knownPuzzle.copyOf()
        // 5 is already the first cell of row 0, so a second 5 in the same row is illegal.
        broken[SudokuBoard.indexOf(0, 2)] = 5
        assertEquals(0, SudokuSolver.countSolutions(broken))
        assertNull(SudokuSolver.solve(broken))
    }

    @Test
    fun `generated solutions are valid and vary with the seed`() {
        val first = SudokuSolver.generateSolution(Random(11))
        val second = SudokuSolver.generateSolution(Random(12))
        assertTrue(SudokuBoard.isValidSolution(first))
        assertTrue(SudokuBoard.isValidSolution(second))
        assertFalse("two seeds should not produce the same grid", first.contentEquals(second))
    }

    @Test
    fun `the same seed produces the same solution`() {
        assertArrayEquals(SudokuSolver.generateSolution(Random(7)), SudokuSolver.generateSolution(Random(7)))
    }

    private fun findDeadlyRectangle(grid: IntArray): List<Int>? {
        for (band in 0 until 3) {
            val rows = (band * 3 until band * 3 + 3).toList()
            for (i in rows.indices) {
                for (j in i + 1 until rows.size) {
                    val r1 = rows[i]
                    val r2 = rows[j]
                    for (c1 in 0 until 9) {
                        for (c2 in 0 until 9) {
                            if (c1 / 3 == c2 / 3) continue // must span two boxes
                            val a = grid[SudokuBoard.indexOf(r1, c1)]
                            val b = grid[SudokuBoard.indexOf(r1, c2)]
                            if (grid[SudokuBoard.indexOf(r2, c1)] != b) continue
                            if (grid[SudokuBoard.indexOf(r2, c2)] != a) continue
                            return listOf(
                                SudokuBoard.indexOf(r1, c1),
                                SudokuBoard.indexOf(r1, c2),
                                SudokuBoard.indexOf(r2, c1),
                                SudokuBoard.indexOf(r2, c2)
                            )
                        }
                    }
                }
            }
        }
        return null
    }

    private fun board(text: String): IntArray = requireNotNull(SudokuBoard.fromStorage(text))

    private fun assertArrayEquals(expected: IntArray, actual: IntArray) =
        assertEquals(SudokuBoard.toStorage(expected), SudokuBoard.toStorage(actual))
}
