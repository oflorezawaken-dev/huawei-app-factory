package com.huaweiappfactory.receiptlens.domain.model

data class CurrencyInfo(
    val code: String,
    val symbol: String,
    val name: String,
    val minorUnits: Int = 2
) {
    companion object {
        val SUPPORTED_CURRENCIES = listOf(
            CurrencyInfo("USD", "$", "US Dollar"),
            CurrencyInfo("EUR", "€", "Euro"),
            CurrencyInfo("GBP", "£", "British Pound"),
            CurrencyInfo("CAD", "CA$", "Canadian Dollar"),
            CurrencyInfo("AUD", "AU$", "Australian Dollar"),
            CurrencyInfo("JPY", "¥", "Japanese Yen", minorUnits = 0),
            CurrencyInfo("CNY", "¥", "Chinese Yuan"),
            CurrencyInfo("SAR", "ر.س", "Saudi Riyal"),
            CurrencyInfo("AED", "د.إ", "UAE Dirham"),
            CurrencyInfo("TRY", "₺", "Turkish Lira"),
            CurrencyInfo("BRL", "R$", "Brazilian Real"),
            CurrencyInfo("CHF", "CHF", "Swiss Franc"),
            CurrencyInfo("INR", "₹", "Indian Rupee"),
            CurrencyInfo("MXN", "MX$", "Mexican Peso")
        )

        fun findByCode(code: String): CurrencyInfo {
            return SUPPORTED_CURRENCIES.find { it.code.equals(code, ignoreCase = true) }
                ?: CurrencyInfo(code.uppercase(), code.uppercase(), code.uppercase())
        }
    }
}
