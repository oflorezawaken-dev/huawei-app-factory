package com.huaweiappfactory.plantcue

import android.app.Application
import com.huaweiappfactory.plantcue.di.AppContainer
import com.huaweiappfactory.plantcue.di.DefaultAppContainer
import com.huaweiappfactory.plantcue.reminders.NotificationHelper
import com.huaweiappfactory.plantcue.reminders.ReminderScheduler

class PlantCueApplication : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = DefaultAppContainer(this)
        NotificationHelper.ensureChannel(this)
        ReminderScheduler.schedule(this, container.userPreferencesRepository.getReminderHourSync())
    }
}
