package com.huaweiappfactory.plantcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.plantcue.data.repository.DueItem
import com.huaweiappfactory.plantcue.data.repository.PlantRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate

data class TodayUiState(
    val loading: Boolean = true,
    val plantCount: Int = 0,
    val overdue: List<DueItem> = emptyList(),
    val dueToday: List<DueItem> = emptyList()
)

class TodayViewModel(private val repo: PlantRepository) : ViewModel() {

    val uiState: StateFlow<TodayUiState> = combine(
        repo.observePlants(),
        repo.observePlantCount()
    ) { plants, count ->
        val today = LocalDate.now()
        val items = plants.flatMap { pws ->
            pws.schedules.filter { it.nextDueEpochDay <= today.toEpochDay() }.map { s ->
                DueItem(
                    plant = pws.plant,
                    schedule = s,
                    type = com.huaweiappfactory.plantcue.domain.CareType.valueOf(s.careType),
                    daysLate = today.toEpochDay() - s.nextDueEpochDay
                )
            }
        }.sortedByDescending { it.daysLate }
        TodayUiState(
            loading = false,
            plantCount = count,
            overdue = items.filter { it.daysLate > 0 },
            dueToday = items.filter { it.daysLate == 0L }
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), TodayUiState())

    fun markDone(scheduleId: Long) = viewModelScope.launch { repo.markDone(scheduleId) }
    fun snooze(scheduleId: Long) = viewModelScope.launch { repo.snooze(scheduleId) }

    companion object {
        fun factory(repo: PlantRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = TodayViewModel(repo) as T
        }
    }
}
