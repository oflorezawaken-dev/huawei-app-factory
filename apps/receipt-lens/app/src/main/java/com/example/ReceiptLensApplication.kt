package com.huaweiappfactory.receiptlens

import android.app.Application
import com.huaweiappfactory.receiptlens.di.AppContainer
import com.huaweiappfactory.receiptlens.di.DefaultAppContainer

class ReceiptLensApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = DefaultAppContainer(this)
    }
}
