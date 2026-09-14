package com.huaweiappfactory.hashtags.di

import android.content.Context
import com.huaweiappfactory.hashtags.ads.AdManager
import com.huaweiappfactory.hashtags.ads.PetalAdsManager
import com.huaweiappfactory.hashtags.data.local.AppDatabase
import com.huaweiappfactory.hashtags.data.local.AssetSets
import com.huaweiappfactory.hashtags.data.repository.HashtagRepository
import com.huaweiappfactory.hashtags.data.repository.UserPreferencesRepository

interface AppContainer {
    val database: AppDatabase
    val hashtagRepository: HashtagRepository
    val userPreferencesRepository: UserPreferencesRepository
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    override val database: AppDatabase by lazy { AppDatabase.getInstance(context) }

    override val hashtagRepository: HashtagRepository by lazy {
        HashtagRepository(database.hashtagDao(), AssetSets(context))
    }

    override val userPreferencesRepository: UserPreferencesRepository by lazy {
        UserPreferencesRepository(context)
    }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply { initialize(context) }
    }
}
