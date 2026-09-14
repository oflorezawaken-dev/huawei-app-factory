package com.huaweiappfactory.sudoku.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import kotlin.random.Random

class SudokuGameTest {

    private lateinit var puzzle: Puzzle
    private lateinit var game: SudokuGame
    private var firstEmpty: Int = -1

    @Before
    fun setUp() {
        puzzle = SudokuGenerator.generate(Difficulty.EASY, Random(5))
        game = SudokuGame.from(puzzle)
        firstEmpty = (0 until SudokuBoard.CELLS).first { puzzle.givens[it] == 0 }
    }

    @Test
    fun `a given cell can never be changed`() {
        val given = (0 until SudokuBoard.CELLS).first { puzzle.givens[it] != 0 }
        val before = game.valueAt(given)
        assertEquals(MoveResult.REJECTED, game.setValue(given, if (before == 1) 2 else 1))
        assertEquals(before, game.valueAt(given))
        assertFalse(game.canUndo)
    }

    @Test
    fun `a correct entry is accepted and counts no mistake`() {
        val correct = puzzle.solution[firstEmpty]
        assertEquals(MoveResult.CORRECT, game.setValue(firstEmpty, correct))
        assertEquals(correct, game.valueAt(firstEmpty))
        assertEquals(0, game.mistakes)
    }

    @Test
    fun `a wrong entry counts exactly one mistake`() {
        val wrong = wrongValueFor(firstEmpty)
        assertEquals(MoveResult.WRONG, game.setValue(firstEmpty, wrong))
        assertEquals(1, game.mistakes)
        // Re-entering the same wrong value changes nothing and must not count twice.
        assertEquals(MoveResult.NO_CHANGE, game.setValue(firstEmpty, wrong))
        assertEquals(1, game.mistakes)
    }

    @Test
    fun `entering a value clears that cell's notes`() {
        game.toggleNote(firstEmpty, 4)
        game.toggleNote(firstEmpty, 7)
        assertTrue(SudokuBoard.hasNote(game.notesAt(firstEmpty), 4))
        game.setValue(firstEmpty, puzzle.solution[firstEmpty])
        assertEquals(0, game.notesAt(firstEmpty))
    }

    @Test
    fun `notes toggle on and off and are refused on a filled cell`() {
        assertEquals(MoveResult.NOTE, game.toggleNote(firstEmpty, 3))
        assertTrue(SudokuBoard.hasNote(game.notesAt(firstEmpty), 3))
        assertEquals(MoveResult.NOTE, game.toggleNote(firstEmpty, 3))
        assertFalse(SudokuBoard.hasNote(game.notesAt(firstEmpty), 3))

        game.setValue(firstEmpty, puzzle.solution[firstEmpty])
        assertEquals(MoveResult.REJECTED, game.toggleNote(firstEmpty, 3))
    }

    @Test
    fun `erase clears the value and the notes`() {
        game.setValue(firstEmpty, puzzle.solution[firstEmpty])
        game.erase(firstEmpty)
        assertEquals(0, game.valueAt(firstEmpty))
        assertEquals(0, game.notesAt(firstEmpty))
    }

    @Test
    fun `undo restores the board, the notes and both counters`() {
        game.toggleNote(firstEmpty, 2)
        val notesBefore = game.notesAt(firstEmpty)

        game.setValue(firstEmpty, wrongValueFor(firstEmpty))
        assertEquals(1, game.mistakes)

        assertTrue(game.undo())
        assertEquals(0, game.valueAt(firstEmpty))
        assertEquals(notesBefore, game.notesAt(firstEmpty))
        assertEquals(0, game.mistakes)

        assertTrue(game.undo())
        assertEquals(0, game.notesAt(firstEmpty))
        assertFalse(game.canUndo)
        assertFalse(game.undo())
    }

    @Test
    fun `a hint fills a cell, costs no mistake and is capped`() {
        repeat(SudokuGame.HINTS_PER_PUZZLE) { assertEquals(MoveResult.HINT, game.hint()) }
        assertEquals(0, game.hintsLeft)
        assertEquals(0, game.mistakes)
        assertEquals(MoveResult.REJECTED, game.hint())
        assertEquals(SudokuGame.HINTS_PER_PUZZLE, game.hintsUsed)
    }

    @Test
    fun `a hint on the selected cell fills that cell`() {
        assertEquals(MoveResult.HINT, game.hint(firstEmpty))
        assertEquals(puzzle.solution[firstEmpty], game.valueAt(firstEmpty))
    }

    @Test
    fun `undoing a hint gives it back`() {
        game.hint(firstEmpty)
        assertEquals(SudokuGame.HINTS_PER_PUZZLE - 1, game.hintsLeft)
        game.undo()
        assertEquals(SudokuGame.HINTS_PER_PUZZLE, game.hintsLeft)
        assertEquals(0, game.valueAt(firstEmpty))
    }

    @Test
    fun `filling every cell correctly reports the puzzle as solved`() {
        var last: MoveResult = MoveResult.NO_CHANGE
        for (index in 0 until SudokuBoard.CELLS) {
            if (game.isEditable(index)) last = game.setValue(index, puzzle.solution[index])
        }
        assertEquals(MoveResult.SOLVED, last)
        assertTrue(game.isSolved())
        assertEquals(0, game.mistakes)
    }

    @Test
    fun `a duplicate in a row is reported as a conflict`() {
        val row = 0
        val empties = (0 until SudokuBoard.SIZE)
            .map { SudokuBoard.indexOf(row, it) }
            .filter { game.isEditable(it) }
        // Rows with fewer than two free cells cannot show this; EASY seed 5 has them.
        assertTrue("need two free cells in row $row", empties.size >= 2)
        game.setValue(empties[0], 5)
        game.setValue(empties[1], 5)
        val conflicts = game.conflicts()
        assertTrue(conflicts.contains(empties[0]))
        assertTrue(conflicts.contains(empties[1]))
    }

    @Test
    fun `remaining count falls as a digit is placed`() {
        val digit = puzzle.solution[firstEmpty]
        val before = game.remaining(digit)
        game.setValue(firstEmpty, digit)
        assertEquals(before - 1, game.remaining(digit))
    }

    @Test
    fun `the mistake limit is only reached after three wrong entries`() {
        val editable = (0 until SudokuBoard.CELLS).filter { game.isEditable(it) }
        repeat(SudokuGame.MISTAKE_LIMIT) { i ->
            val index = editable[i]
            game.setValue(index, wrongValueFor(index))
            assertEquals(i == SudokuGame.MISTAKE_LIMIT - 1, game.isOutOfMistakes())
        }
    }

    @Test
    fun `progress counts only the cells the player can fill`() {
        assertEquals(0f, game.progress(), 0.0001f)
        for (index in 0 until SudokuBoard.CELLS) {
            if (game.isEditable(index)) game.setValue(index, puzzle.solution[index])
        }
        assertEquals(1f, game.progress(), 0.0001f)
    }

    private fun wrongValueFor(index: Int): Int =
        (1..9).first { it != puzzle.solution[index] }
}
