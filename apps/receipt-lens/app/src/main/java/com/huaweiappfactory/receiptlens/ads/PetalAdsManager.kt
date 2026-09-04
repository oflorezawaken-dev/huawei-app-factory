package com.huaweiappfactory.receiptlens.ads

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.ViewGroup

interface AdManager {
    fun initialize(context: Context)
    fun isAvailable(): Boolean
    fun createBannerView(context: Context, placement: AdPlacement): View?
    fun showInterstitial(activity: Activity, onDismissed: () -> Unit)
    fun showRewarded(activity: Activity, onRewarded: () -> Unit, onDismissed: () -> Unit)
}

/**
 * Cleanly isolated Petal Ads Manager.
 * Complies with strict guidelines:
 * - Ads are never shown during camera scanning
 * - Ads are never shown during OCR extraction
 * - Ads are never shown during active receipt editing to prevent data loss
 * - Completely isolated: If Petal Ads SDK is not configured, the app works 100% offline without errors.
 */
class PetalAdsManager(
    private val context: Context
) : AdManager {

    private var initialized = false

    override fun initialize(context: Context) {
        if (!PetalAdConfig.IS_PETAL_ADS_ENABLED) return

        try {
            // Dynamic check for Huawei HwAds SDK class
            val hwAdsClass = Class.forName("com.huawei.hms.ads.HwAds")
            val initMethod = hwAdsClass.getMethod("init", Context::class.java)
            initMethod.invoke(null, context.applicationContext)
            initialized = true
        } catch (_: Exception) {
            initialized = false
        }
    }

    override fun isAvailable(): Boolean {
        return initialized && PetalAdConfig.IS_PETAL_ADS_ENABLED
    }

    override fun createBannerView(context: Context, placement: AdPlacement): View? {
        if (!isAvailable()) return null

        try {
            // Reflection instantiate Huawei BannerView
            val bannerViewClass = Class.forName("com.huawei.hms.ads.banner.BannerView")
            val constructor = bannerViewClass.getConstructor(Context::class.java)
            val bannerView = constructor.newInstance(context) as View

            val setAdIdMethod = bannerViewClass.getMethod("setAdId", String::class.java)
            setAdIdMethod.invoke(bannerView, PetalAdConfig.TEST_BANNER_AD_ID)

            val adParamClass = Class.forName("com.huawei.hms.ads.AdParam\$Builder")
            val builder = adParamClass.getConstructor().newInstance()
            val buildMethod = adParamClass.getMethod("build")
            val adParam = buildMethod.invoke(builder)

            val loadAdMethod = bannerViewClass.getMethod("loadAd", Class.forName("com.huawei.hms.ads.AdParam"))
            loadAdMethod.invoke(bannerView, adParam)

            return bannerView
        } catch (_: Exception) {
            return null
        }
    }

    override fun showInterstitial(activity: Activity, onDismissed: () -> Unit) {
        // Protected execution: do not display if not configured
        if (!isAvailable()) {
            onDismissed()
            return
        }
        onDismissed()
    }

    override fun showRewarded(activity: Activity, onRewarded: () -> Unit, onDismissed: () -> Unit) {
        if (!isAvailable()) {
            onDismissed()
            return
        }
        onDismissed()
    }
}
