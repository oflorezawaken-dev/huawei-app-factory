package com.huaweiappfactory.translate.di

import android.content.Context
import com.huaweiappfactory.translate.ads.AdManager
import com.huaweiappfactory.translate.ads.PetalAdsManager
import com.huaweiappfactory.translate.data.translate.MlKitTranslationEngine
import com.huaweiappfactory.translate.data.translate.TranslationEngine

interface AppContainer {
    val translationEngine: TranslationEngine
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    override val translationEngine: TranslationEngine by lazy { MlKitTranslationEngine() }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply { initialize(context) }
    }
}
