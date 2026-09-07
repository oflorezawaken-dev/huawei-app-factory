package com.huaweiappfactory.plantcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.plantcue.data.local.PlantWithSchedules
import com.huaweiappfactory.plantcue.data.repository.PlantRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

enum class PlantSort { NEXT_DUE, NAME }

data class PlantsUiState(
    val loading: Boolean = true,
    val plants: List<PlantWithSchedules> = emptyList(),
    val rooms: List<String> = emptyList(),
    val roomFilter: String? = null,
    val sort: PlantSort = PlantSort.NEXT_DUE
)

class PlantsViewModel(private val repo: PlantRepository) : ViewModel() {

    private val roomFilter = MutableStateFlow<String?>(null)
    private val sort = MutableStateFlow(PlantSort.NEXT_DUE)

    val uiState: StateFlow<PlantsUiState> = combine(
        repo.observePlants(), repo.observeRooms(), roomFilter, sort
    ) { plants, rooms, filter, sortBy ->
        val filtered = if (filter == null) plants else plants.filter { it.plant.room == filter }
        val sorted = when (sortBy) {
            PlantSort.NAME -> filtered.sortedBy { it.plant.name.lowercase() }
            PlantSort.NEXT_DUE -> filtered.sortedBy { p -> p.schedules.minOfOrNull { it.nextDueEpochDay } ?: Long.MAX_VALUE }
        }
        PlantsUiState(loading = false, plants = sorted, rooms = rooms, roomFilter = filter, sort = sortBy)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), PlantsUiState())

    fun setRoomFilter(room: String?) { roomFilter.value = room }
    fun setSort(s: PlantSort) { sort.value = s }

    companion object {
        fun factory(repo: PlantRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = PlantsViewModel(repo) as T
        }
    }
}
