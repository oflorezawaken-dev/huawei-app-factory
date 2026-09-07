package com.huaweiappfactory.plantcue.domain

import java.time.LocalDate

/** The kinds of care PlantCue can remind about. */
enum class CareType(val defaultIntervalDays: Int) {
    WATER(7),
    FERTILISE(28),
    MIST(3)
}

/** What the user did about a due care item. */
enum class CareAction { DONE, SNOOZED }

/** Where a schedule stands relative to today. */
enum class DueStatus { OVERDUE, DUE_TODAY, UPCOMING }

/**
 * Pure scheduling rules. No Android, no clock: callers pass `today`, which keeps
 * this trivially unit-testable and deterministic.
 */
object Scheduler {

    /** A schedule created today is due after one full interval. */
    fun initialNextDue(createdOn: LocalDate, intervalDays: Int): LocalDate =
        createdOn.plusDays(intervalDays.coerceAtLeast(1).toLong())

    /** After "Done", the next due date is one interval after the day it was done. */
    fun nextDueAfterDone(doneOn: LocalDate, intervalDays: Int): LocalDate =
        doneOn.plusDays(intervalDays.coerceAtLeast(1).toLong())

    /**
     * "Snooze" pushes the item to tomorrow. An overdue item snoozed today is due
     * tomorrow, not "yesterday + 1", so it does not stay overdue forever.
     */
    fun snooze(nextDue: LocalDate, today: LocalDate): LocalDate =
        maxOf(nextDue, today).plusDays(1)

    fun status(nextDue: LocalDate, today: LocalDate): DueStatus = when {
        nextDue.isBefore(today) -> DueStatus.OVERDUE
        nextDue.isEqual(today) -> DueStatus.DUE_TODAY
        else -> DueStatus.UPCOMING
    }

    /** Positive when overdue, zero when due today, negative when upcoming. */
    fun daysLate(nextDue: LocalDate, today: LocalDate): Long =
        today.toEpochDay() - nextDue.toEpochDay()
}
