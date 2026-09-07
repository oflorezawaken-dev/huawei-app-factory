package com.huaweiappfactory.plantcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.plantcue.data.local.CareEventEntity
import com.huaweiappfactory.plantcue.data.local.PlantWithSchedules
import com.huaweiappfactory.plantcue.data.repository.PlantRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class PlantDetailUiState(
    val loading: Boolean = true,
    val plant: PlantWithSchedules? = null,
    val events: List<CareEventEntity> = emptyList(),
    val deleted: Boolean = false
)

class PlantDetailViewModel(private val repo: PlantRepository, private val plantId: Long) : ViewModel() {

    private val deleted = MutableStateFlow(false)

    val uiState: StateFlow<PlantDetailUiState> = combine(
        repo.observePlant(plantId), repo.observeEventsForPlant(plantId), deleted
    ) { plant, events, del ->
        PlantDetailUiState(loading = false, plant = plant, events = events, deleted = del)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PlantDetailUiState())

    fun markDone(scheduleId: Long) = viewModelScope.launch { repo.markDone(scheduleId) }
    fun snooze(scheduleId: Long) = viewModelScope.launch { repo.snooze(scheduleId) }
    fun delete() = viewModelScope.launch { repo.deletePlant(plantId); deleted.value = true }

    companion object {
        fun factory(repo: PlantRepository, plantId: Long): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = PlantDetailViewModel(repo, plantId) as T
        }
    }
}
