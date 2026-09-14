package com.huaweiappfactory.hashtags.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

/** A set the user built. Tags are stored space-separated, the same shape the clipboard uses. */
@Entity(tableName = "custom_set")
data class CustomSetEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val tags: String,
    val createdAt: Long,
    val updatedAt: Long
)

/** A starred tag. The tag itself is the key, so starring twice is impossible. */
@Entity(tableName = "favourite_tag")
data class FavouriteTagEntity(
    @PrimaryKey val tag: String,
    val addedAt: Long
)

/** One copy, kept so the same combination can be pulled back without rebuilding it. */
@Entity(tableName = "copy_history")
data class CopyHistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val tags: String,
    val sourceName: String,
    val copiedAt: Long
)
