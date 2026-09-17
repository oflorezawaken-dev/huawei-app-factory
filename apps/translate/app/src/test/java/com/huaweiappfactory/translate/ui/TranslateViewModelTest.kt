package com.huaweiappfactory.translate.ui

import com.huaweiappfactory.translate.data.translate.TranslationEngine
import com.huaweiappfactory.translate.ui.screens.TranslateUiState
import com.huaweiappfactory.translate.domain.ModelSize
import kotlinx.coroutines.ExperimentalCoroutinesApi
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The state machine, without the SDK.
 *
 * TranslateViewModel itself needs a main dispatcher and a Room-backed
 * repository, so these tests exercise TranslateUiState directly: the rules
 * worth protecting -- what "ready" means, what a pair costs, what detection is
 * allowed to override -- all live there.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class TranslateViewModelTest {

    @Test
    fun `an unready pair states its cost, a ready one costs nothing`() {
        // Readiness is a pair question, answered by the engine: ML Kit's unit is
        // "translate-en_es", so a set of languages can never answer it.
        val notReady = TranslateUiState(source = "en", target = "es", autoDetect = false)
        assertFalse(notReady.pairReady)
        assertEquals(ModelSize.APPROX_BYTES_PER_PAIR, notReady.pendingBytes)

        val ready = notReady.copy(pairReady = true)
        assertEquals(0L, ready.pendingBytes)
    }

    @Test
    fun `detection replaces the source only while auto-detect is on`() {
        val auto = TranslateUiState(source = "en", target = "es", autoDetect = true, detected = "fr")
        assertEquals("fr", auto.effectiveSource)

        val manual = auto.copy(autoDetect = false)
        assertEquals("en", manual.effectiveSource)
    }

    @Test
    fun `auto-detect with nothing detected yet falls back to the chosen source`() {
        val state = TranslateUiState(source = "en", target = "es", autoDetect = true, detected = null)
        assertEquals("en", state.effectiveSource)
    }

    @Test
    fun `the same language on both sides is never translatable`() {
        val state = TranslateUiState(
            source = "en",
            target = "en",
            autoDetect = false,
            pairReady = true,
            input = "hello"
        )
        // The engine would never report a same-language pair as ready, but the
        // screen must not depend on that politeness.
        assertFalse(state.canTranslate)
    }

    @Test
    fun `translate is blocked while a download or a translation is running`() {
        val base = TranslateUiState(
            source = "en",
            target = "es",
            autoDetect = false,
            pairReady = true,
            input = "hello"
        )
        assertTrue(base.canTranslate)
        assertFalse(base.copy(downloading = true).canTranslate)
        assertFalse(base.copy(translating = true).canTranslate)
        assertFalse(base.copy(input = "   ").canTranslate)
    }

    @Test
    fun `the engine interface is implementable without any Huawei type`() {
        // Not a stand-in for a shipped build (factory rule 2): this is the whole
        // reason the interface exists, so ViewModels stay testable on the JVM.
        val fake = object : TranslationEngine {
            override suspend fun supportedLanguages() = setOf("en", "es")
            override suspend fun downloadedLanguages() = setOf("en")
            override suspend fun isPairReady(source: String, target: String) = true
            override suspend fun downloadModels(
                source: String,
                target: String,
                wifiOnly: Boolean,
                onProgress: (Long, Long) -> Unit
            ) = onProgress(1, 2)
            override suspend fun deleteModel(code: String) = Unit
            override suspend fun translate(text: String, source: String, target: String) = "hola"
            override suspend fun detectLanguage(text: String): String? = "en"
            override fun release() = Unit
        }
        assertTrue(fake is TranslationEngine)
    }
}
