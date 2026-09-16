package com.huaweiappfactory.translate.di

import android.content.Context
import com.huaweiappfactory.translate.ads.AdManager
import com.huaweiappfactory.translate.ads.PetalAdsManager
import com.huaweiappfactory.translate.data.local.AppDatabase
import com.huaweiappfactory.translate.data.repository.TranslationRepository
import com.huaweiappfactory.translate.data.repository.UserPreferencesRepository
import com.huaweiappfactory.translate.data.translate.MlKitTranslationEngine
import com.huaweiappfactory.translate.data.translate.TranslationEngine

interface AppContainer {
    val translationEngine: TranslationEngine
    val translationRepository: TranslationRepository
    val userPreferencesRepository: UserPreferencesRepository
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    private val database: AppDatabase by lazy { AppDatabase.getInstance(context) }

    override val translationEngine: TranslationEngine by lazy { MlKitTranslationEngine() }

    override val translationRepository: TranslationRepository by lazy {
        TranslationRepository(database.translationDao())
    }

    override val userPreferencesRepository: UserPreferencesRepository by lazy {
        UserPreferencesRepository(context)
    }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply { initialize(context) }
    }
}
