package com.huaweiappfactory.plantcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.plantcue.data.repository.PlantRepository
import com.huaweiappfactory.plantcue.domain.CareStats
import com.huaweiappfactory.plantcue.domain.StatsCalculator
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate

class StatsViewModel(repo: PlantRepository) : ViewModel() {

    val stats: StateFlow<CareStats?> = combine(repo.observePlantCount(), repo.observeCareRecords()) { count, records ->
        StatsCalculator.compute(count, records, LocalDate.now())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    companion object {
        fun factory(repo: PlantRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = StatsViewModel(repo) as T
        }
    }
}
