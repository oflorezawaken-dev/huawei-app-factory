package com.huaweiappfactory.hashtags

import android.app.Application
import com.huaweiappfactory.hashtags.di.AppContainer
import com.huaweiappfactory.hashtags.di.DefaultAppContainer

class HashtagsApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = DefaultAppContainer(this)
    }
}
