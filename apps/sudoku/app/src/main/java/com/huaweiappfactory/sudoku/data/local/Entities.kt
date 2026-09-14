package com.huaweiappfactory.sudoku.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * The single game in progress. There is at most one row, always id = 1: starting a
 * new puzzle replaces it, finishing one deletes it.
 */
@Entity(tableName = "saved_game")
data class SavedGameEntity(
    @PrimaryKey val id: Int = SINGLETON_ID,
    val difficulty: String,
    val givens: String,
    val solution: String,
    val entries: String,
    val notes: String,
    val elapsedSeconds: Int,
    val mistakes: Int,
    val hintsUsed: Int,
    val updatedAt: Long
) {
    companion object {
        const val SINGLETON_ID = 1
    }
}

/** One finished game. Never updated, only appended, so statistics are a pure read. */
@Entity(tableName = "game_result")
data class GameResultEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val difficulty: String,
    val won: Boolean,
    val elapsedSeconds: Int,
    val mistakes: Int,
    val hintsUsed: Int,
    val finishedAt: Long
)
