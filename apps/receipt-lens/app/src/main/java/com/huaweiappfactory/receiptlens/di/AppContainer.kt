package com.huaweiappfactory.receiptlens.di

import android.content.Context
import com.huaweiappfactory.receiptlens.ads.AdManager
import com.huaweiappfactory.receiptlens.ads.PetalAdsManager
import com.huaweiappfactory.receiptlens.data.local.AppDatabase
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import com.huaweiappfactory.receiptlens.data.repository.UserPreferencesRepository
import com.huaweiappfactory.receiptlens.ml.HuaweiMlKitOcrService
import com.huaweiappfactory.receiptlens.ml.OcrService

interface AppContainer {
    val database: AppDatabase
    val receiptRepository: ReceiptRepository
    val userPreferencesRepository: UserPreferencesRepository
    val ocrService: OcrService
    val adManager: AdManager
}

class DefaultAppContainer(private val context: Context) : AppContainer {

    override val database: AppDatabase by lazy {
        AppDatabase.getInstance(context)
    }

    override val receiptRepository: ReceiptRepository by lazy {
        ReceiptRepository(database.receiptDao(), context)
    }

    override val userPreferencesRepository: UserPreferencesRepository by lazy {
        UserPreferencesRepository(context)
    }

    override val ocrService: OcrService by lazy {
        HuaweiMlKitOcrService(context)
    }

    override val adManager: AdManager by lazy {
        PetalAdsManager(context).apply {
            initialize(context)
        }
    }
}
