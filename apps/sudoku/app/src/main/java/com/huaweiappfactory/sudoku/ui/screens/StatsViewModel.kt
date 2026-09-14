package com.huaweiappfactory.sudoku.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.sudoku.data.repository.GameRepository
import com.huaweiappfactory.sudoku.domain.OverallStats
import com.huaweiappfactory.sudoku.domain.StatsCalculator
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

class StatsViewModel(repository: GameRepository) : ViewModel() {

    val stats: StateFlow<OverallStats?> = repository.outcomes
        .map { StatsCalculator.compute(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    companion object {
        fun factory(repository: GameRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = StatsViewModel(repository) as T
        }
    }
}
