package com.huaweiappfactory.receiptlens.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ReceiptDao {

    @Query("SELECT * FROM receipts ORDER BY transactionDate DESC, id DESC")
    fun getAllReceipts(): Flow<List<ReceiptEntity>>

    @Query("SELECT * FROM receipts ORDER BY transactionDate DESC, id DESC LIMIT :limit")
    fun getRecentReceipts(limit: Int): Flow<List<ReceiptEntity>>

    @Query("SELECT * FROM receipts WHERE id = :id")
    fun getReceiptById(id: Long): Flow<ReceiptEntity?>

    @Query("SELECT * FROM receipts WHERE id = :id")
    suspend fun getReceiptByIdSync(id: Long): ReceiptEntity?

    @Query("""
        SELECT * FROM receipts 
        WHERE (merchantName LIKE '%' || :query || '%' OR (notes IS NOT NULL AND notes LIKE '%' || :query || '%'))
        AND (:category IS NULL OR category = :category)
        AND (:currency IS NULL OR currency = :currency)
        ORDER BY 
        CASE WHEN :sortBy = 'NEWEST' THEN transactionDate END DESC,
        CASE WHEN :sortBy = 'OLDEST' THEN transactionDate END ASC,
        CASE WHEN :sortBy = 'HIGHEST' THEN totalAmount END DESC,
        CASE WHEN :sortBy = 'LOWEST' THEN totalAmount END ASC,
        id DESC
    """)
    fun searchReceipts(
        query: String,
        category: String?,
        currency: String?,
        sortBy: String
    ): Flow<List<ReceiptEntity>>

    @Query("SELECT COUNT(*) FROM receipts")
    fun getTotalCount(): Flow<Int>

    @Query("SELECT DISTINCT currency FROM receipts")
    fun getDistinctCurrencies(): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReceipt(receipt: ReceiptEntity): Long

    @Update
    suspend fun updateReceipt(receipt: ReceiptEntity)

    @Query("DELETE FROM receipts WHERE id = :id")
    suspend fun deleteReceiptById(id: Long)

    @Query("SELECT * FROM receipts")
    suspend fun getAllReceiptsSnapshot(): List<ReceiptEntity>
}
