package com.huaweiappfactory.plantcue.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate

class StatsCalculatorTest {

    private val today = LocalDate.of(2026, 9, 6)

    private fun rec(dayOffset: Long, action: CareAction = CareAction.DONE, dueOffset: Long = dayOffset) = CareRecord(
        plantId = 1, type = CareType.WATER, action = action,
        on = today.plusDays(dayOffset), dueOn = today.plusDays(dueOffset)
    )

    @Test
    fun `empty history gives zero stats and no on-time rate`() {
        val s = StatsCalculator.compute(3, emptyList(), today)
        assertEquals(3, s.plantCount)
        assertEquals(0, s.eventsThisMonth)
        assertNull(s.onTimePercentThisMonth)
        assertEquals(0, s.streakDays)
    }

    @Test
    fun `on-time percentage counts only DONE events this month`() {
        val records = listOf(
            rec(0),                                  // done today, due today -> on time
            rec(-1, dueOffset = -3),                 // done 1 day ago, was due 3 days ago -> late
            rec(-2, action = CareAction.SNOOZED),    // snooze is not counted for on-time
            rec(-40)                                 // last month, ignored
        )
        val s = StatsCalculator.compute(2, records, today)
        assertEquals(3, s.eventsThisMonth)
        assertEquals(50, s.onTimePercentThisMonth)
    }

    @Test
    fun `streak counts consecutive days with a DONE event ending today`() {
        val records = listOf(rec(0), rec(-1), rec(-2), rec(-4))
        assertEquals(3, StatsCalculator.compute(1, records, today).streakDays)
    }

    @Test
    fun `streak survives when nothing was done yet today`() {
        val records = listOf(rec(-1), rec(-2))
        assertEquals(2, StatsCalculator.compute(1, records, today).streakDays)
    }

    @Test
    fun `snoozes do not extend a streak`() {
        val records = listOf(rec(0, action = CareAction.SNOOZED), rec(-1))
        assertEquals(1, StatsCalculator.compute(1, records, today).streakDays)
    }
}
