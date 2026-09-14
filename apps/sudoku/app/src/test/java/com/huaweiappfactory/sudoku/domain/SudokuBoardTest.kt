package com.huaweiappfactory.sudoku.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SudokuBoardTest {

    private val solution = requireNotNull(
        SudokuBoard.fromStorage(
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
    )

    @Test
    fun `peers are the twenty cells sharing a row, column or box`() {
        val peers = SudokuBoard.peersOf(SudokuBoard.indexOf(4, 4))
        assertEquals(20, peers.size)
        assertFalse(peers.contains(SudokuBoard.indexOf(4, 4)))
        assertTrue(peers.contains(SudokuBoard.indexOf(4, 0)))
        assertTrue(peers.contains(SudokuBoard.indexOf(0, 4)))
        assertTrue(peers.contains(SudokuBoard.indexOf(3, 3)))
        assertFalse(peers.contains(SudokuBoard.indexOf(0, 0)))
    }

    @Test
    fun `a complete valid grid has no conflicts`() {
        assertTrue(SudokuBoard.isValidSolution(solution))
        assertTrue(SudokuBoard.conflicts(solution).isEmpty())
        assertTrue(SudokuBoard.isComplete(solution))
    }

    @Test
    fun `duplicates are reported in rows, columns and boxes`() {
        val rowClash = solution.copyOf()
        rowClash[SudokuBoard.indexOf(0, 1)] = rowClash[SudokuBoard.indexOf(0, 0)]
        assertTrue(SudokuBoard.conflicts(rowClash).contains(SudokuBoard.indexOf(0, 1)))

        val colClash = solution.copyOf()
        colClash[SudokuBoard.indexOf(5, 0)] = colClash[SudokuBoard.indexOf(0, 0)]
        assertTrue(SudokuBoard.conflicts(colClash).contains(SudokuBoard.indexOf(5, 0)))

        val boxClash = solution.copyOf()
        boxClash[SudokuBoard.indexOf(1, 1)] = boxClash[SudokuBoard.indexOf(0, 0)]
        assertTrue(SudokuBoard.conflicts(boxClash).contains(SudokuBoard.indexOf(1, 1)))
    }

    @Test
    fun `empty cells never conflict`() {
        val holes = IntArray(SudokuBoard.CELLS)
        assertTrue(SudokuBoard.conflicts(holes).isEmpty())
        assertFalse(SudokuBoard.isComplete(holes))
        assertFalse(SudokuBoard.isValidSolution(holes))
    }

    @Test
    fun `a board survives a storage round trip`() {
        val text = SudokuBoard.toStorage(solution)
        assertEquals(81, text.length)
        assertEquals(SudokuBoard.toStorage(solution), SudokuBoard.toStorage(requireNotNull(SudokuBoard.fromStorage(text))))
    }

    @Test
    fun `malformed storage is rejected instead of guessed`() {
        assertNull(SudokuBoard.fromStorage(null))
        assertNull(SudokuBoard.fromStorage(""))
        assertNull(SudokuBoard.fromStorage("12345"))
        assertNull(SudokuBoard.fromStorage("x".repeat(81)))
    }

    @Test
    fun `notes survive a storage round trip`() {
        val notes = IntArray(SudokuBoard.CELLS)
        notes[0] = SudokuBoard.noteBit(1) or SudokuBoard.noteBit(9)
        notes[80] = SudokuBoard.noteBit(5)
        val restored = requireNotNull(SudokuBoard.notesFromStorage(SudokuBoard.notesToStorage(notes)))
        assertTrue(SudokuBoard.hasNote(restored[0], 1))
        assertTrue(SudokuBoard.hasNote(restored[0], 9))
        assertFalse(SudokuBoard.hasNote(restored[0], 5))
        assertTrue(SudokuBoard.hasNote(restored[80], 5))
    }

    @Test
    fun `malformed notes are rejected`() {
        assertNull(SudokuBoard.notesFromStorage(null))
        assertNull(SudokuBoard.notesFromStorage("1,2,3"))
        assertNull(SudokuBoard.notesFromStorage(List(81) { "999999" }.joinToString(",")))
    }

    @Test
    fun `canPlace refuses a value already held by a peer`() {
        val partial = IntArray(SudokuBoard.CELLS)
        partial[SudokuBoard.indexOf(0, 0)] = 7
        assertFalse(SudokuBoard.canPlace(partial, SudokuBoard.indexOf(0, 5), 7))
        assertFalse(SudokuBoard.canPlace(partial, SudokuBoard.indexOf(5, 0), 7))
        assertFalse(SudokuBoard.canPlace(partial, SudokuBoard.indexOf(1, 1), 7))
        assertTrue(SudokuBoard.canPlace(partial, SudokuBoard.indexOf(5, 5), 7))
    }
}
