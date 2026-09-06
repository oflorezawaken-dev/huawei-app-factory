package com.huaweiappfactory.receiptlens.ads

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import com.huawei.hms.ads.AdParam
import com.huawei.hms.ads.BannerAdSize
import com.huawei.hms.ads.banner.BannerView

/** Provided once at the app root; screens read it to place ads. */
val LocalAdManager = compositionLocalOf<AdManager?> { null }

/**
 * A Petal Ads banner as a Compose element. Renders nothing when ads are not
 * available, so layouts never reserve space for an ad that will not come.
 */
@Composable
fun PetalBanner(placement: AdPlacement, modifier: Modifier = Modifier) {
    val adManager = LocalAdManager.current ?: return
    if (!adManager.isAvailable()) return

    val context = LocalContext.current
    val bannerView = remember(placement) {
        BannerView(context).apply {
            adId = adManager.bannerAdId
            bannerAdSize = BannerAdSize.BANNER_SIZE_SMART
            setBannerRefresh(60)
        }
    }

    DisposableEffect(bannerView) {
        try {
            bannerView.loadAd(AdParam.Builder().build())
        } catch (_: Throwable) {
            // Ads must never break the screen.
        }
        onDispose {
            try { bannerView.destroy() } catch (_: Throwable) { }
        }
    }

    AndroidView(
        factory = { bannerView },
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .testTag("petal_banner_${placement.name.lowercase()}")
    )
}

/** Finds the hosting Activity from a Compose context, if any. */
fun Context.findActivity(): Activity? {
    var ctx: Context = this
    while (ctx is ContextWrapper) {
        if (ctx is Activity) return ctx
        ctx = ctx.baseContext
    }
    return null
}
