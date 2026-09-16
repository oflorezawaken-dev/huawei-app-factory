package com.huaweiappfactory.translate.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.translate.data.repository.ThemeChoice
import com.huaweiappfactory.translate.data.repository.TranslationRepository
import com.huaweiappfactory.translate.data.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class SettingsViewModel(
    private val prefs: UserPreferencesRepository,
    private val history: TranslationRepository
) : ViewModel() {

    val theme: StateFlow<ThemeChoice> = prefs.theme
    val historyEnabled: StateFlow<Boolean> = prefs.historyEnabled

    fun setTheme(choice: ThemeChoice) = prefs.setTheme(choice)

    /** Turning history off also empties it: leaving the old rows would be a lie. */
    fun setHistoryEnabled(enabled: Boolean) {
        prefs.setHistoryEnabled(enabled)
        if (!enabled) viewModelScope.launch { history.clear() }
    }

    fun clearHistory() = viewModelScope.launch { history.clear() }

    companion object {
        fun factory(prefs: UserPreferencesRepository, history: TranslationRepository) =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    SettingsViewModel(prefs, history) as T
            }
    }
}
