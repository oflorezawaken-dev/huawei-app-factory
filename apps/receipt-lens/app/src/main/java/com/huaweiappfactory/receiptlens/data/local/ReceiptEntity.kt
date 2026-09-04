package com.huaweiappfactory.receiptlens.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Entity representing a receipt in the local Room database.
 * Monetary values are stored as Long (minor units / cents) to prevent floating-point inaccuracies.
 */
@Entity(tableName = "receipts")
data class ReceiptEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val merchantName: String,
    val transactionDate: Long, // Epoch timestamp in milliseconds
    val totalAmount: Long, // Stored in minor units (e.g. 1234 for $12.34)
    val taxAmount: Long? = null, // Stored in minor units
    val currency: String, // ISO currency code e.g. "USD", "EUR", "GBP"
    val category: String, // Category identifier e.g. "Food", "Groceries"
    val notes: String? = null,
    val imagePath: String? = null, // File path in app-private storage
    val rawOcrText: String? = null, // Preserved raw OCR recognized text
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)
