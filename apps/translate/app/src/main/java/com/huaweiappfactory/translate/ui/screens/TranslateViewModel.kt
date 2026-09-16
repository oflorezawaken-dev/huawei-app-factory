package com.huaweiappfactory.translate.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.translate.data.repository.TranslationRepository
import com.huaweiappfactory.translate.data.repository.UserPreferencesRepository
import com.huaweiappfactory.translate.data.translate.TranslationEngine
import com.huaweiappfactory.translate.domain.Language
import com.huaweiappfactory.translate.domain.Languages
import com.huaweiappfactory.translate.domain.ModelSize
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** What went wrong, in terms the screen can phrase for a person. */
enum class TranslateError { DOWNLOAD_FAILED, TRANSLATION_FAILED, ENGINE_UNAVAILABLE }

data class TranslateUiState(
    val languages: List<Language> = emptyList(),
    val downloaded: Set<String> = emptySet(),
    val source: String = "",
    val target: String = "",
    val autoDetect: Boolean = true,
    val detected: String? = null,
    val input: String = "",
    val output: String = "",
    val pairReady: Boolean = false,
    val downloading: Boolean = false,
    val downloadedBytes: Long = 0,
    val totalBytes: Long = 0,
    val translating: Boolean = false,
    val error: TranslateError? = null
) {
    /** The language actually used as the source, once detection has had its say. */
    val effectiveSource: String get() = if (autoDetect) detected ?: source else source

    /** What the pair will cost, stated before it is needed. */
    val pendingBytes: Long
        get() = ModelSize.approxPairBytes(pairReady)

    val canTranslate: Boolean
        get() = pairReady && Languages.isTranslatable(effectiveSource, target) &&
            input.isNotBlank() && !translating && !downloading
}

class TranslateViewModel(
    private val engine: TranslationEngine,
    private val history: TranslationRepository,
    private val prefs: UserPreferencesRepository
) : ViewModel() {

    private val _state = MutableStateFlow(TranslateUiState())
    val state: StateFlow<TranslateUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch { loadLanguages() }
    }

    private suspend fun loadLanguages() {
        val supported = runCatching { engine.supportedLanguages() }.getOrNull()
        if (supported == null) {
            _state.update { it.copy(error = TranslateError.ENGINE_UNAVAILABLE) }
            return
        }
        val downloaded = runCatching { engine.downloadedLanguages() }.getOrDefault(emptySet())
        val languages = Languages.describe(supported)
        val source = prefs.lastSource.ifBlank { pick(supported, "en") }
        val target = prefs.lastTarget.ifBlank { pick(supported, "es", avoid = source) }
        _state.update {
            it.copy(
                languages = languages,
                downloaded = downloaded,
                source = source,
                target = target,
                error = null
            )
        }
        refreshPairReady()
    }

    /**
     * Asks the engine about the exact pair. Readiness cannot be derived from a
     * set of languages: ML Kit's unit is the pair.
     */
    private fun refreshPairReady() {
        val s = _state.value
        if (!Languages.isTranslatable(s.effectiveSource, s.target)) {
            _state.update { it.copy(pairReady = false) }
            return
        }
        viewModelScope.launch {
            val ready = engine.isPairReady(s.effectiveSource, s.target)
            _state.update { it.copy(pairReady = ready) }
        }
    }

    /** Falls back to whatever the engine does have rather than assuming English. */
    private fun pick(supported: Set<String>, wanted: String, avoid: String? = null): String =
        when {
            wanted in supported && wanted != avoid -> wanted
            else -> supported.sorted().firstOrNull { it != avoid } ?: ""
        }

    fun onInputChange(text: String) {
        _state.update { it.copy(input = text, error = null) }
        if (_state.value.autoDetect) detect(text)
    }

    private fun detect(text: String) {
        if (text.length < MIN_CHARS_TO_DETECT) {
            _state.update { it.copy(detected = null) }
            return
        }
        viewModelScope.launch {
            val code = engine.detectLanguage(text)
            // Only accept a detection the engine can actually translate from.
            val usable = code?.takeIf { c -> _state.value.languages.any { it.code == c } }
            val changed = usable != _state.value.detected
            _state.update { it.copy(detected = usable) }
            if (changed) refreshPairReady()
        }
    }

    fun onSourceChange(code: String) {
        prefs.lastSource = code
        _state.update { it.copy(source = code, autoDetect = false, output = "", error = null) }
        refreshPairReady()
    }

    fun onTargetChange(code: String) {
        prefs.lastTarget = code
        _state.update { it.copy(target = code, output = "", error = null) }
        refreshPairReady()
    }

    fun onAutoDetectChange(enabled: Boolean) {
        _state.update { it.copy(autoDetect = enabled, output = "") }
        if (enabled) detect(_state.value.input) else _state.update { it.copy(detected = null) }
        refreshPairReady()
    }

    /** Swaps the two languages, and the text with them when there is a result. */
    fun swap() {
        val s = _state.value
        val from = s.effectiveSource
        if (!Languages.isTranslatable(from, s.target)) return
        prefs.lastSource = s.target
        prefs.lastTarget = from
        _state.update {
            it.copy(
                source = it.target,
                target = from,
                autoDetect = false,
                detected = null,
                input = it.output.ifBlank { it.input },
                output = ""
            )
        }
        refreshPairReady()
    }

    fun download() {
        val s = _state.value
        if (s.downloading || !Languages.isTranslatable(s.effectiveSource, s.target)) return
        _state.update {
            it.copy(downloading = true, error = null, downloadedBytes = 0, totalBytes = 0)
        }
        viewModelScope.launch {
            runCatching {
                engine.downloadModels(s.effectiveSource, s.target, wifiOnly = false) { done, total ->
                    _state.update { it.copy(downloadedBytes = done, totalBytes = total) }
                }
            }.onSuccess {
                val downloaded = runCatching { engine.downloadedLanguages() }
                    .getOrDefault(_state.value.downloaded + s.effectiveSource + s.target)
                prefs.rememberPair(s.effectiveSource, s.target)
                _state.update { it.copy(downloading = false, downloaded = downloaded) }
                refreshPairReady()
            }.onFailure {
                _state.update {
                    it.copy(downloading = false, error = TranslateError.DOWNLOAD_FAILED)
                }
            }
        }
    }

    fun translate(onDone: () -> Unit = {}) {
        val s = _state.value
        if (!s.canTranslate) return
        _state.update { it.copy(translating = true, error = null) }
        viewModelScope.launch {
            runCatching { engine.translate(s.input, s.effectiveSource, s.target) }
                .onSuccess { result ->
                    _state.update { it.copy(translating = false, output = result) }
                    if (prefs.historyEnabled.value) {
                        history.record(s.effectiveSource, s.target, s.input, result)
                    }
                    onDone()
                }
                .onFailure {
                    // Never clear what the user typed because the engine failed.
                    _state.update {
                        it.copy(translating = false, error = TranslateError.TRANSLATION_FAILED)
                    }
                }
        }
    }

    /** Puts a history entry back on the screen, ready to be translated again. */
    fun restore(sourceLang: String, targetLang: String, text: String) {
        prefs.lastSource = sourceLang
        prefs.lastTarget = targetLang
        _state.update {
            it.copy(
                source = sourceLang,
                target = targetLang,
                autoDetect = false,
                detected = null,
                input = text,
                output = "",
                error = null
            )
        }
        refreshPairReady()
    }

    fun refreshDownloads() {
        viewModelScope.launch {
            val downloaded = runCatching { engine.downloadedLanguages() }.getOrNull()
            if (downloaded != null) _state.update { it.copy(downloaded = downloaded) }
        }
        refreshPairReady()
    }

    override fun onCleared() {
        engine.release()
        super.onCleared()
    }

    companion object {
        /** Below this, detection is guesswork dressed as an answer. */
        const val MIN_CHARS_TO_DETECT = 8

        fun factory(
            engine: TranslationEngine,
            history: TranslationRepository,
            prefs: UserPreferencesRepository
        ) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                TranslateViewModel(engine, history, prefs) as T
        }
    }
}
