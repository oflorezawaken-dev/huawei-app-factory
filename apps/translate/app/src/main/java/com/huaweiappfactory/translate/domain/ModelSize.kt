package com.huaweiappfactory.translate.domain

/**
 * Download sizes, in the unit a phone user thinks in.
 *
 * The store name promises offline translation, which is only true after a
 * download of tens of megabytes. The spec makes one rule out of that: the cost
 * is on screen before the user needs the pair, never as an error afterwards.
 */
object ModelSize {

    /**
     * Huawei ships one model per PAIR, not per language: the artifact fetched
     * for English to Spanish is "translate-en_es", around 25-30 MB.
     */
    const val APPROX_BYTES_PER_PAIR = 27L * 1000 * 1000

    fun formatBytes(bytes: Long): String = when {
        bytes <= 0 -> "0 MB"
        bytes < 1000 * 1000 -> "${(bytes + 999) / 1000} KB"
        else -> "${(bytes + 499_999) / 1_000_000} MB"
    }

    /** What a pair costs while it is not on the phone. */
    fun approxPairBytes(pairReady: Boolean): Long = if (pairReady) 0L else APPROX_BYTES_PER_PAIR
}
