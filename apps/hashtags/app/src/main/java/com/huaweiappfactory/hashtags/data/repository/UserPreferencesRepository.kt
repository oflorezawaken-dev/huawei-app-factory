package com.huaweiappfactory.hashtags.data.repository

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

class UserPreferencesRepository(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("hashtags_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_THEME_MODE = "pref_theme_mode" // SYSTEM, LIGHT, DARK
        private const val KEY_OPEN_FULLY_SELECTED = "pref_open_fully_selected"
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
    val openFullySelected: Flow<Boolean> = watch(KEY_OPEN_FULLY_SELECTED) { isOpenFullySelected() }

    fun getThemeModeSync(): String = prefs.getString(KEY_THEME_MODE, "SYSTEM") ?: "SYSTEM"
    fun setThemeMode(mode: String) = prefs.edit().putString(KEY_THEME_MODE, mode).apply()

    /** Default on: the common case is copying a whole set, which is then one tap. */
    fun isOpenFullySelected(): Boolean = prefs.getBoolean(KEY_OPEN_FULLY_SELECTED, true)
    fun setOpenFullySelected(value: Boolean) =
        prefs.edit().putBoolean(KEY_OPEN_FULLY_SELECTED, value).apply()
}
