package com.huaweiappfactory.receiptlens.ads

/**
 * Configuration and unit identifiers for Huawei Petal Ads.
 * When publishing to Huawei AppGallery, replace with actual Petal Ads console ad unit IDs.
 */
object PetalAdConfig {
    // Test Ad Unit IDs provided by Huawei Petal Ads documentation
    const val TEST_BANNER_AD_ID = "testw6vs28auh3"
    const val TEST_INTERSTITIAL_AD_ID = "teste9ih9j0rc3"
    const val TEST_REWARDED_AD_ID = "testx9ih9j0rc3"

    // Set to true once Huawei Ads SDK is included and configured in project
    const val IS_PETAL_ADS_ENABLED = false
}

enum class AdPlacement {
    HISTORY_BOTTOM_BANNER,
    STATISTICS_BANNER,
    SETTINGS_FOOTER
}
