package com.huaweiappfactory.receiptlens.util

import com.huaweiappfactory.receiptlens.domain.model.CurrencyInfo
import java.math.BigDecimal
import java.math.RoundingMode
import java.text.NumberFormat
import java.util.Currency
import java.util.Locale

object CurrencyUtils {

    /**
     * Formats an amount given in minor currency units (e.g. cents) into a display string.
     * Uses BigDecimal to avoid any floating-point representation inaccuracy.
     */
    fun formatAmount(
        amountInMinorUnits: Long,
        currencyCode: String,
        locale: Locale = Locale.getDefault()
    ): String {
        val currencyInfo = CurrencyInfo.findByCode(currencyCode)
        val decimal = BigDecimal.valueOf(amountInMinorUnits)
            .movePointLeft(currencyInfo.minorUnits)

        return try {
            val format = NumberFormat.getCurrencyInstance(locale)
            try {
                format.currency = Currency.getInstance(currencyCode)
            } catch (_: Exception) {
                // In case non-standard code
            }
            format.format(decimal)
        } catch (_: Exception) {
            // Fallback formatting
            val scale = currencyInfo.minorUnits
            val formattedNumber = decimal.setScale(scale, RoundingMode.HALF_UP).toPlainString()
            "${currencyInfo.symbol} $formattedNumber"
        }
    }

    /**
     * Formats an amount given in minor units to a plain decimal representation for text fields.
     * E.g. 1250 with 2 minor units -> "12.50", 500 with 0 minor units -> "500".
     */
    fun amountToDecimalString(amountInMinorUnits: Long?, currencyCode: String): String {
        if (amountInMinorUnits == null) return ""
        val currencyInfo = CurrencyInfo.findByCode(currencyCode)
        return BigDecimal.valueOf(amountInMinorUnits)
            .movePointLeft(currencyInfo.minorUnits)
            .setScale(currencyInfo.minorUnits, RoundingMode.HALF_UP)
            .toPlainString()
    }

    /**
     * Parses a string representation of an amount into minor units (e.g. cents).
     * Handles both comma and period as decimal separator.
     * E.g. "12.34" or "12,34" -> 1234L for a 2-decimal currency.
     */
    fun parseAmountToMinorUnits(input: String, currencyCode: String): Long? {
        val cleaned = input.trim()
            .replace("[^0-9.,]".toRegex(), "")
            .trim()

        if (cleaned.isEmpty()) return null

        val currencyInfo = CurrencyInfo.findByCode(currencyCode)

        // Determine if comma or dot is the decimal separator
        val standardized = if (cleaned.contains(",") && cleaned.contains(".")) {
            // e.g. 1,234.56 or 1.234,56
            if (cleaned.lastIndexOf('.') > cleaned.lastIndexOf(',')) {
                // 1,234.56
                cleaned.replace(",", "")
            } else {
                // 1.234,56
                cleaned.replace(".", "").replace(",", ".")
            }
        } else if (cleaned.contains(",")) {
            // Could be 12,34 (decimal) or 1,000 (thousands)
            val parts = cleaned.split(",")
            if (parts.size == 2 && parts[1].length <= currencyInfo.minorUnits) {
                cleaned.replace(",", ".")
            } else {
                cleaned.replace(",", "")
            }
        } else {
            cleaned
        }

        return try {
            val bd = BigDecimal(standardized)
            bd.movePointRight(currencyInfo.minorUnits)
                .setScale(0, RoundingMode.HALF_UP)
                .longValueExact()
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Detects currency code from raw OCR text using regex heuristics.
     */
    fun detectCurrency(text: String, defaultCurrency: String = "USD"): String {
        // OCR receipts are multi-line; normalize line breaks so the existing
        // whole-text regex heuristics can see currency codes on any line.
        val upper = text.uppercase().replace('\n', ' ').replace('\r', ' ')

        return when {
            text.contains("€") || upper.matches(".*\\b(EUR|EURO|EUROS)\\b.*".toRegex()) -> "EUR"
            text.contains("£") || upper.matches(".*\\b(GBP|POUND|POUNDS)\\b.*".toRegex()) -> "GBP"
            text.contains("¥") || upper.matches(".*\\b(JPY|YEN|RMB|CNY|YUAN)\\b.*".toRegex()) -> {
                if (upper.contains("CNY") || upper.contains("RMB") || upper.contains("元") || upper.contains("YUAN")) "CNY" else "JPY"
            }
            text.contains("₺") || upper.matches(".*\\b(TRY|TL)\\b.*".toRegex()) -> "TRY"
            text.contains("R$") || upper.matches(".*\\b(BRL|REAIS)\\b.*".toRegex()) -> "BRL"
            upper.matches(".*\\b(SAR|RIYAL|RIYALS)\\b.*".toRegex()) || text.contains("ر.س") -> "SAR"
            upper.matches(".*\\b(AED|DIRHAM|DIRHAMS|DHS)\\b.*".toRegex()) || text.contains("د.إ") -> "AED"
            upper.matches(".*\\b(CAD|CA\\$)\\b.*".toRegex()) -> "CAD"
            upper.matches(".*\\b(AUD|AU\\$)\\b.*".toRegex()) -> "AUD"
            upper.matches(".*\\bCHF\\b.*".toRegex()) -> "CHF"
            text.contains("$") || upper.matches(".*\\b(USD|DOLLAR|DOLLARS)\\b.*".toRegex()) -> "USD"
            else -> defaultCurrency
        }
    }
}
