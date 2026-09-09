package com.huaweiappfactory.habitcue.reminders

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.huaweiappfactory.habitcue.HabitCueApplication
import java.time.Duration
import java.time.LocalDateTime
import java.time.LocalTime
import java.util.concurrent.TimeUnit

/**
 * Runs once a day around the configured hour and posts the summary notification
 * when something is due. Inexact by design (WorkManager periodic work): no exact
 * alarm permission, battery friendly, good enough for a habit reminder.
 */
class DailyReminderWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val container = (applicationContext as HabitCueApplication).container
        val due = runCatching { container.habitRepository.dueToday() }.getOrElse { return Result.retry() }
        NotificationHelper.showDailySummary(applicationContext, due)
        return Result.success()
    }
}

object ReminderScheduler {

    private const val UNIQUE_NAME = "daily_habit_reminder"

    /** (Re)schedules the daily check so the first run lands at the next [hour]:00. */
    fun schedule(context: Context, hour: Int) {
        val now = LocalDateTime.now()
        var next = now.toLocalDate().atTime(LocalTime.of(hour.coerceIn(0, 23), 0))
        if (!next.isAfter(now)) next = next.plusDays(1)
        val delay = Duration.between(now, next)

        val request = PeriodicWorkRequestBuilder<DailyReminderWorker>(24, TimeUnit.HOURS, 1, TimeUnit.HOURS)
            .setInitialDelay(delay.toMinutes(), TimeUnit.MINUTES)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            UNIQUE_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            request
        )
    }
}
