package com.huaweiappfactory.hashtags.data.repository

import com.huaweiappfactory.hashtags.data.local.CopyHistoryEntity
import com.huaweiappfactory.hashtags.data.local.CustomSetEntity
import com.huaweiappfactory.hashtags.data.local.FavouriteTagEntity
import com.huaweiappfactory.hashtags.data.local.HashtagDao
import com.huaweiappfactory.hashtags.domain.BuiltInSets
import com.huaweiappfactory.hashtags.domain.CopyRecord
import com.huaweiappfactory.hashtags.domain.HashtagSet
import com.huaweiappfactory.hashtags.domain.Tags
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map

class HashtagRepository(
    private val dao: HashtagDao,
    private val builtIn: BuiltInSets
) {

    /** Read-only sets shipped with the app. */
    fun builtInSets(): List<HashtagSet> = builtIn.all()

    val customSets: Flow<List<HashtagSet>> = dao.observeCustomSets().map { rows ->
        rows.map { it.toDomain() }
    }

    val favourites: Flow<List<String>> = dao.observeFavourites().map { rows ->
        rows.map { it.tag }
    }

    val history: Flow<List<CopyRecord>> = dao.observeHistory().map { rows ->
        rows.map { CopyRecord(it.id, Tags.deserialise(it.tags), it.sourceName, it.copiedAt) }
    }

    /**
     * Everything that can appear on the topic screen, in the order it is shown:
     * the user's own sets first, because they are why someone comes back.
     */
    val allSets: Flow<List<HashtagSet>> = combine(customSets, favourites) { custom, favs ->
        buildList {
            addAll(custom)
            if (favs.isNotEmpty()) {
                add(HashtagSet(FAVOURITES_ID, favs, HashtagSet.Kind.FAVOURITES))
            }
            addAll(builtIn.all())
        }
    }

    suspend fun createCustomSet(name: String, tags: List<String>): Long {
        val now = System.currentTimeMillis()
        return dao.insertCustomSet(
            CustomSetEntity(name = name.trim(), tags = Tags.serialise(tags), createdAt = now, updatedAt = now)
        )
    }

    suspend fun updateCustomSet(id: Long, name: String, tags: List<String>) {
        val existing = dao.customSet(id) ?: return
        dao.updateCustomSet(
            existing.copy(
                name = name.trim(),
                tags = Tags.serialise(tags),
                updatedAt = System.currentTimeMillis()
            )
        )
    }

    suspend fun deleteCustomSet(id: Long) {
        dao.customSet(id)?.let { dao.deleteCustomSet(it) }
    }

    suspend fun customSet(id: Long): HashtagSet? = dao.customSet(id)?.toDomain()

    suspend fun setFavourite(tag: String, favourite: Boolean) {
        if (favourite) {
            dao.addFavourite(FavouriteTagEntity(tag, System.currentTimeMillis()))
        } else {
            dao.removeFavourite(tag)
        }
    }

    /** Records a copy and trims the history in the same breath, so it cannot grow. */
    suspend fun recordCopy(tags: List<String>, sourceName: String) {
        if (tags.isEmpty()) return
        dao.insertHistory(
            CopyHistoryEntity(
                tags = Tags.serialise(tags),
                sourceName = sourceName,
                copiedAt = System.currentTimeMillis()
            )
        )
        dao.trimHistory(HISTORY_LIMIT)
    }

    private fun CustomSetEntity.toDomain() = HashtagSet(
        id = "custom:$id",
        tags = Tags.deserialise(tags),
        kind = HashtagSet.Kind.CUSTOM,
        customName = name,
        rowId = id
    )

    companion object {
        const val FAVOURITES_ID = "favourites"
        const val HISTORY_LIMIT = 10
    }
}
