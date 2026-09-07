package com.huaweiappfactory.plantcue.domain

import java.time.LocalDate

/** One care event as the calculator needs it (decoupled from the Room entity). */
data class CareRecord(
    val plantId: Long,
    val type: CareType,
    val action: CareAction,
    val on: LocalDate,
    /** The date the item was due when the action happened. */
    val dueOn: LocalDate
)

data class CareStats(
    val plantCount: Int,
    val eventsThisMonth: Int,
    /** 0..100, or null when there were no DONE events this month. */
    val onTimePercentThisMonth: Int?,
    /** Consecutive days, ending today or yesterday, with at least one DONE event. */
    val streakDays: Int
)

object StatsCalculator {

    fun compute(plantCount: Int, records: List<CareRecord>, today: LocalDate): CareStats {
        val monthStart = today.withDayOfMonth(1)
        val thisMonth = records.filter { !it.on.isBefore(monthStart) && !it.on.isAfter(today) }
        val doneThisMonth = thisMonth.filter { it.action == CareAction.DONE }
        val onTime = doneThisMonth.count { !it.on.isAfter(it.dueOn) }
        val onTimePercent = if (doneThisMonth.isEmpty()) null else (onTime * 100) / doneThisMonth.size

        val doneDays = records.filter { it.action == CareAction.DONE }.map { it.on }.toSet()
        var streak = 0
        var cursor = if (today in doneDays) today else today.minusDays(1)
        while (cursor in doneDays) {
            streak++
            cursor = cursor.minusDays(1)
        }

        return CareStats(
            plantCount = plantCount,
            eventsThisMonth = thisMonth.size,
            onTimePercentThisMonth = onTimePercent,
            streakDays = streak
        )
    }
}
