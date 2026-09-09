package com.huaweiappfactory.habitcue.data.repository

import com.huaweiappfactory.habitcue.data.local.HabitCompletionEntity
import com.huaweiappfactory.habitcue.data.local.HabitDao
import com.huaweiappfactory.habitcue.data.local.HabitEntity
import com.huaweiappfactory.habitcue.domain.HabitScheduler
import com.huaweiappfactory.habitcue.domain.HabitSchedule
import com.huaweiappfactory.habitcue.domain.ScheduleType
import com.huaweiappfactory.habitcue.domain.maskToWeekdays
import com.huaweiappfactory.habitcue.domain.weekdaysToMask
import kotlinx.coroutines.flow.Flow
import java.time.DayOfWeek
import java.time.LocalDate

/** Schedule as entered on the Add/Edit screen. */
data class HabitScheduleInput(
    val type: ScheduleType,
    val weekdays: Set<DayOfWeek> = emptySet(),
    val timesPerWeek: Int = 0
)

/** A habit still needing attention on a given day, for Today and the daily notification. */
data class DueHabit(val habit: HabitEntity, val schedule: HabitSchedule)

fun HabitEntity.toSchedule(): HabitSchedule = HabitSchedule(
    type = ScheduleType.valueOf(scheduleType),
    weekdays = maskToWeekdays(scheduleWeekdaysMask),
    timesPerWeek = scheduleTimesPerWeek
)

class HabitRepository(private val dao: HabitDao) {

    fun observeHabits(): Flow<List<HabitEntity>> = dao.observeHabits()
    fun observeHabit(id: Long): Flow<HabitEntity?> = dao.observeHabit(id)
    fun observeHabitCount(): Flow<Int> = dao.observeHabitCount()
    fun observeCompletionsForHabit(habitId: Long): Flow<List<HabitCompletionEntity>> = dao.observeCompletionsForHabit(habitId)
    fun observeAllCompletions(): Flow<List<HabitCompletionEntity>> = dao.observeAllCompletions()

    suspend fun getHabit(id: Long): HabitEntity? = dao.getHabit(id)
    suspend fun getCompletedDates(habitId: Long): Set<LocalDate> =
        dao.getCompletionsForHabitOnce(habitId).map { LocalDate.ofEpochDay(it.epochDay) }.toSet()

    /** Creates or updates a habit. Its creation date never changes once set. */
    suspend fun saveHabit(id: Long, name: String, colour: String, schedule: HabitScheduleInput, today: LocalDate = LocalDate.now()): Long {
        val createdAt = if (id == 0L) today.toEpochDay() else (dao.getHabit(id)?.createdAtEpochDay ?: today.toEpochDay())
        val entity = HabitEntity(
            id = id,
            name = name.trim(),
            colour = colour,
            scheduleType = schedule.type.name,
            scheduleWeekdaysMask = weekdaysToMask(schedule.weekdays),
            scheduleTimesPerWeek = schedule.timesPerWeek,
            createdAtEpochDay = createdAt
        )
        return if (id == 0L) dao.insertHabit(entity) else { dao.updateHabit(entity); id }
    }

    suspend fun deleteHabit(id: Long) {
        val h = dao.getHabit(id) ?: return
        dao.deleteHabit(h) // completions cascade
    }

    suspend fun markDone(habitId: Long, today: LocalDate = LocalDate.now()) {
        dao.insertCompletion(HabitCompletionEntity(habitId = habitId, epochDay = today.toEpochDay(), completedAtMillis = System.currentTimeMillis()))
    }

    suspend fun undo(habitId: Long, today: LocalDate = LocalDate.now()) {
        dao.deleteCompletion(habitId, today.toEpochDay())
    }

    /** Everything still due today, across all habits. */
    suspend fun dueToday(today: LocalDate = LocalDate.now()): List<DueHabit> {
        val habits = dao.getHabitsOnce()
        return habits.mapNotNull { h ->
            val schedule = h.toSchedule()
            val completed = getCompletedDates(h.id)
            if (HabitScheduler.isDueOn(schedule, completed, today)) DueHabit(h, schedule) else null
        }
    }

    suspend fun markAllDueDone(today: LocalDate = LocalDate.now()) {
        dueToday(today).forEach { markDone(it.habit.id, today) }
    }
}
