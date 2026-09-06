package com.huaweiappfactory.receiptlens.ml

import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReceiptParserTest {

    @Test
    fun `parses a labeled total tax currency and category`() {
        val receipt = ReceiptParser.parse(
            """
            Carrefour Market
            Date: 2026-09-04
            Subtotal 10.00
            VAT 1.90
            GRAND TOTAL EUR 11.90
            """.trimIndent()
        )

        assertEquals("Carrefour Market", receipt.merchantName)
        assertEquals(1_190L, receipt.totalAmount)
        assertEquals(190L, receipt.taxAmount)
        assertEquals("EUR", receipt.currency)
        assertEquals(ReceiptCategory.GROCERIES.id, receipt.category)
        assertFalse(receipt.isConfidenceLow)
    }

    @Test
    fun `uses fallback total and flags ambiguous receipt`() {
        val receipt = ReceiptParser.parse("Coffee shop\nLatte 4.50\nMuffin 3.25")

        assertEquals(450L, receipt.totalAmount)
        assertEquals(ReceiptCategory.FOOD.id, receipt.category)
        assertTrue(receipt.isConfidenceLow)
    }

    @Test
    fun `handles blank and invalid receipt text`() {
        val receipt = ReceiptParser.parse("   ", defaultCurrency = "COP")

        assertNull(receipt.merchantName)
        assertNull(receipt.totalAmount)
        assertEquals("COP", receipt.currency)
        assertEquals(ReceiptCategory.OTHER.id, receipt.category)
        assertTrue(receipt.isConfidenceLow)
    }
}
