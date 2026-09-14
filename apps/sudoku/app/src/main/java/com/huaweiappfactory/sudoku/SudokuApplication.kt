package com.huaweiappfactory.sudoku

import android.app.Application
import com.huaweiappfactory.sudoku.di.AppContainer
import com.huaweiappfactory.sudoku.di.DefaultAppContainer

class SudokuApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = DefaultAppContainer(this)
    }
}
