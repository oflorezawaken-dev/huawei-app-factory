package com.huaweiappfactory.sudoku.data.repository

import com.huaweiappfactory.sudoku.data.local.GameResultEntity
import com.huaweiappfactory.sudoku.data.local.SavedGameEntity
import com.huaweiappfactory.sudoku.data.local.SudokuDao
import com.huaweiappfactory.sudoku.domain.Difficulty
import com.huaweiappfactory.sudoku.domain.GameOutcome
import com.huaweiappfactory.sudoku.domain.SudokuBoard
import com.huaweiappfactory.sudoku.domain.SudokuGame
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/** A saved game summarised for the Continue card on Home. */
data class SavedGameSummary(
    val difficulty: Difficulty,
    val elapsedSeconds: Int,
    val progress: Float
)

class GameRepository(private val dao: SudokuDao) {

    val savedGameSummary: Flow<SavedGameSummary?> = dao.observeSavedGame().map { entity ->
        val game = entity?.let { toGame(it) } ?: return@map null
        SavedGameSummary(game.difficulty, game.elapsedSeconds, game.progress())
    }

    val outcomes: Flow<List<GameOutcome>> = dao.observeResults().map { list ->
        list.map {
            GameOutcome(
                difficulty = Difficulty.fromName(it.difficulty),
                won = it.won,
                elapsedSeconds = it.elapsedSeconds,
                finishedAtMillis = it.finishedAt
            )
        }
    }

    suspend fun loadSavedGame(): SudokuGame? = dao.savedGame()?.let { toGame(it) }

    suspend fun saveGame(game: SudokuGame) {
        dao.upsertSavedGame(
            SavedGameEntity(
                difficulty = game.difficulty.name,
                givens = SudokuBoard.toStorage(game.givens),
                solution = SudokuBoard.toStorage(game.solution),
                entries = SudokuBoard.toStorage(game.entries()),
                notes = SudokuBoard.notesToStorage(game.notes()),
                elapsedSeconds = game.elapsedSeconds,
                mistakes = game.mistakes,
                hintsUsed = game.hintsUsed,
                updatedAt = System.currentTimeMillis()
            )
        )
    }

    suspend fun clearSavedGame() = dao.clearSavedGame()

    suspend fun recordResult(game: SudokuGame, won: Boolean) {
        dao.insertResult(
            GameResultEntity(
                difficulty = game.difficulty.name,
                won = won,
                elapsedSeconds = game.elapsedSeconds,
                mistakes = game.mistakes,
                hintsUsed = game.hintsUsed,
                finishedAt = System.currentTimeMillis()
            )
        )
    }

    suspend fun allOutcomes(): List<GameOutcome> = dao.results().map {
        GameOutcome(Difficulty.fromName(it.difficulty), it.won, it.elapsedSeconds, it.finishedAt)
    }

    suspend fun clearStatistics() = dao.clearResults()

    /** A row that cannot be parsed is treated as no saved game rather than a crash. */
    private fun toGame(entity: SavedGameEntity): SudokuGame? {
        val givens = SudokuBoard.fromStorage(entity.givens) ?: return null
        val solution = SudokuBoard.fromStorage(entity.solution) ?: return null
        val entries = SudokuBoard.fromStorage(entity.entries) ?: return null
        val notes = SudokuBoard.notesFromStorage(entity.notes) ?: IntArray(SudokuBoard.CELLS)
        if (!SudokuBoard.isValidSolution(solution)) return null
        return SudokuGame(
            difficulty = Difficulty.fromName(entity.difficulty),
            givens = givens,
            solution = solution,
            entries = entries,
            notes = notes,
            mistakes = entity.mistakes,
            hintsUsed = entity.hintsUsed,
            elapsedSeconds = entity.elapsedSeconds
        )
    }
}
