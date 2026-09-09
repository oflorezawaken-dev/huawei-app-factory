package com.huaweiappfactory.habitcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.habitcue.data.local.HabitEntity
import com.huaweiappfactory.habitcue.data.repository.HabitRepository
import com.huaweiappfactory.habitcue.data.repository.toSchedule
import com.huaweiappfactory.habitcue.domain.HabitSchedule
import com.huaweiappfactory.habitcue.domain.HabitScheduler
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate

data class TodayItem(val habit: HabitEntity, val schedule: HabitSchedule)

data class TodayUiState(
    val loading: Boolean = true,
    val habitCount: Int = 0,
    val due: List<TodayItem> = emptyList()
)

class TodayViewModel(private val repo: HabitRepository) : ViewModel() {

    val uiState: StateFlow<TodayUiState> = combine(
        repo.observeHabits(), repo.observeAllCompletions()
    ) { habits, completions ->
        val today = LocalDate.now()
        val completedByHabit = completions
            .groupBy({ it.habitId }, { LocalDate.ofEpochDay(it.epochDay) })
            .mapValues { it.value.toSet() }
        val due = habits.mapNotNull { habit ->
            val schedule = habit.toSchedule()
            val completed = completedByHabit[habit.id] ?: emptySet()
            if (HabitScheduler.isDueOn(schedule, completed, today)) TodayItem(habit, schedule) else null
        }
        TodayUiState(loading = false, habitCount = habits.size, due = due)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), TodayUiState())

    fun markDone(habitId: Long) = viewModelScope.launch { repo.markDone(habitId) }
    fun undo(habitId: Long) = viewModelScope.launch { repo.undo(habitId) }

    companion object {
        fun factory(repo: HabitRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = TodayViewModel(repo) as T
        }
    }
}
