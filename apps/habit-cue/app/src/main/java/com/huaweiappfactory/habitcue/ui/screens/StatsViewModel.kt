package com.huaweiappfactory.habitcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.habitcue.data.repository.HabitRepository
import com.huaweiappfactory.habitcue.data.repository.toSchedule
import com.huaweiappfactory.habitcue.domain.HabitStats
import com.huaweiappfactory.habitcue.domain.HabitStatsCalculator
import com.huaweiappfactory.habitcue.domain.HabitStatsInput
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import java.time.LocalDate

class StatsViewModel(repo: HabitRepository) : ViewModel() {

    val stats: StateFlow<HabitStats?> = combine(repo.observeHabits(), repo.observeAllCompletions()) { habits, completions ->
        val completedByHabit = completions
            .groupBy({ it.habitId }, { LocalDate.ofEpochDay(it.epochDay) })
            .mapValues { it.value.toSet() }
        val inputs = habits.map { habit ->
            HabitStatsInput(
                schedule = habit.toSchedule(),
                completedDates = completedByHabit[habit.id] ?: emptySet(),
                createdOn = LocalDate.ofEpochDay(habit.createdAtEpochDay)
            )
        }
        HabitStatsCalculator.compute(inputs, LocalDate.now())
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    companion object {
        fun factory(repo: HabitRepository): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = StatsViewModel(repo) as T
        }
    }
}
