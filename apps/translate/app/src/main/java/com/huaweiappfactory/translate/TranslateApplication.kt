package com.huaweiappfactory.translate

import android.app.Application
import android.util.Log
import com.huawei.hms.mlsdk.common.MLApplication
import com.huaweiappfactory.translate.di.AppContainer
import com.huaweiappfactory.translate.di.DefaultAppContainer

class TranslateApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        // ML Kit authorises the model download with this key. It is a credential:
        // it comes from BuildConfig, which CI fills from a GitHub secret, and it
        // is never printed -- only its absence is, because a build without it
        // looks identical until the first download fails.
        val apiKey = BuildConfig.ML_KIT_API_KEY
        if (apiKey.isBlank()) {
            Log.w("Translate", "ML_KIT_API_KEY is empty; language packs will not download.")
        } else {
            MLApplication.getInstance().apiKey = apiKey
        }
        container = DefaultAppContainer(this)
    }
}
