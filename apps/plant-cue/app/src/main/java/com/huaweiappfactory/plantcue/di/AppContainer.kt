package com.huaweiappfactory.plantcue.di

import android.content.Context
import com.huaweiappfactory.plantcue.ads.AdManager
import com.huaweiappfactory.plantcue.ads.PetalAdsManager
import com.huaweiappfactory.plantcue.data.local.AppDatabase
import com.huaweiappfactory.plantcue.data.repository.PlantRepository
import com.huaweiappfactory.plantcue.data.repository.UserPreferencesRepository

interface AppContainer {
    val database: AppDatabase
    val plantRepository: PlantRepository
    val userPreferencesRepository: UserPreferencesRepository
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    override val database: AppDatabase by lazy { AppDatabase.getInstance(context) }

    override val plantRepository: PlantRepository by lazy { PlantRepository(database.plantDao(), context) }

    override val userPreferencesRepository: UserPreferencesRepository by lazy { UserPreferencesRepository(context) }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply { initialize(context) }
    }
}
