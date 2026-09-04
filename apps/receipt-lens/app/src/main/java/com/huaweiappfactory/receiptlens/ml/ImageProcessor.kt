package com.huaweiappfactory.receiptlens.ml

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.min

object ImageProcessor {

    /**
     * Resizes large images keeping aspect ratio to prevent excessive memory usage.
     * Keeps execution strictly off the main thread.
     */
    suspend fun resizeBitmapForOcr(bitmap: Bitmap, maxDimension: Int = 1600): Bitmap =
        withContext(Dispatchers.Default) {
            val width = bitmap.width
            val height = bitmap.height

            if (width <= maxDimension && height <= maxDimension) {
                return@withContext bitmap
            }

            val ratio = min(maxDimension.toFloat() / width, maxDimension.toFloat() / height)
            val newWidth = (width * ratio).toInt()
            val newHeight = (height * ratio).toInt()

            Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
        }

    /**
     * Enhances document legibility by boosting contrast and converting to high-contrast grayscale.
     */
    suspend fun enhanceDocumentImage(src: Bitmap): Bitmap = withContext(Dispatchers.Default) {
        val width = src.width
        val height = src.height
        val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint()

        // Grayscale matrix
        val matrix = ColorMatrix()
        matrix.setSaturation(0f)

        // Increase contrast: contrast scale ~ 1.3f
        val contrast = 1.35f
        val translate = (-0.5f * contrast + 0.5f) * 255f
        val contrastMatrix = ColorMatrix(
            floatArrayOf(
                contrast, 0f, 0f, 0f, translate,
                0f, contrast, 0f, 0f, translate,
                0f, 0f, contrast, 0f, translate,
                0f, 0f, 0f, 1f, 0f
            )
        )
        matrix.postConcat(contrastMatrix)

        paint.colorFilter = ColorMatrixColorFilter(matrix)
        canvas.drawBitmap(src, 0f, 0f, paint)

        output
    }
}
