package com.huaweiappfactory.receiptlens.ml

import android.graphics.Bitmap

sealed class OcrResult {
    data class Success(val rawText: String) : OcrResult()
    data class Failure(val message: String, val cause: Throwable? = null) : OcrResult()
    data class Unavailable(val reason: String) : OcrResult()
}

interface OcrService {
    suspend fun processImage(bitmap: Bitmap): OcrResult
}
