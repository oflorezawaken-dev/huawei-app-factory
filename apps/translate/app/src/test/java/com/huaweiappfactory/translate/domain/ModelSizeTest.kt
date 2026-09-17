package com.huaweiappfactory.translate.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class ModelSizeTest {

    @Test
    fun `sizes round up, so the number never promises less than the download costs`() {
        assertEquals("27 MB", ModelSize.formatBytes(27_000_000))
        assertEquals("28 MB", ModelSize.formatBytes(27_500_001))
    }

    @Test
    fun `small sizes stay in kilobytes and zero stays zero`() {
        assertEquals("0 MB", ModelSize.formatBytes(0))
        assertEquals("0 MB", ModelSize.formatBytes(-5))
        assertEquals("500 KB", ModelSize.formatBytes(500_000))
        // A single byte is still a kilobyte once rounded up, not a megabyte.
        assertEquals("1 KB", ModelSize.formatBytes(1))
    }

    @Test
    fun `a pair that is not on the phone costs one model`() {
        // ML Kit downloads "translate-en_es": one artifact for the pair, not one
        // per language. Charging twice would overstate the cost by half.
        assertEquals(ModelSize.APPROX_BYTES_PER_PAIR, ModelSize.approxPairBytes(pairReady = false))
    }

    @Test
    fun `a pair already on the phone costs nothing`() {
        assertEquals(0L, ModelSize.approxPairBytes(pairReady = true))
    }
}
