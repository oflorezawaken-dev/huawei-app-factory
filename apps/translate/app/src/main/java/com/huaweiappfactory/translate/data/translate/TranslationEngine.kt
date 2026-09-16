package com.huaweiappfactory.translate.data.translate

import com.huawei.hmf.tasks.Task
import com.huawei.hms.mlsdk.model.download.MLModelDownloadListener
import com.huawei.hms.mlsdk.model.download.MLModelDownloadStrategy
import com.huawei.hms.mlsdk.translate.MLTranslateLanguage
import com.huawei.hms.mlsdk.translate.MLTranslatorFactory
import com.huawei.hms.mlsdk.translate.local.MLLocalTranslateSetting
import com.huawei.hms.mlsdk.translate.local.MLLocalTranslator
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * What the app needs from a translator, with no Huawei type in the signature.
 *
 * The interface exists so the ViewModels and their tests never touch the SDK:
 * ML Kit needs HMS Core on the device, which a JVM unit test does not have.
 * It does NOT exist to allow a stand-in implementation in a shipped build --
 * factory rule 2, and the reason ReceiptLens shipped an OCR that never ran.
 */
interface TranslationEngine {

    /** Language codes the on-device engine can handle at all. */
    suspend fun supportedLanguages(): Set<String>

    /** Whether this pair can translate right now, with the network switched off. */
    suspend fun isModelReady(source: String, target: String): Boolean

    /**
     * Downloads what the pair needs. Progress is reported in bytes; a pair is
     * two models of 25-30 MB each, which is a cost the user has to see coming.
     */
    suspend fun downloadModels(
        source: String,
        target: String,
        wifiOnly: Boolean,
        onProgress: (downloaded: Long, total: Long) -> Unit = { _, _ -> }
    )

    suspend fun translate(text: String, source: String, target: String): String

    /** Releases the native translator. Call when the pair changes or the screen goes. */
    fun release()
}

/** Suspends on an HMS [Task] without blocking the caller's thread. */
private suspend fun <T> Task<T>.await(): T = suspendCancellableCoroutine { cont ->
    addOnSuccessListener { value -> if (cont.isActive) cont.resume(value) }
    addOnFailureListener { error -> if (cont.isActive) cont.resumeWithException(error) }
}

/**
 * The real thing: Huawei ML Kit's on-device translator.
 *
 * Every call goes through HMS Core on the device, so nothing here can be
 * exercised by a unit test and all of it has to be verified on a phone.
 */
class MlKitTranslationEngine : TranslationEngine {

    private var translator: MLLocalTranslator? = null
    private var pair: Pair<String, String>? = null

    private fun translatorFor(source: String, target: String): MLLocalTranslator {
        val wanted = source to target
        if (pair != wanted) {
            translator?.stop()
            val setting = MLLocalTranslateSetting.Factory()
                .setSourceLangCode(source)
                .setTargetLangCode(target)
                .create()
            translator = MLTranslatorFactory.getInstance().getLocalTranslator(setting)
            pair = wanted
        }
        return requireNotNull(translator)
    }

    override suspend fun supportedLanguages(): Set<String> =
        MLTranslateLanguage.getLocalAllLanguages().await()

    override suspend fun isModelReady(source: String, target: String): Boolean =
        runCatching {
            // preparedModel() with no strategy resolves immediately when the models
            // are already on disk and fails when they are not, which is the only
            // reliable "is this pair usable offline" signal the SDK offers.
            translatorFor(source, target).preparedModel().await()
            true
        }.getOrDefault(false)

    override suspend fun downloadModels(
        source: String,
        target: String,
        wifiOnly: Boolean,
        onProgress: (Long, Long) -> Unit
    ) {
        val strategy = MLModelDownloadStrategy.Factory()
            .apply { if (wifiOnly) needWifi() }
            .create()
        val listener = MLModelDownloadListener { alreadyDownloaded, total ->
            onProgress(alreadyDownloaded, total)
        }
        translatorFor(source, target).preparedModel(strategy, listener).await()
    }

    override suspend fun translate(text: String, source: String, target: String): String =
        translatorFor(source, target).asyncTranslate(text).await()

    override fun release() {
        translator?.stop()
        translator = null
        pair = null
    }
}
