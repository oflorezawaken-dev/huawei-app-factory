package com.huaweiappfactory.hashtags.data.local

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface HashtagDao {

    @Query("SELECT * FROM custom_set ORDER BY updatedAt DESC")
    fun observeCustomSets(): Flow<List<CustomSetEntity>>

    @Query("SELECT * FROM custom_set WHERE id = :id")
    suspend fun customSet(id: Long): CustomSetEntity?

    @Insert
    suspend fun insertCustomSet(set: CustomSetEntity): Long

    @Update
    suspend fun updateCustomSet(set: CustomSetEntity)

    @Delete
    suspend fun deleteCustomSet(set: CustomSetEntity)

    @Query("SELECT * FROM favourite_tag ORDER BY addedAt DESC")
    fun observeFavourites(): Flow<List<FavouriteTagEntity>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun addFavourite(tag: FavouriteTagEntity)

    @Query("DELETE FROM favourite_tag WHERE tag = :tag")
    suspend fun removeFavourite(tag: String)

    @Query("SELECT * FROM copy_history ORDER BY copiedAt DESC")
    fun observeHistory(): Flow<List<CopyHistoryEntity>>

    @Insert
    suspend fun insertHistory(entry: CopyHistoryEntity)

    /**
     * Keeps the history at [keep] rows. Written as one statement so a burst of
     * copies cannot leave the table growing between a count and a delete.
     */
    @Query("DELETE FROM copy_history WHERE id NOT IN " +
        "(SELECT id FROM copy_history ORDER BY copiedAt DESC LIMIT :keep)")
    suspend fun trimHistory(keep: Int)
}
