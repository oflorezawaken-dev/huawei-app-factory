package com.huaweiappfactory.sudoku.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.random.Random

/**
 * The generator is the one part of the app a player can never work around: a puzzle
 * with two solutions is unsolvable by deduction and looks like a bug. These tests run
 * every difficulty with fixed seeds so a regression is reproducible.
 */
class SudokuGeneratorTest {

    private val seeds = listOf(1, 2, 3)

    @Test
    fun `every generated puzzle has exactly one solution`() {
        forEachPuzzle { puzzle ->
            assertEquals(
                "puzzle for ${puzzle.difficulty} is ambiguous",
                1,
                SudokuSolver.countSolutions(puzzle.givens, limit = 2)
            )
        }
    }

    @Test
    fun `the clue count stays inside the difficulty range`() {
        forEachPuzzle { puzzle ->
            val count = puzzle.givenCount
            val difficulty = puzzle.difficulty
            assertTrue(
                "$difficulty produced $count clues, outside ${difficulty.minGivens}..${difficulty.maxGivens}",
                count in difficulty.minGivens..difficulty.maxGivens
            )
        }
    }

    @Test
    fun `the stated solution really solves the puzzle`() {
        forEachPuzzle { puzzle ->
            assertTrue(SudokuBoard.isValidSolution(puzzle.solution))
            val solved = SudokuSolver.solve(puzzle.givens)
            assertEquals(
                SudokuBoard.toStorage(puzzle.solution),
                SudokuBoard.toStorage(requireNotNull(solved))
            )
        }
    }

    @Test
    fun `every clue matches the solution`() {
        forEachPuzzle { puzzle ->
            for (index in 0 until SudokuBoard.CELLS) {
                val clue = puzzle.givens[index]
                if (clue != 0) {
                    assertEquals("clue at $index contradicts the solution", puzzle.solution[index], clue)
                }
            }
        }
    }

    @Test
    fun `harder difficulties never give away more clues than easier ones`() {
        val counts = Difficulty.entries.map { SudokuGenerator.generate(it, Random(42)).givenCount }
        for (i in 1 until counts.size) {
            assertTrue(
                "clue counts should not increase with difficulty: $counts",
                counts[i] <= counts[i - 1]
            )
        }
    }

    @Test
    fun `the same seed produces the same puzzle`() {
        val first = SudokuGenerator.generate(Difficulty.HARD, Random(99))
        val second = SudokuGenerator.generate(Difficulty.HARD, Random(99))
        assertEquals(first, second)
    }

    private fun forEachPuzzle(check: (Puzzle) -> Unit) {
        for (difficulty in Difficulty.entries) {
            for (seed in seeds) {
                check(SudokuGenerator.generate(difficulty, Random(seed)))
            }
        }
    }
}
