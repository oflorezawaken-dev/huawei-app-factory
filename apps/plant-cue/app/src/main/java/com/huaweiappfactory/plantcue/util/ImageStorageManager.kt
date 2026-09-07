package com.huaweiappfactory.plantcue.util

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/** Plant photos live in app-private storage, downscaled to at most [MAX_DIMENSION] px. */
object ImageStorageManager {

    private const val PHOTOS_DIR = "plants"
    private const val MAX_DIMENSION = 1280

    private fun photosDir(context: Context): File =
        File(context.filesDir, PHOTOS_DIR).also { if (!it.exists()) it.mkdirs() }

    /** Temporary file handed to the system camera through the FileProvider. */
    fun newCameraTempFile(context: Context): File {
        val dir = File(context.cacheDir, "camera").also { if (!it.exists()) it.mkdirs() }
        return File(dir, "capture_${System.currentTimeMillis()}.jpg")
    }

    suspend fun saveImageFromUri(context: Context, uri: Uri): Result<String> = withContext(Dispatchers.IO) {
        try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            context.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            var sample = 1
            val maxDim = maxOf(bounds.outWidth, bounds.outHeight)
            while (maxDim / (sample * 2) >= MAX_DIMENSION) sample *= 2
            val bitmap = context.contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
            } ?: return@withContext Result.failure(IllegalStateException("Could not decode image"))
            saveBitmap(context, bitmap)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun saveImageFromFile(context: Context, file: File): Result<String> =
        saveImageFromUri(context, Uri.fromFile(file)).also { runCatching { file.delete() } }

    private fun saveBitmap(context: Context, bitmap: Bitmap): Result<String> = try {
        val file = File(photosDir(context), "plant_${System.currentTimeMillis()}_${UUID.randomUUID().toString().take(6)}.jpg")
        FileOutputStream(file).use { out ->
            if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 85, out)) {
                file.delete()
                return Result.failure(IllegalStateException("Could not compress image"))
            }
        }
        Result.success(file.absolutePath)
    } catch (e: Exception) {
        Result.failure(e)
    }

    suspend fun deleteImageFile(path: String?): Boolean = withContext(Dispatchers.IO) {
        if (path.isNullOrBlank()) return@withContext true
        runCatching { File(path).takeIf { it.exists() }?.delete() ?: true }.getOrDefault(false)
    }
}
