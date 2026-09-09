package com.huaweiappfactory.habitcue.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate

class HabitStatsCalculatorTest {

    // 2026-09-06, so month-to-date (Sep 1..6) is exactly 6 calendar days, regardless of weekday.
    private val today = LocalDate.of(2026, 9, 6)
    private val monthStart = today.withDayOfMonth(1)

    @Test
    fun `empty habit list gives zero stats and no completion rate`() {
        val stats = HabitStatsCalculator.compute(emptyList(), today)
        assertEquals(0, stats.habitCount)
        assertNull(stats.completionRatePercent)
        assertEquals(0, stats.completionsThisMonth)
        assertEquals(0, stats.bestStreak)
    }

    @Test
    fun `daily habit contributes one expected instance per day of the month so far`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        val completed = setOf(monthStart, monthStart.plusDays(1), monthStart.plusDays(2)) // 3 of 6 days done
        val input = HabitStatsInput(schedule, completed, createdOn = monthStart)
        val stats = HabitStatsCalculator.compute(listOf(input), today)
        assertEquals(3, stats.completionsThisMonth)
        assertEquals(50, stats.completionRatePercent) // 3 / 6
    }

    @Test
    fun `times per week habit contributes timesPerWeek expected instances per week touched`() {
        val schedule = HabitSchedule(ScheduleType.TIMES_PER_WEEK, timesPerWeek = 3)
        // createdOn == today: the period is exactly today's single week.
        val input = HabitStatsInput(schedule, completedDates = setOf(today), createdOn = today)
        val stats = HabitStatsCalculator.compute(listOf(input), today)
        assertEquals(1, stats.completionsThisMonth)
        assertEquals(33, stats.completionRatePercent) // 1 / 3
    }

    @Test
    fun `best streak is the maximum current streak across all habits`() {
        val short = HabitStatsInput(HabitSchedule(ScheduleType.DAILY), completedDates = setOf(today), createdOn = today)
        val long = HabitStatsInput(
            HabitSchedule(ScheduleType.DAILY),
            completedDates = setOf(today, today.minusDays(1), today.minusDays(2), today.minusDays(3)),
            createdOn = today.minusDays(3)
        )
        val stats = HabitStatsCalculator.compute(listOf(short, long), today)
        assertEquals(4, stats.bestStreak)
    }

    @Test
    fun `a habit created after the month started only counts days from its creation`() {
        val schedule = HabitSchedule(ScheduleType.DAILY)
        val createdOn = today.minusDays(1) // one day before today, still within this month
        val completed = setOf(createdOn, today) // both scheduled days done
        val input = HabitStatsInput(schedule, completed, createdOn)
        val stats = HabitStatsCalculator.compute(listOf(input), today)
        assertEquals(100, stats.completionRatePercent) // 2 expected, 2 completed
    }
}
