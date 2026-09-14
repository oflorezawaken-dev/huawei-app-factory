package com.huaweiappfactory.hashtags.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.hashtags.data.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class SettingsViewModel(private val preferences: UserPreferencesRepository) : ViewModel() {

    val themeMode: StateFlow<String> = preferences.themeMode
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), preferences.getThemeModeSync())

    val openFullySelected: StateFlow<Boolean> = preferences.openFullySelected
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), preferences.isOpenFullySelected())

    fun setThemeMode(mode: String) = preferences.setThemeMode(mode)
    fun setOpenFullySelected(value: Boolean) = preferences.setOpenFullySelected(value)

    companion object {
        fun factory(preferences: UserPreferencesRepository): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    SettingsViewModel(preferences) as T
            }
    }
}
