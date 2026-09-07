package com.huaweiappfactory.plantcue.domain

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

class SchedulerTest {

    private val today = LocalDate.of(2026, 9, 6)

    @Test
    fun `initial due date is one interval after creation`() {
        assertEquals(LocalDate.of(2026, 9, 13), Scheduler.initialNextDue(today, 7))
    }

    @Test
    fun `done moves next due one interval after the done day, across month boundary`() {
        assertEquals(LocalDate.of(2026, 10, 4), Scheduler.nextDueAfterDone(today, 28))
    }

    @Test
    fun `interval below one day is treated as one day`() {
        assertEquals(today.plusDays(1), Scheduler.nextDueAfterDone(today, 0))
    }

    @Test
    fun `snoozing an overdue item makes it due tomorrow, not the day after the old date`() {
        val overdue = today.minusDays(5)
        assertEquals(today.plusDays(1), Scheduler.snooze(overdue, today))
    }

    @Test
    fun `snoozing an upcoming item pushes it one more day`() {
        val upcoming = today.plusDays(3)
        assertEquals(today.plusDays(4), Scheduler.snooze(upcoming, today))
    }

    @Test
    fun `status and daysLate agree`() {
        assertEquals(DueStatus.OVERDUE, Scheduler.status(today.minusDays(2), today))
        assertEquals(2L, Scheduler.daysLate(today.minusDays(2), today))
        assertEquals(DueStatus.DUE_TODAY, Scheduler.status(today, today))
        assertEquals(0L, Scheduler.daysLate(today, today))
        assertEquals(DueStatus.UPCOMING, Scheduler.status(today.plusDays(1), today))
        assertEquals(-1L, Scheduler.daysLate(today.plusDays(1), today))
    }
}
