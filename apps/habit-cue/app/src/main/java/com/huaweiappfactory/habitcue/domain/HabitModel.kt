package com.huaweiappfactory.habitcue.domain

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

/** How a habit repeats. */
enum class ScheduleType { DAILY, SPECIFIC_WEEKDAYS, TIMES_PER_WEEK }

/**
 * A habit's repeat rule. [weekdays] is only meaningful for [ScheduleType.SPECIFIC_WEEKDAYS];
 * [timesPerWeek] only for [ScheduleType.TIMES_PER_WEEK].
 */
data class HabitSchedule(
    val type: ScheduleType,
    val weekdays: Set<DayOfWeek> = emptySet(),
    val timesPerWeek: Int = 0
)

/** How many consecutive units (days or weeks, depending on the schedule) are complete. */
data class StreakResult(val current: Int, val longest: Int)

/**
 * Pure scheduling and streak rules. No Android, no clock: callers pass `today`, which
 * keeps this trivially unit-testable and deterministic.
 */
object HabitScheduler {

    /** True when [date] is one of the habit's scheduled days (always true for TIMES_PER_WEEK,
     * which has no fixed days -- any day can count toward the weekly target). */
    fun isScheduledOn(schedule: HabitSchedule, date: LocalDate): Boolean = when (schedule.type) {
        ScheduleType.DAILY -> true
        ScheduleType.SPECIFIC_WEEKDAYS -> date.dayOfWeek in schedule.weekdays
        ScheduleType.TIMES_PER_WEEK -> true
    }

    /** True when the habit still needs attention on [date] given what has already been completed. */
    fun isDueOn(schedule: HabitSchedule, completedDates: Set<LocalDate>, date: LocalDate): Boolean =
        when (schedule.type) {
            ScheduleType.DAILY, ScheduleType.SPECIFIC_WEEKDAYS ->
                isScheduledOn(schedule, date) && date !in completedDates
            ScheduleType.TIMES_PER_WEEK -> {
                val start = startOfWeek(date)
                val doneThisWeek = completedDates.count { it in start..start.plusDays(6) }
                // Once today is itself marked done it drops off Today even if the weekly
                // target is not yet reached; it can be done again on a different day this week.
                date !in completedDates && doneThisWeek < schedule.timesPerWeek.coerceAtLeast(1)
            }
        }

    /** Monday of the ISO week containing [date]. */
    fun startOfWeek(date: LocalDate): LocalDate =
        date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))

    /**
     * Single forward pass from [createdOn] to [today] computing both the live streak and the
     * best one ever seen. The final unit (today for day-based schedules, the current week for
     * TIMES_PER_WEEK) gets a grace exception: if it is not yet satisfied, the run is left
     * unchanged rather than reset, because that unit has not closed yet. Every earlier unit
     * either extends the run (met) or resets it to zero (a closed unit that was missed);
     * an unscheduled day for SPECIFIC_WEEKDAYS is simply skipped, neither extending nor resetting.
     */
    fun streaks(
        schedule: HabitSchedule,
        completedDates: Set<LocalDate>,
        createdOn: LocalDate,
        today: LocalDate
    ): StreakResult {
        var run = 0
        var longest = 0
        when (schedule.type) {
            ScheduleType.DAILY, ScheduleType.SPECIFIC_WEEKDAYS -> {
                var d = createdOn
                while (!d.isAfter(today)) {
                    if (isScheduledOn(schedule, d)) {
                        val done = d in completedDates
                        if (done) {
                            run++
                            if (run > longest) longest = run
                        } else if (d != today) {
                            run = 0
                        }
                    }
                    d = d.plusDays(1)
                }
            }
            ScheduleType.TIMES_PER_WEEK -> {
                val target = schedule.timesPerWeek.coerceAtLeast(1)
                val currentWeekStart = startOfWeek(today)
                var weekStart = startOfWeek(createdOn)
                while (!weekStart.isAfter(currentWeekStart)) {
                    val count = completedDates.count { it in weekStart..weekStart.plusDays(6) }
                    val met = count >= target
                    if (met) {
                        run++
                        if (run > longest) longest = run
                    } else if (weekStart != currentWeekStart) {
                        run = 0
                    }
                    weekStart = weekStart.plusWeeks(1)
                }
            }
        }
        return StreakResult(current = run, longest = longest)
    }
}

fun weekdaysToMask(days: Set<DayOfWeek>): Int = days.fold(0) { acc, d -> acc or (1 shl (d.value - 1)) }

fun maskToWeekdays(mask: Int): Set<DayOfWeek> =
    DayOfWeek.entries.filter { (mask shr (it.value - 1)) and 1 == 1 }.toSet()
