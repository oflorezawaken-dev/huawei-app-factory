package com.huaweiappfactory.sudoku.data.repository

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

class UserPreferencesRepository(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("sudoku_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_THEME_MODE = "pref_theme_mode" // SYSTEM, LIGHT, DARK
        private const val KEY_HIGHLIGHTS = "pref_highlights"
        private const val KEY_MISTAKE_LIMIT = "pref_mistake_limit"
        private const val KEY_TIMER_VISIBLE = "pref_timer_visible"
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
    val highlightsEnabled: Flow<Boolean> = watch(KEY_HIGHLIGHTS) { isHighlightsEnabled() }
    val mistakeLimitEnabled: Flow<Boolean> = watch(KEY_MISTAKE_LIMIT) { isMistakeLimitEnabled() }
    val timerVisible: Flow<Boolean> = watch(KEY_TIMER_VISIBLE) { isTimerVisible() }

    fun getThemeModeSync(): String = prefs.getString(KEY_THEME_MODE, "SYSTEM") ?: "SYSTEM"
    fun setThemeMode(mode: String) = prefs.edit().putString(KEY_THEME_MODE, mode).apply()

    fun isHighlightsEnabled(): Boolean = prefs.getBoolean(KEY_HIGHLIGHTS, true)
    fun setHighlightsEnabled(enabled: Boolean) = prefs.edit().putBoolean(KEY_HIGHLIGHTS, enabled).apply()

    fun isMistakeLimitEnabled(): Boolean = prefs.getBoolean(KEY_MISTAKE_LIMIT, false)
    fun setMistakeLimitEnabled(enabled: Boolean) = prefs.edit().putBoolean(KEY_MISTAKE_LIMIT, enabled).apply()

    fun isTimerVisible(): Boolean = prefs.getBoolean(KEY_TIMER_VISIBLE, true)
    fun setTimerVisible(visible: Boolean) = prefs.edit().putBoolean(KEY_TIMER_VISIBLE, visible).apply()
}
