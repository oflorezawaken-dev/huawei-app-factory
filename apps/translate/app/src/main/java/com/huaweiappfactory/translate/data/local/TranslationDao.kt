package com.huaweiappfactory.translate.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TranslationDao {

    @Query("SELECT * FROM translations ORDER BY createdAt DESC")
    fun history(): Flow<List<TranslationEntity>>

    @Insert
    suspend fun insert(row: TranslationEntity): Long

    @Query("DELETE FROM translations WHERE id = :id")
    suspend fun delete(id: Long)

    @Query("DELETE FROM translations")
    suspend fun clear()

    /**
     * Keeps the newest [keep] rows. One statement rather than loading the table
     * into Kotlin to decide what to drop: the history is unbounded input and the
     * app should not scale its memory with it.
     */
    @Query(
        "DELETE FROM translations WHERE id NOT IN " +
            "(SELECT id FROM translations ORDER BY createdAt DESC LIMIT :keep)"
    )
    suspend fun trim(keep: Int)
}
