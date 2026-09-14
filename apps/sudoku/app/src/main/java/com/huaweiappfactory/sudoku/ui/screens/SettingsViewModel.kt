package com.huaweiappfactory.sudoku.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.sudoku.data.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class SettingsViewModel(private val preferences: UserPreferencesRepository) : ViewModel() {

    val themeMode: StateFlow<String> = preferences.themeMode
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), preferences.getThemeModeSync())

    val highlightsEnabled: StateFlow<Boolean> = preferences.highlightsEnabled
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), preferences.isHighlightsEnabled())

    val mistakeLimitEnabled: StateFlow<Boolean> = preferences.mistakeLimitEnabled
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), preferences.isMistakeLimitEnabled())

    val timerVisible: StateFlow<Boolean> = preferences.timerVisible
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), preferences.isTimerVisible())

    fun setThemeMode(mode: String) = preferences.setThemeMode(mode)
    fun setHighlights(enabled: Boolean) = preferences.setHighlightsEnabled(enabled)
    fun setMistakeLimit(enabled: Boolean) = preferences.setMistakeLimitEnabled(enabled)
    fun setTimerVisible(visible: Boolean) = preferences.setTimerVisible(visible)

    companion object {
        fun factory(preferences: UserPreferencesRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = SettingsViewModel(preferences) as T
        }
    }
}
