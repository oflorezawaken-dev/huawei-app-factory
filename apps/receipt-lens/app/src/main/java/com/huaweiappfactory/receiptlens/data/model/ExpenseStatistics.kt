package com.huaweiappfactory.receiptlens.data.model

import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory

data class CurrencySpending(
    val currency: String,
    val totalAmount: Long, // Minor units
    val thisMonthAmount: Long, // Minor units
    val receiptCount: Int,
    val categoryBreakdown: List<CategorySpending>,
    val monthlyTrend: List<MonthlySpending>
)

data class CategorySpending(
    val category: ReceiptCategory,
    val amount: Long, // Minor units
    val count: Int,
    val percentage: Float // 0.0 to 100.0
)

data class MonthlySpending(
    val monthYearKey: String, // e.g. "Sep 2026"
    val timestamp: Long,
    val amount: Long, // Minor units
    val count: Int
)

data class OverallStatistics(
    val totalReceiptsCount: Int,
    val perCurrencySpending: Map<String, CurrencySpending>
)
