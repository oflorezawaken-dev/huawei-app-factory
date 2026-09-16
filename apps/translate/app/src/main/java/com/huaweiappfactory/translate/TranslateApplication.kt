package com.huaweiappfactory.translate

import android.app.Application
import com.huaweiappfactory.translate.di.AppContainer
import com.huaweiappfactory.translate.di.DefaultAppContainer

class TranslateApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        // ML Kit is configured in MlKitBootstrap, a ContentProvider: onCreate here
        // runs after ML Kit has already chosen its endpoint, which is too late.
        container = DefaultAppContainer(this)
    }
}
