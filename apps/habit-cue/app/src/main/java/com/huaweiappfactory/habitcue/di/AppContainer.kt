package com.huaweiappfactory.habitcue.di

import android.content.Context
import com.huaweiappfactory.habitcue.ads.AdManager
import com.huaweiappfactory.habitcue.ads.PetalAdsManager
import com.huaweiappfactory.habitcue.data.local.AppDatabase
import com.huaweiappfactory.habitcue.data.repository.HabitRepository
import com.huaweiappfactory.habitcue.data.repository.UserPreferencesRepository

interface AppContainer {
    val database: AppDatabase
    val habitRepository: HabitRepository
    val userPreferencesRepository: UserPreferencesRepository
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    override val database: AppDatabase by lazy { AppDatabase.getInstance(context) }

    override val habitRepository: HabitRepository by lazy { HabitRepository(database.habitDao()) }

    override val userPreferencesRepository: UserPreferencesRepository by lazy { UserPreferencesRepository(context) }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply { initialize(context) }
    }
}
