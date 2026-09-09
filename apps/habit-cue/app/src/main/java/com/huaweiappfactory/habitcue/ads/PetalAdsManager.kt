package com.huaweiappfactory.habitcue.ads

import android.app.Activity
import android.content.Context
import android.os.SystemClock
import android.util.Log
import com.huawei.hms.ads.AdListener
import com.huawei.hms.ads.AdParam
import com.huawei.hms.ads.HwAds
import com.huawei.hms.ads.InterstitialAd
import com.huaweiappfactory.habitcue.BuildConfig

/**
 * Where a banner may appear. Never on Today or Add/Edit habit: those are the
 * daily-check-off and data-entry surfaces the spec protects from ads.
 */
enum class AdPlacement { HABITS_BANNER, STATS_BANNER }

/** Natural pauses where an interstitial may be considered. */
enum class InterstitialTrigger { OPEN_STATISTICS }

interface AdManager {
    /** Initialises the ads SDK. Safe to call more than once. */
    fun initialize(context: Context)

    /** True once the SDK is initialised. Banners/interstitials are no-ops otherwise. */
    fun isAvailable(): Boolean

    /** Ad unit ID for banners (real in signed releases, Huawei test ID otherwise). */
    val bannerAdId: String

    /** Loads an interstitial in the background so it is ready for a later trigger. */
    fun preloadInterstitial(context: Context)

    /**
     * Shows an interstitial if one is loaded AND the frequency policy allows it.
     * Returns true when an ad was shown. Never blocks the caller.
     */
    fun maybeShowInterstitial(activity: Activity, trigger: InterstitialTrigger): Boolean
}

/**
 * Real Huawei Petal Ads integration (SDK: com.huawei.hms:ads-lite).
 *
 * Frequency policy, deliberately conservative:
 *  - no interstitial during the first [WARMUP_MS] after app start
 *  - at least [MIN_INTERVAL_MS] between interstitials
 *  - at most one interstitial per [TRIGGERS_PER_AD] triggers
 * Every failure is swallowed and logged: ads must never break habit tracking.
 */
class PetalAdsManager(context: Context) : AdManager {

    private val appContext = context.applicationContext
    private val startedAt = SystemClock.elapsedRealtime()

    @Volatile private var initialized = false
    @Volatile private var interstitial: InterstitialAd? = null
    @Volatile private var interstitialLoaded = false
    @Volatile private var lastInterstitialAt = 0L
    private var triggerCount = 0

    override val bannerAdId: String = BuildConfig.PETAL_BANNER_AD_ID

    override fun initialize(context: Context) {
        if (initialized) return
        try {
            HwAds.init(context.applicationContext)
            initialized = true
            Log.i(TAG, "Petal Ads initialised (test ids: ${BuildConfig.PETAL_ADS_USING_TEST_IDS})")
            preloadInterstitial(context)
        } catch (t: Throwable) {
            Log.w(TAG, "Petal Ads init failed; ads disabled for this session", t)
            initialized = false
        }
    }

    override fun isAvailable(): Boolean = initialized

    override fun preloadInterstitial(context: Context) {
        if (!initialized || interstitialLoaded || interstitial != null) return
        try {
            val ad = InterstitialAd(context.applicationContext).apply {
                adId = BuildConfig.PETAL_INTERSTITIAL_AD_ID
                adListener = object : AdListener() {
                    override fun onAdLoaded() { interstitialLoaded = true }
                    override fun onAdFailed(errorCode: Int) {
                        Log.d(TAG, "Interstitial failed to load: $errorCode")
                        interstitialLoaded = false
                        interstitial = null
                    }
                    override fun onAdClosed() {
                        interstitialLoaded = false
                        interstitial = null
                        // Get the next one ready for a later natural pause.
                        preloadInterstitial(appContext)
                    }
                }
            }
            interstitial = ad
            ad.loadAd(AdParam.Builder().build())
        } catch (t: Throwable) {
            Log.w(TAG, "Interstitial preload failed", t)
            interstitial = null
            interstitialLoaded = false
        }
    }

    override fun maybeShowInterstitial(activity: Activity, trigger: InterstitialTrigger): Boolean {
        if (!initialized) return false
        val now = SystemClock.elapsedRealtime()
        triggerCount++
        val warm = now - startedAt >= WARMUP_MS
        val spaced = now - lastInterstitialAt >= MIN_INTERVAL_MS
        val due = triggerCount % TRIGGERS_PER_AD == 0
        if (!(warm && spaced && due)) {
            if (interstitial == null) preloadInterstitial(activity)
            return false
        }
        val ad = interstitial
        if (ad == null || !interstitialLoaded) {
            preloadInterstitial(activity)
            return false
        }
        return try {
            ad.show(activity)
            lastInterstitialAt = now
            true
        } catch (t: Throwable) {
            Log.w(TAG, "Interstitial show failed", t)
            interstitial = null
            interstitialLoaded = false
            false
        }
    }

    private companion object {
        const val TAG = "PetalAds"
        const val WARMUP_MS = 60_000L
        const val MIN_INTERVAL_MS = 3 * 60_000L
        const val TRIGGERS_PER_AD = 4
    }
}
