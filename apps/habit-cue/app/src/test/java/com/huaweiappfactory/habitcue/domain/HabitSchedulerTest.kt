package com.huaweiappfactory.habitcue.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

class HabitSchedulerTest {

    private val today = LocalDate.of(2026, 9, 6)
    private val monday = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))

    @Test
    fun `daily streak counts consecutive completed days ending today`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        val completed = setOf(today, today.minusDays(1), today.minusDays(2))
        val result = HabitScheduler.streaks(schedule, completed, today.minusDays(10), today)
        assertEquals(3, result.current)
        assertEquals(3, result.longest)
    }

    @Test
    fun `daily streak survives when today is not done yet`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        val completed = setOf(today.minusDays(1), today.minusDays(2))
        val result = HabitScheduler.streaks(schedule, completed, today.minusDays(10), today)
        assertEquals(2, result.current)
        assertEquals(2, result.longest)
    }

    @Test
    fun `daily streak breaks on a missed closed day`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        val completed = setOf(today, today.minusDays(2)) // yesterday missing
        val result = HabitScheduler.streaks(schedule, completed, today.minusDays(10), today)
        assertEquals(1, result.current)
        assertEquals(1, result.longest)
    }

    @Test
    fun `longest streak can exceed the current one after a gap`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        val completed = setOf(
            today.minusDays(9), today.minusDays(8), today.minusDays(7), today.minusDays(6), today.minusDays(5),
            today.minusDays(1), today
        )
        val result = HabitScheduler.streaks(schedule, completed, today.minusDays(9), today)
        assertEquals(2, result.current)
        assertEquals(5, result.longest)
    }

    @Test
    fun `specific weekdays streak skips unscheduled days without breaking it`() {
        val schedule = HabitSchedule(ScheduleType.SPECIFIC_WEEKDAYS, weekdays = setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.FRIDAY))
        val friday = monday.plusDays(4)
        val completed = setOf(monday, monday.plusDays(2), friday)
        val result = HabitScheduler.streaks(schedule, completed, monday, friday)
        assertEquals(3, result.current)
        assertEquals(3, result.longest)
    }

    @Test
    fun `times per week streak carries into an in-progress current week`() {
        val schedule = HabitSchedule(ScheduleType.TIMES_PER_WEEK, timesPerWeek = 2)
        val lastWeekMonday = monday.minusWeeks(1)
        // Last week: 2 completions, meets the target of 2. This week (in progress): only 1 so far.
        val completed = setOf(lastWeekMonday, lastWeekMonday.plusDays(3), monday)
        val wednesday = monday.plusDays(2)
        val result = HabitScheduler.streaks(schedule, completed, lastWeekMonday, wednesday)
        assertEquals(1, result.current)
        assertEquals(1, result.longest)
    }

    @Test
    fun `times per week streak resets after a week that missed the target`() {
        val schedule = HabitSchedule(ScheduleType.TIMES_PER_WEEK, timesPerWeek = 2)
        val week1Monday = monday.minusWeeks(2)
        val week2Monday = monday.minusWeeks(1)
        // Week 1 meets the target (2), week 2 misses it (1, closed), week 3 (current) has none yet.
        val completed = setOf(week1Monday, week1Monday.plusDays(3), week2Monday)
        val wednesday = monday.plusDays(2)
        val result = HabitScheduler.streaks(schedule, completed, week1Monday, wednesday)
        assertEquals(0, result.current)
        assertEquals(1, result.longest)
    }

    @Test
    fun `isDueOn hides a daily habit once completed for the day`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        assertTrue(HabitScheduler.isDueOn(schedule, emptySet(), today))
        assertFalse(HabitScheduler.isDueOn(schedule, setOf(today), today))
    }

    @Test
    fun `isDueOn for times per week drops off once done today even short of the weekly target`() {
        val schedule = HabitSchedule(ScheduleType.TIMES_PER_WEEK, timesPerWeek = 3)
        val completed = setOf(today)
        assertFalse(HabitScheduler.isDueOn(schedule, completed, today))
        assertTrue(HabitScheduler.isDueOn(schedule, completed, today.plusDays(1)))
    }

    @Test
    fun `isScheduledOn respects the chosen weekdays only`() {
        val schedule = HabitSchedule(ScheduleType.SPECIFIC_WEEKDAYS, weekdays = setOf(DayOfWeek.MONDAY))
        assertTrue(HabitScheduler.isScheduledOn(schedule, monday))
        assertFalse(HabitScheduler.isScheduledOn(schedule, monday.plusDays(1)))
    }

    @Test
    fun `weekday mask round-trips`() {
        val days = setOf(DayOfWeek.MONDAY, DayOfWeek.WEDNESDAY, DayOfWeek.SUNDAY)
        assertEquals(days, maskToWeekdays(weekdaysToMask(days)))
    }
}
