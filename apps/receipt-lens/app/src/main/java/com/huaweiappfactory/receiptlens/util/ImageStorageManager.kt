package com.huaweiappfactory.receiptlens.util

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

object ImageStorageManager {

    private const val RECEIPTS_DIR = "receipts"

    private fun getReceiptsDirectory(context: Context): File {
        val dir = File(context.filesDir, RECEIPTS_DIR)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }

    /**
     * Saves a bitmap directly to application-private internal storage.
     * Returns the absolute path of the saved file.
     */
    suspend fun saveBitmap(context: Context, bitmap: Bitmap): Result<String> = withContext(Dispatchers.IO) {
        try {
            val dir = getReceiptsDirectory(context)
            val fileName = "receipt_${System.currentTimeMillis()}_${UUID.randomUUID().toString().take(6)}.jpg"
            val file = File(dir, fileName)

            FileOutputStream(file).use { out ->
                val success = bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                if (!success) {
                    file.delete()
                    return@withContext Result.failure(Exception("Failed to compress bitmap"))
                }
            }
            Result.success(file.absolutePath)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Copies an image from a Content Uri (e.g. from System Photo Picker) to application-private storage.
     * Downsamples if needed to avoid OutOfMemory.
     * Returns absolute path of saved file.
     */
    suspend fun saveImageFromUri(context: Context, uri: Uri): Result<String> = withContext(Dispatchers.IO) {
        try {
            val dir = getReceiptsDirectory(context)
            val fileName = "receipt_${System.currentTimeMillis()}_${UUID.randomUUID().toString().take(6)}.jpg"
            val destFile = File(dir, fileName)

            // Decode dimensions first
            var inputStream: InputStream? = context.contentResolver.openInputStream(uri)
            val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeStream(inputStream, null, options)
            inputStream?.close()

            // Calculate inSampleSize to bound max dimension around 2000px
            val maxDim = maxOf(options.outWidth, options.outHeight)
            var inSampleSize = 1
            while (maxDim / (inSampleSize * 2) >= 1600) {
                inSampleSize *= 2
            }

            // Decode bitmap with scale
            inputStream = context.contentResolver.openInputStream(uri)
            val decodeOptions = BitmapFactory.Options().apply {
                this.inSampleSize = inSampleSize
            }
            val bitmap = BitmapFactory.decodeStream(inputStream, null, decodeOptions)
            inputStream?.close()

            if (bitmap == null) {
                return@withContext Result.failure(Exception("Failed to decode image from Uri"))
            }

            FileOutputStream(destFile).use { out ->
                val compressed = bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)
                if (!compressed) {
                    destFile.delete()
                    return@withContext Result.failure(Exception("Failed to compress and save image"))
                }
            }

            Result.success(destFile.absolutePath)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Loads a bitmap safely from file path with bounding size.
     */
    suspend fun loadBitmap(filePath: String, maxDimension: Int = 1600): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val file = File(filePath)
            if (!file.exists()) return@withContext null

            val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(filePath, options)

            var sampleSize = 1
            val maxDim = maxOf(options.outWidth, options.outHeight)
            while (maxDim / (sampleSize * 2) >= maxDimension) {
                sampleSize *= 2
            }

            val decodeOptions = BitmapFactory.Options().apply {
                inSampleSize = sampleSize
            }
            BitmapFactory.decodeFile(filePath, decodeOptions)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Deletes the local image file safely.
     */
    suspend fun deleteImageFile(filePath: String?): Boolean = withContext(Dispatchers.IO) {
        if (filePath.isNullOrBlank()) return@withContext true
        try {
            val file = File(filePath)
            if (file.exists()) {
                file.delete()
            } else {
                true
            }
        } catch (e: Exception) {
            false
        }
    }
}
