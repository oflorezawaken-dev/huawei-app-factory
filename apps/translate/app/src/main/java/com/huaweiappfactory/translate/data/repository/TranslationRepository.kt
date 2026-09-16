package com.huaweiappfactory.translate.data.repository

import com.huaweiappfactory.translate.data.local.TranslationDao
import com.huaweiappfactory.translate.data.local.TranslationEntity
import kotlinx.coroutines.flow.Flow

/** One translation as the app talks about it. */
data class TranslationRecord(
    val id: Long,
    val sourceLang: String,
    val targetLang: String,
    val sourceText: String,
    val translatedText: String,
    val createdAt: Long
)

class TranslationRepository(private val dao: TranslationDao) {

    fun history(): Flow<List<TranslationEntity>> = dao.history()

    /**
     * Records a translation, unless the user has turned history off.
     *
     * The cap is applied on every insert rather than on a schedule: there is no
     * background work in this app, so the only moment the table can grow is the
     * only moment it can be trimmed.
     */
    suspend fun record(
        sourceLang: String,
        targetLang: String,
        sourceText: String,
        translatedText: String,
        now: Long = System.currentTimeMillis()
    ) {
        dao.insert(
            TranslationEntity(
                sourceLang = sourceLang,
                targetLang = targetLang,
                sourceText = sourceText,
                translatedText = translatedText,
                createdAt = now
            )
        )
        dao.trim(MAX_HISTORY)
    }

    suspend fun delete(id: Long) = dao.delete(id)

    suspend fun clear() = dao.clear()

    companion object {
        const val MAX_HISTORY = 100
    }
}
