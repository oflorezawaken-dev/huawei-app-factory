package com.huaweiappfactory.sudoku.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface SudokuDao {

    @Query("SELECT * FROM saved_game WHERE id = :id LIMIT 1")
    suspend fun savedGame(id: Int = SavedGameEntity.SINGLETON_ID): SavedGameEntity?

    @Query("SELECT * FROM saved_game WHERE id = :id LIMIT 1")
    fun observeSavedGame(id: Int = SavedGameEntity.SINGLETON_ID): Flow<SavedGameEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSavedGame(game: SavedGameEntity)

    @Query("DELETE FROM saved_game")
    suspend fun clearSavedGame()

    @Insert
    suspend fun insertResult(result: GameResultEntity): Long

    @Query("SELECT * FROM game_result ORDER BY finishedAt ASC")
    fun observeResults(): Flow<List<GameResultEntity>>

    @Query("SELECT * FROM game_result ORDER BY finishedAt ASC")
    suspend fun results(): List<GameResultEntity>

    @Query("DELETE FROM game_result")
    suspend fun clearResults()
}
