package com.huaweiappfactory.translate.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.translate.data.translate.TranslationEngine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * The state of one translation, including the state nobody wants to design for:
 * the language pair is not on the phone yet and weighs tens of megabytes.
 */
data class TranslateUiState(
    val source: String = "en",
    val target: String = "es",
    val input: String = "",
    val output: String = "",
    val supported: Set<String> = emptySet(),
    val modelReady: Boolean = false,
    val downloading: Boolean = false,
    val downloadedBytes: Long = 0,
    val totalBytes: Long = 0,
    val busy: Boolean = false,
    val error: String? = null
)

class TranslateViewModel(private val engine: TranslationEngine) : ViewModel() {

    private val _state = MutableStateFlow(TranslateUiState())
    val state: StateFlow<TranslateUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch {
            runCatching { engine.supportedLanguages() }
                .onSuccess { langs -> _state.update { it.copy(supported = langs) } }
                .onFailure { e -> _state.update { it.copy(error = e.message ?: "ML Kit unavailable") } }
            refreshModelState()
        }
    }

    fun onInputChange(text: String) = _state.update { it.copy(input = text) }

    fun onSourceChange(code: String) {
        _state.update { it.copy(source = code, output = "") }
        viewModelScope.launch { refreshModelState() }
    }

    fun onTargetChange(code: String) {
        _state.update { it.copy(target = code, output = "") }
        viewModelScope.launch { refreshModelState() }
    }

    private suspend fun refreshModelState() {
        val s = _state.value
        val ready = engine.isModelReady(s.source, s.target)
        _state.update { it.copy(modelReady = ready) }
    }

    fun download() {
        val s = _state.value
        if (s.downloading) return
        _state.update { it.copy(downloading = true, error = null, downloadedBytes = 0, totalBytes = 0) }
        viewModelScope.launch {
            runCatching {
                engine.downloadModels(s.source, s.target, wifiOnly = false) { done, total ->
                    _state.update { it.copy(downloadedBytes = done, totalBytes = total) }
                }
            }
                .onSuccess { _state.update { it.copy(downloading = false, modelReady = true) } }
                .onFailure { e ->
                    _state.update { it.copy(downloading = false, error = e.message ?: "Download failed") }
                }
        }
    }

    fun translate() {
        val s = _state.value
        if (s.input.isBlank() || s.busy) return
        _state.update { it.copy(busy = true, error = null) }
        viewModelScope.launch {
            runCatching { engine.translate(s.input, s.source, s.target) }
                .onSuccess { out -> _state.update { it.copy(busy = false, output = out) } }
                .onFailure { e ->
                    _state.update { it.copy(busy = false, error = e.message ?: "Translation failed") }
                }
        }
    }

    override fun onCleared() {
        engine.release()
        super.onCleared()
    }

    companion object {
        fun factory(engine: TranslationEngine) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                TranslateViewModel(engine) as T
        }
    }
}
