package com.huaweiappfactory.translate.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.translate.data.repository.UserPreferencesRepository
import com.huaweiappfactory.translate.data.translate.TranslationEngine
import com.huaweiappfactory.translate.domain.Language
import com.huaweiappfactory.translate.domain.Languages
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** A pair the phone has, named the way the user chose it. */
data class DownloadedPair(val source: String, val target: String, val label: String)

data class LanguagesUiState(
    val pairs: List<DownloadedPair> = emptyList(),
    val available: List<Language> = emptyList(),
    val busyPair: String? = null,
    val loading: Boolean = true,
    val failed: Boolean = false
)

/**
 * What is already on the phone, and how to get the space back.
 *
 * There is no "download" action here, and that is deliberate: ML Kit downloads
 * a PAIR, so a language on its own is not a thing that can be fetched. The only
 * honest place to offer a download is the Translate screen, where both ends of
 * the pair are known.
 */
class LanguagesViewModel(
    private val engine: TranslationEngine,
    private val prefs: UserPreferencesRepository
) : ViewModel() {

    private val _state = MutableStateFlow(LanguagesUiState())
    val state: StateFlow<LanguagesUiState> = _state.asStateFlow()

    init { refresh() }

    fun refresh() {
        viewModelScope.launch {
            val supported = runCatching { engine.supportedLanguages() }.getOrNull()
            if (supported == null) {
                _state.update { it.copy(loading = false, failed = true) }
                return@launch
            }
            val pairs = prefs.downloadedPairs.value.mapNotNull { stored ->
                UserPreferencesRepository.split(stored)?.let { (source, target) ->
                    DownloadedPair(
                        source = source,
                        target = target,
                        label = Languages.displayName(source) + " → " +
                            Languages.displayName(target)
                    )
                }
            }.sortedBy { it.label }
            _state.update {
                it.copy(
                    pairs = pairs,
                    available = Languages.describe(supported),
                    loading = false,
                    failed = false
                )
            }
        }
    }

    fun delete(pair: DownloadedPair) {
        val key = UserPreferencesRepository.key(pair.source, pair.target)
        if (_state.value.busyPair != null) return
        _state.update { it.copy(busyPair = key) }
        viewModelScope.launch {
            // The model file is named after the pair, and the SDK addresses it by
            // the target language code.
            runCatching { engine.deleteModel(pair.target) }
            prefs.forgetPair(pair.source, pair.target)
            _state.update { it.copy(busyPair = null) }
            refresh()
        }
    }

    companion object {
        fun factory(engine: TranslationEngine, prefs: UserPreferencesRepository) =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    LanguagesViewModel(engine, prefs) as T
            }
    }
}
