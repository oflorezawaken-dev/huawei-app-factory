package com.huaweiappfactory.receiptlens.data.repository

import android.content.Context
import com.huaweiappfactory.receiptlens.data.local.ReceiptDao
import com.huaweiappfactory.receiptlens.data.local.ReceiptEntity
import com.huaweiappfactory.receiptlens.data.model.CategorySpending
import com.huaweiappfactory.receiptlens.data.model.CurrencySpending
import com.huaweiappfactory.receiptlens.data.model.MonthlySpending
import com.huaweiappfactory.receiptlens.data.model.OverallStatistics
import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory
import com.huaweiappfactory.receiptlens.util.DateUtils
import com.huaweiappfactory.receiptlens.util.ImageStorageManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Calendar

class ReceiptRepository(
    private val receiptDao: ReceiptDao,
    private val context: Context
) {

    fun getAllReceipts(): Flow<List<ReceiptEntity>> = receiptDao.getAllReceipts()

    fun getRecentReceipts(limit: Int = 5): Flow<List<ReceiptEntity>> = receiptDao.getRecentReceipts(limit)

    fun getReceiptById(id: Long): Flow<ReceiptEntity?> = receiptDao.getReceiptById(id)

    suspend fun getReceiptByIdSync(id: Long): ReceiptEntity? = receiptDao.getReceiptByIdSync(id)

    fun searchReceipts(
        query: String = "",
        category: String? = null,
        currency: String? = null,
        sortBy: String = "NEWEST"
    ): Flow<List<ReceiptEntity>> {
        return receiptDao.searchReceipts(
            query = query.trim(),
            category = if (category == "ALL") null else category,
            currency = if (currency == "ALL") null else currency,
            sortBy = sortBy
        )
    }

    fun getTotalCount(): Flow<Int> = receiptDao.getTotalCount()

    fun getDistinctCurrencies(): Flow<List<String>> = receiptDao.getDistinctCurrencies()

    suspend fun insertReceipt(receipt: ReceiptEntity): Long {
        return receiptDao.insertReceipt(receipt)
    }

    suspend fun updateReceipt(receipt: ReceiptEntity) {
        receiptDao.updateReceipt(receipt.copy(updatedAt = System.currentTimeMillis()))
    }

    /**
     * Deletes a receipt and removes its stored private image file safely.
     */
    suspend fun deleteReceipt(receipt: ReceiptEntity): Boolean {
        // Delete image file first or handle cleanly
        receipt.imagePath?.let { path ->
            ImageStorageManager.deleteImageFile(path)
        }
        receiptDao.deleteReceiptById(receipt.id)
        return true
    }

    suspend fun getAllReceiptsSnapshot(): List<ReceiptEntity> {
        return receiptDao.getAllReceiptsSnapshot()
    }

    /**
     * Computes real-time statistics grouped by currency to maintain strict financial correctness.
     */
    fun getStatistics(): Flow<OverallStatistics> {
        return receiptDao.getAllReceipts().map { receipts ->
            val now = System.currentTimeMillis()
            val totalCount = receipts.size

            // Group receipts by currency
            val groupedByCurrency = receipts.groupBy { it.currency.uppercase() }

            val currencySpendingMap = groupedByCurrency.mapValues { (currency, items) ->
                val totalAmount = items.sumOf { it.totalAmount }

                val thisMonthAmount = items
                    .filter { DateUtils.isSameMonthAndYear(it.transactionDate, now) }
                    .sumOf { it.totalAmount }

                // Category breakdown
                val byCategory = items.groupBy { it.category }
                val categorySpendings = byCategory.map { (catId, catItems) ->
                    val catAmount = catItems.sumOf { it.totalAmount }
                    val percentage = if (totalAmount > 0) (catAmount.toFloat() / totalAmount) * 100f else 0f
                    CategorySpending(
                        category = ReceiptCategory.fromId(catId),
                        amount = catAmount,
                        count = catItems.size,
                        percentage = percentage
                    )
                }.sortedByDescending { it.amount }

                // Monthly trends
                val byMonth = items.groupBy { receipt ->
                    val cal = Calendar.getInstance().apply { timeInMillis = receipt.transactionDate }
                    // Key format: YYYY-MM
                    val year = cal.get(Calendar.YEAR)
                    val month = cal.get(Calendar.MONTH)
                    Pair(year * 100 + month, receipt.transactionDate)
                }

                val monthlyTrends = byMonth.map { (keyPair, monthItems) ->
                    MonthlySpending(
                        monthYearKey = DateUtils.formatMonthYear(keyPair.second),
                        timestamp = keyPair.second,
                        amount = monthItems.sumOf { it.totalAmount },
                        count = monthItems.size
                    )
                }.sortedBy { it.timestamp }

                CurrencySpending(
                    currency = currency,
                    totalAmount = totalAmount,
                    thisMonthAmount = thisMonthAmount,
                    receiptCount = items.size,
                    categoryBreakdown = categorySpendings,
                    monthlyTrend = monthlyTrends
                )
            }

            OverallStatistics(
                totalReceiptsCount = totalCount,
                perCurrencySpending = currencySpendingMap
            )
        }
    }
}
