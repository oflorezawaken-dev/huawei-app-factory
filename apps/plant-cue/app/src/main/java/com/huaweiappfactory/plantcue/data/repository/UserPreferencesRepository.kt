package com.huaweiappfactory.plantcue.data.repository

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

class UserPreferencesRepository(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("plantcue_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_THEME_MODE = "pref_theme_mode" // SYSTEM, LIGHT, DARK
        private const val KEY_REMINDER_HOUR = "pref_reminder_hour" // 0..23
        private const val KEY_NOTIF_INTRO_SEEN = "pref_notif_intro_seen"
        const val DEFAULT_REMINDER_HOUR = 9
    }

    private fun <T> watch(key: String, read: () -> T): Flow<T> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, changed ->
            if (changed == key) trySend(read())
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        trySend(read())
        awaitClose { prefs.unregisterOnSharedPreferenceChangeListener(listener) }
    }

    val themeMode: Flow<String> = watch(KEY_THEME_MODE) { getThemeModeSync() }
    val reminderHour: Flow<Int> = watch(KEY_REMINDER_HOUR) { getReminderHourSync() }

    fun getThemeModeSync(): String = prefs.getString(KEY_THEME_MODE, "SYSTEM") ?: "SYSTEM"
    fun setThemeMode(mode: String) = prefs.edit().putString(KEY_THEME_MODE, mode).apply()

    fun getReminderHourSync(): Int = prefs.getInt(KEY_REMINDER_HOUR, DEFAULT_REMINDER_HOUR)
    fun setReminderHour(hour: Int) = prefs.edit().putInt(KEY_REMINDER_HOUR, hour.coerceIn(0, 23)).apply()

    fun isNotificationIntroSeen(): Boolean = prefs.getBoolean(KEY_NOTIF_INTRO_SEEN, false)
    fun setNotificationIntroSeen() = prefs.edit().putBoolean(KEY_NOTIF_INTRO_SEEN, true).apply()
}
