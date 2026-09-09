package com.huaweiappfactory.habitcue

import android.app.Application
import com.huaweiappfactory.habitcue.di.AppContainer
import com.huaweiappfactory.habitcue.di.DefaultAppContainer
import com.huaweiappfactory.habitcue.reminders.NotificationHelper
import com.huaweiappfactory.habitcue.reminders.ReminderScheduler

class HabitCueApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = DefaultAppContainer(this)
        NotificationHelper.ensureChannel(this)
        ReminderScheduler.schedule(this, container.userPreferencesRepository.getReminderHourSync())
    }
}
