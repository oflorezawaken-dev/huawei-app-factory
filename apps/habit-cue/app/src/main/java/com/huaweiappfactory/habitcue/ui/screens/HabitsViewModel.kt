package com.huaweiappfactory.habitcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.habitcue.data.local.HabitEntity
import com.huaweiappfactory.habitcue.data.repository.HabitRepository
import com.huaweiappfactory.habitcue.data.repository.toSchedule
import com.huaweiappfactory.habitcue.domain.HabitSchedule
import com.huaweiappfactory.habitcue.domain.HabitScheduler
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate

enum class HabitSort { STREAK, NAME }

data class HabitRow(val habit: HabitEntity, val schedule: HabitSchedule, val currentStreak: Int)

data class HabitsUiState(
    val loading: Boolean = true,
    val habits: List<HabitRow> = emptyList(),
    val sort: HabitSort = HabitSort.STREAK
)

class HabitsViewModel(private val repo: HabitRepository) : ViewModel() {

    private val sort = MutableStateFlow(HabitSort.STREAK)

    val uiState: StateFlow<HabitsUiState> = combine(
        repo.observeHabits(), repo.observeAllCompletions(), sort
    ) { habits, completions, sortBy ->
        val today = LocalDate.now()
        val completedByHabit = completions
            .groupBy({ it.habitId }, { LocalDate.ofEpochDay(it.epochDay) })
            .mapValues { it.value.toSet() }
        val rows = habits.map { habit ->
            val schedule = habit.toSchedule()
            val completed = completedByHabit[habit.id] ?: emptySet()
            val streak = HabitScheduler.streaks(schedule, completed, LocalDate.ofEpochDay(habit.createdAtEpochDay), today).current
            HabitRow(habit, schedule, streak)
        }
        val sorted = when (sortBy) {
            HabitSort.NAME -> rows.sortedBy { it.habit.name.lowercase() }
            HabitSort.STREAK -> rows.sortedByDescending { it.currentStreak }
        }
        HabitsUiState(loading = false, habits = sorted, sort = sortBy)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), HabitsUiState())

    fun setSort(s: HabitSort) { sort.value = s }

    companion object {
        fun factory(repo: HabitRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = HabitsViewModel(repo) as T
        }
    }
}
