package com.huaweiappfactory.receiptlens.util

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CurrencyUtilsTest {

    @Test
    fun `parses localized decimal and thousands separators`() {
        assertEquals(123_456L, CurrencyUtils.parseAmountToMinorUnits("1,234.56", "USD"))
        assertEquals(123_456L, CurrencyUtils.parseAmountToMinorUnits("1.234,56", "EUR"))
        assertEquals(500L, CurrencyUtils.parseAmountToMinorUnits("500", "JPY"))
    }

    @Test
    fun `rejects invalid amounts`() {
        assertNull(CurrencyUtils.parseAmountToMinorUnits("not an amount", "USD"))
    }
}
