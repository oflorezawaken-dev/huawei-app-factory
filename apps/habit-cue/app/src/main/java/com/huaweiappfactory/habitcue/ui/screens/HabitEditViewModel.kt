package com.huaweiappfactory.habitcue.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.habitcue.data.repository.HabitRepository
import com.huaweiappfactory.habitcue.data.repository.HabitScheduleInput
import com.huaweiappfactory.habitcue.data.repository.UserPreferencesRepository
import com.huaweiappfactory.habitcue.data.repository.toSchedule
import com.huaweiappfactory.habitcue.domain.ScheduleType
import com.huaweiappfactory.habitcue.ui.theme.HABIT_COLOURS
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.DayOfWeek

data class HabitEditUiState(
    val isNew: Boolean = true,
    val loading: Boolean = true,
    val name: String = "",
    val colour: String = HABIT_COLOURS.first(),
    val scheduleType: ScheduleType = ScheduleType.DAILY,
    val weekdays: Set<DayOfWeek> = emptySet(),
    val timesPerWeek: Int = 3,
    val nameError: Boolean = false,
    val weekdaysError: Boolean = false,
    val saving: Boolean = false,
    val savedId: Long? = null,
    /** Ask for POST_NOTIFICATIONS right after the first habit is saved (once). */
    val askNotificationPermission: Boolean = false
)

class HabitEditViewModel(
    private val repo: HabitRepository,
    private val prefs: UserPreferencesRepository,
    private val habitId: Long
) : ViewModel() {

    private val _ui = MutableStateFlow(HabitEditUiState(isNew = habitId == 0L))
    val uiState: StateFlow<HabitEditUiState> = _ui.asStateFlow()

    init {
        viewModelScope.launch {
            if (habitId != 0L) {
                val habit = repo.getHabit(habitId)
                if (habit != null) {
                    val schedule = habit.toSchedule()
                    _ui.update {
                        it.copy(
                            loading = false, isNew = false,
                            name = habit.name,
                            colour = habit.colour,
                            scheduleType = schedule.type,
                            weekdays = schedule.weekdays,
                            timesPerWeek = if (schedule.timesPerWeek > 0) schedule.timesPerWeek else 3
                        )
                    }
                    return@launch
                }
            }
            _ui.update { it.copy(loading = false) }
        }
    }

    fun onName(v: String) = _ui.update { it.copy(name = v, nameError = false) }
    fun onColour(v: String) = _ui.update { it.copy(colour = v) }
    fun onScheduleType(v: ScheduleType) = _ui.update { it.copy(scheduleType = v, weekdaysError = false) }

    fun toggleWeekday(day: DayOfWeek) = _ui.update { s ->
        val set = s.weekdays.toMutableSet()
        if (day in set) set.remove(day) else set.add(day)
        s.copy(weekdays = set, weekdaysError = false)
    }

    fun onTimesPerWeek(v: Int) = _ui.update { it.copy(timesPerWeek = v.coerceIn(1, 7)) }

    fun save() {
        val s = _ui.value
        if (s.name.isBlank()) { _ui.update { it.copy(nameError = true) }; return }
        if (s.scheduleType == ScheduleType.SPECIFIC_WEEKDAYS && s.weekdays.isEmpty()) {
            _ui.update { it.copy(weekdaysError = true) }
            return
        }
        if (s.saving) return
        _ui.update { it.copy(saving = true) }
        viewModelScope.launch {
            val scheduleInput = HabitScheduleInput(type = s.scheduleType, weekdays = s.weekdays, timesPerWeek = s.timesPerWeek)
            val id = repo.saveHabit(habitId, s.name, s.colour, scheduleInput)
            val ask = !prefs.isNotificationIntroSeen()
            if (ask) prefs.setNotificationIntroSeen()
            _ui.update { it.copy(saving = false, savedId = id, askNotificationPermission = ask) }
        }
    }

    fun notificationPromptHandled() = _ui.update { it.copy(askNotificationPermission = false) }

    companion object {
        fun factory(repo: HabitRepository, prefs: UserPreferencesRepository, habitId: Long): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T = HabitEditViewModel(repo, prefs, habitId) as T
            }
    }
}
