package com.huaweiappfactory.receiptlens.export

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.huaweiappfactory.receiptlens.data.local.ReceiptEntity
import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory
import com.huaweiappfactory.receiptlens.util.CurrencyUtils
import com.huaweiappfactory.receiptlens.util.DateUtils
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileWriter

object ReceiptCsvExporter {

    suspend fun exportReceiptsToCsv(context: Context, receipts: List<ReceiptEntity>): Result<Uri> =
        withContext(Dispatchers.IO) {
            try {
                val exportDir = File(context.cacheDir, "exports")
                if (!exportDir.exists()) {
                    exportDir.mkdirs()
                }

                val csvFile = File(exportDir, "receiptlens_expenses_${System.currentTimeMillis()}.csv")
                FileWriter(csvFile).use { writer ->
                    // CSV Header
                    writer.append("Receipt ID,Merchant,Date,Total,Tax,Currency,Category,Notes,Created At\n")

                    for (receipt in receipts) {
                        val totalDecimal = CurrencyUtils.amountToDecimalString(receipt.totalAmount, receipt.currency)
                        val taxDecimal = receipt.taxAmount?.let {
                            CurrencyUtils.amountToDecimalString(it, receipt.currency)
                        } ?: ""

                        val line = listOf(
                            receipt.id.toString(),
                            escapeCsv(receipt.merchantName),
                            DateUtils.formatIsoDate(receipt.transactionDate),
                            totalDecimal,
                            taxDecimal,
                            receipt.currency,
                            escapeCsv(receipt.category),
                            escapeCsv(receipt.notes ?: ""),
                            DateUtils.formatDateTime(receipt.createdAt)
                        ).joinToString(",")

                        writer.append(line).append("\n")
                    }
                }

                val authority = "${context.packageName}.fileprovider"
                val uri = FileProvider.getUriForFile(context, authority, csvFile)
                Result.success(uri)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }

    fun createShareCsvIntent(context: Context, csvUri: Uri): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "text/csv"
            putExtra(Intent.EXTRA_STREAM, csvUri)
            putExtra(Intent.EXTRA_SUBJECT, "ReceiptLens Expenses Export")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    fun formatSingleReceiptSummary(context: Context, receipt: ReceiptEntity): String {
        val totalFormatted = CurrencyUtils.formatAmount(receipt.totalAmount, receipt.currency)
        val dateFormatted = DateUtils.formatDate(receipt.transactionDate)
        val categoryTitle = ReceiptCategory.fromId(receipt.category).name

        val sb = StringBuilder()
        sb.append("🧾 Receipt: ").append(receipt.merchantName).append("\n")
        sb.append("💰 Total: ").append(totalFormatted).append("\n")
        sb.append("📅 Date: ").append(dateFormatted).append("\n")
        sb.append("🏷️ Category: ").append(categoryTitle).append("\n")

        receipt.taxAmount?.let { tax ->
            sb.append("🏛️ Tax: ").append(CurrencyUtils.formatAmount(tax, receipt.currency)).append("\n")
        }

        if (!receipt.notes.isNullOrBlank()) {
            sb.append("📝 Notes: ").append(receipt.notes).append("\n")
        }

        sb.append("\nExported via ReceiptLens")
        return sb.toString()
    }

    private fun escapeCsv(value: String): String {
        val containsSpecial = value.contains(",") || value.contains("\"") || value.contains("\n")
        return if (containsSpecial) {
            "\"" + value.replace("\"", "\"\"") + "\""
        } else {
            value
        }
    }
}
