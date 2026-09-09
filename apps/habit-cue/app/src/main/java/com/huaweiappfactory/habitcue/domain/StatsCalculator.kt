package com.huaweiappfactory.habitcue.domain

import java.time.LocalDate

/** One habit as the calculator needs it, decoupled from the Room entity. */
data class HabitStatsInput(
    val schedule: HabitSchedule,
    val completedDates: Set<LocalDate>,
    val createdOn: LocalDate
)

data class HabitStats(
    val habitCount: Int,
    /** 0..100, or null when nothing was expected of any habit in the period yet. */
    val completionRatePercent: Int?,
    val completionsThisMonth: Int,
    /** The best current streak across all habits. */
    val bestStreak: Int
)

object HabitStatsCalculator {

    fun compute(inputs: List<HabitStatsInput>, today: LocalDate): HabitStats {
        val monthStart = today.withDayOfMonth(1)
        var expected = 0
        var completed = 0
        var completionsThisMonth = 0
        var bestStreak = 0

        for (input in inputs) {
            val streak = HabitScheduler.streaks(input.schedule, input.completedDates, input.createdOn, today).current
            if (streak > bestStreak) bestStreak = streak

            completionsThisMonth += input.completedDates.count { !it.isBefore(monthStart) && !it.isAfter(today) }

            val periodStart = maxOf(input.createdOn, monthStart)
            if (periodStart.isAfter(today)) continue

            when (input.schedule.type) {
                ScheduleType.DAILY, ScheduleType.SPECIFIC_WEEKDAYS -> {
                    var d = periodStart
                    while (!d.isAfter(today)) {
                        if (HabitScheduler.isScheduledOn(input.schedule, d)) {
                            expected++
                            if (d in input.completedDates) completed++
                        }
                        d = d.plusDays(1)
                    }
                }
                ScheduleType.TIMES_PER_WEEK -> {
                    val target = input.schedule.timesPerWeek.coerceAtLeast(1)
                    var weekStart = HabitScheduler.startOfWeek(periodStart)
                    val lastWeekStart = HabitScheduler.startOfWeek(today)
                    while (!weekStart.isAfter(lastWeekStart)) {
                        expected += target
                        weekStart = weekStart.plusWeeks(1)
                    }
                    completed += input.completedDates.count { !it.isBefore(periodStart) && !it.isAfter(today) }
                }
            }
        }

        val rate = if (expected == 0) null else ((completed * 100) / expected).coerceAtMost(100)
        return HabitStats(
            habitCount = inputs.size,
            completionRatePercent = rate,
            completionsThisMonth = completionsThisMonth,
            bestStreak = bestStreak
        )
    }
}
