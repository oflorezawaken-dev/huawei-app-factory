package com.huaweiappfactory.habitcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.habitcue.data.local.HabitEntity
import com.huaweiappfactory.habitcue.data.repository.HabitRepository
import com.huaweiappfactory.habitcue.data.repository.toSchedule
import com.huaweiappfactory.habitcue.domain.HabitSchedule
import com.huaweiappfactory.habitcue.domain.HabitScheduler
import com.huaweiappfactory.habitcue.domain.ScheduleType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.time.LocalDate

data class HabitDetailUiState(
    val loading: Boolean = true,
    val habit: HabitEntity? = null,
    val schedule: HabitSchedule = HabitSchedule(ScheduleType.DAILY),
    val completedDates: Set<LocalDate> = emptySet(),
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val displayedMonth: LocalDate = LocalDate.now().withDayOfMonth(1),
    val deleted: Boolean = false
)

class HabitDetailViewModel(private val repo: HabitRepository, private val habitId: Long) : ViewModel() {

    private val deleted = MutableStateFlow(false)
    private val displayedMonth = MutableStateFlow(LocalDate.now().withDayOfMonth(1))

    val uiState: StateFlow<HabitDetailUiState> = combine(
        repo.observeHabit(habitId), repo.observeCompletionsForHabit(habitId), deleted, displayedMonth
    ) { habit, completions, del, month ->
        val completed = completions.map { LocalDate.ofEpochDay(it.epochDay) }.toSet()
        if (habit == null) {
            HabitDetailUiState(loading = false, deleted = del)
        } else {
            val schedule = habit.toSchedule()
            val streaks = HabitScheduler.streaks(schedule, completed, LocalDate.ofEpochDay(habit.createdAtEpochDay), LocalDate.now())
            HabitDetailUiState(
                loading = false,
                habit = habit,
                schedule = schedule,
                completedDates = completed,
                currentStreak = streaks.current,
                longestStreak = streaks.longest,
                displayedMonth = month,
                deleted = del
            )
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), HabitDetailUiState())

    fun markDoneToday() = viewModelScope.launch { repo.markDone(habitId) }
    fun undoToday() = viewModelScope.launch { repo.undo(habitId) }
    fun previousMonth() { displayedMonth.value = displayedMonth.value.minusMonths(1) }
    fun nextMonth() { displayedMonth.value = displayedMonth.value.plusMonths(1) }
    fun delete() = viewModelScope.launch { repo.deleteHabit(habitId); deleted.value = true }

    companion object {
        fun factory(repo: HabitRepository, habitId: Long): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = HabitDetailViewModel(repo, habitId) as T
        }
    }
}
