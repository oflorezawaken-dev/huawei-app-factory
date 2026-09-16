package com.huaweiappfactory.translate.data.translate

import com.huawei.hmf.tasks.Task
import com.huawei.hms.mlsdk.langdetect.MLLangDetectorFactory
import com.huawei.hms.mlsdk.langdetect.local.MLLocalLangDetector
import com.huawei.hms.mlsdk.model.download.MLLocalModelManager
import com.huawei.hms.mlsdk.model.download.MLModelDownloadListener
import com.huawei.hms.mlsdk.model.download.MLModelDownloadStrategy
import com.huawei.hms.mlsdk.translate.MLTranslateLanguage
import com.huawei.hms.mlsdk.translate.MLTranslatorFactory
import com.huawei.hms.mlsdk.translate.local.MLLocalTranslateSetting
import com.huawei.hms.mlsdk.translate.local.MLLocalTranslator
import com.huawei.hms.mlsdk.translate.local.MLLocalTranslatorModel
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

    /** Languages that appear in at least one model on the phone. */
    suspend fun downloadedLanguages(): Set<String>

    /**
     * Whether this exact pair can translate right now with the network off.
     *
     * The unit ML Kit downloads is a pair, not a language: the file it fetches
     * for English to Spanish is called "translate-en_es". Asking whether two
     * languages are present is therefore the wrong question and always answers
     * no for the second half -- measured on the phone, where the download card
     * never went away however many times it was tapped.
     */
    suspend fun isPairReady(source: String, target: String): Boolean

    /**
     * Downloads what the pair needs. Progress is reported in bytes, because the
     * store name promises offline translation and the user is entitled to see
     * what that promise costs while it is being paid.
     */
    suspend fun downloadModels(
        source: String,
        target: String,
        wifiOnly: Boolean,
        onProgress: (downloaded: Long, total: Long) -> Unit = { _, _ -> }
    )

    /** Frees the space a language takes. */
    suspend fun deleteModel(code: String)

    suspend fun translate(text: String, source: String, target: String): String

    /** The language this text looks like, or null when the engine will not say. */
    suspend fun detectLanguage(text: String): String?

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
    private var detector: MLLocalLangDetector? = null

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

    override suspend fun downloadedLanguages(): Set<String> =
        MLLocalModelManager.getInstance()
            .getModels(MLLocalTranslatorModel::class.java)
            .await()
            .mapNotNull { it.languageCode }
            .toSet()

    override suspend fun isPairReady(source: String, target: String): Boolean =
        runCatching {
            // preparedModel() with no strategy resolves when the pair is already
            // on disk and fails when it is not: the only "usable offline" signal
            // the SDK offers.
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

    override suspend fun deleteModel(code: String) {
        val model = MLLocalTranslatorModel.Factory(code).create()
        MLLocalModelManager.getInstance().deleteModel(model).await()
        // The cached translator may hold the model that just went away.
        release()
    }

    override suspend fun translate(text: String, source: String, target: String): String =
        translatorFor(source, target).asyncTranslate(text).await()

    override suspend fun detectLanguage(text: String): String? {
        val active = detector ?: MLLangDetectorFactory.getInstance().localLangDetector
            .also { detector = it }
        val code = runCatching { active.firstBestDetect(text).await() }.getOrNull()
        // The detector answers "unknown" rather than failing when it will not
        // commit, and a caller must not turn that into a language.
        return code?.takeIf { it.isNotBlank() && !it.equals(UNDETECTED, ignoreCase = true) }
    }

    override fun release() {
        translator?.stop()
        translator = null
        pair = null
    }

    private companion object {
        const val UNDETECTED = "unknown"
    }
}
