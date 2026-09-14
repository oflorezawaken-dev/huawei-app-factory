package com.huaweiappfactory.sudoku.domain

/**
 * Board conventions shared by the whole app.
 *
 * A board is an `IntArray(81)` in row-major order; `0` means empty and `1..9` are
 * the digits. Notes are a second `IntArray(81)` where bit `d - 1` is set when the
 * pencil mark for digit `d` is on.
 */
object SudokuBoard {

    const val SIZE = 9
    const val CELLS = SIZE * SIZE
    const val BOX = 3

    fun rowOf(index: Int) = index / SIZE
    fun colOf(index: Int) = index % SIZE
    fun boxOf(index: Int) = (rowOf(index) / BOX) * BOX + colOf(index) / BOX
    fun indexOf(row: Int, col: Int) = row * SIZE + col

    /** The 20 cells that share a row, column or box with [index]. */
    fun peersOf(index: Int): IntArray = PEERS[index]

    /** True when [value] can be written at [index] without duplicating a peer. */
    fun canPlace(board: IntArray, index: Int, value: Int): Boolean {
        for (peer in PEERS[index]) {
            if (board[peer] == value) return false
        }
        return true
    }

    /** Indexes whose value repeats in their row, column or box. Empty cells never conflict. */
    fun conflicts(board: IntArray): Set<Int> {
        val result = mutableSetOf<Int>()
        for (i in 0 until CELLS) {
            val value = board[i]
            if (value == 0) continue
            for (peer in PEERS[i]) {
                if (board[peer] == value) {
                    result += i
                    result += peer
                }
            }
        }
        return result
    }

    /** True when every row, column and box holds 1..9 exactly once. */
    fun isValidSolution(board: IntArray): Boolean {
        if (board.size != CELLS) return false
        for (unit in UNITS) {
            var seen = 0
            for (index in unit) {
                val value = board[index]
                if (value !in 1..9) return false
                val bit = 1 shl (value - 1)
                if (seen and bit != 0) return false
                seen = seen or bit
            }
        }
        return true
    }

    fun isComplete(board: IntArray): Boolean = board.none { it == 0 }

    fun countGivens(board: IntArray): Int = board.count { it != 0 }

    /** How many times [value] is already on the board (9 means the digit is finished). */
    fun countOf(board: IntArray, value: Int): Int = board.count { it == value }

    /** 81 characters, `0` for an empty cell. The storage format for saved games. */
    fun toStorage(board: IntArray): String = buildString(CELLS) {
        for (value in board) append('0' + value)
    }

    /** Parses [toStorage]; returns null when the text is not a well-formed board. */
    fun fromStorage(text: String?): IntArray? {
        if (text == null || text.length != CELLS) return null
        val board = IntArray(CELLS)
        for (i in 0 until CELLS) {
            val digit = text[i] - '0'
            if (digit !in 0..9) return null
            board[i] = digit
        }
        return board
    }

    /** Notes serialise as 81 comma-separated bitmasks. */
    fun notesToStorage(notes: IntArray): String = notes.joinToString(",")

    fun notesFromStorage(text: String?): IntArray? {
        if (text.isNullOrBlank()) return null
        val parts = text.split(',')
        if (parts.size != CELLS) return null
        val notes = IntArray(CELLS)
        for (i in 0 until CELLS) {
            val mask = parts[i].trim().toIntOrNull() ?: return null
            if (mask !in 0..0x1FF) return null
            notes[i] = mask
        }
        return notes
    }

    fun noteBit(value: Int) = 1 shl (value - 1)
    fun hasNote(mask: Int, value: Int) = mask and noteBit(value) != 0

    /** Every row, column and box as a list of index arrays. */
    val UNITS: Array<IntArray> = buildUnits()

    private val PEERS: Array<IntArray> = buildPeers()

    private fun buildUnits(): Array<IntArray> {
        val units = ArrayList<IntArray>(27)
        for (row in 0 until SIZE) units += IntArray(SIZE) { indexOf(row, it) }
        for (col in 0 until SIZE) units += IntArray(SIZE) { indexOf(it, col) }
        for (box in 0 until SIZE) {
            val baseRow = (box / BOX) * BOX
            val baseCol = (box % BOX) * BOX
            units += IntArray(SIZE) { indexOf(baseRow + it / BOX, baseCol + it % BOX) }
        }
        return units.toTypedArray()
    }

    private fun buildPeers(): Array<IntArray> = Array(CELLS) { index ->
        val peers = LinkedHashSet<Int>(20)
        val row = rowOf(index)
        val col = colOf(index)
        for (c in 0 until SIZE) peers += indexOf(row, c)
        for (r in 0 until SIZE) peers += indexOf(r, col)
        val baseRow = (row / BOX) * BOX
        val baseCol = (col / BOX) * BOX
        for (r in baseRow until baseRow + BOX) {
            for (c in baseCol until baseCol + BOX) peers += indexOf(r, c)
        }
        peers -= index
        peers.toIntArray()
    }
}
