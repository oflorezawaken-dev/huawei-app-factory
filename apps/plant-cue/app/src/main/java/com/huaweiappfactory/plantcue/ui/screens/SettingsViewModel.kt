package com.huaweiappfactory.plantcue.ui.screens

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.plantcue.data.repository.UserPreferencesRepository
import com.huaweiappfactory.plantcue.reminders.ReminderScheduler
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class SettingsUiState(val themeMode: String = "SYSTEM", val reminderHour: Int = UserPreferencesRepository.DEFAULT_REMINDER_HOUR)

class SettingsViewModel(private val prefs: UserPreferencesRepository) : ViewModel() {

    val uiState: StateFlow<SettingsUiState> = combine(prefs.themeMode, prefs.reminderHour) { theme, hour ->
        SettingsUiState(theme, hour)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), SettingsUiState())

    fun setTheme(mode: String) = prefs.setThemeMode(mode)

    fun setReminderHour(context: Context, hour: Int) {
        prefs.setReminderHour(hour)
        ReminderScheduler.schedule(context, hour)
    }

    companion object {
        fun factory(prefs: UserPreferencesRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = SettingsViewModel(prefs) as T
        }
    }
}
