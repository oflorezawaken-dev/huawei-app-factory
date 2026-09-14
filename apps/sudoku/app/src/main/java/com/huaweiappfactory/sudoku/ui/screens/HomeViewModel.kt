package com.huaweiappfactory.sudoku.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.sudoku.data.repository.GameRepository
import com.huaweiappfactory.sudoku.data.repository.SavedGameSummary
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class HomeViewModel(repository: GameRepository) : ViewModel() {

    /** Null when there is nothing to continue, which is also the state on a fresh install. */
    val savedGame: StateFlow<SavedGameSummary?> = repository.savedGameSummary
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    companion object {
        fun factory(repository: GameRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = HomeViewModel(repository) as T
        }
    }
}
