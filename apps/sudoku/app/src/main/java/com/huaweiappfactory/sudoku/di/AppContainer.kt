package com.huaweiappfactory.sudoku.di

import android.content.Context
import com.huaweiappfactory.sudoku.ads.AdManager
import com.huaweiappfactory.sudoku.ads.PetalAdsManager
import com.huaweiappfactory.sudoku.data.local.AppDatabase
import com.huaweiappfactory.sudoku.data.repository.GameRepository
import com.huaweiappfactory.sudoku.data.repository.UserPreferencesRepository

interface AppContainer {
    val database: AppDatabase
    val gameRepository: GameRepository
    val userPreferencesRepository: UserPreferencesRepository
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    override val database: AppDatabase by lazy { AppDatabase.getInstance(context) }

    override val gameRepository: GameRepository by lazy { GameRepository(database.sudokuDao()) }

    override val userPreferencesRepository: UserPreferencesRepository by lazy { UserPreferencesRepository(context) }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply { initialize(context) }
    }
}
