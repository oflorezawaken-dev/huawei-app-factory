package com.huaweiappfactory.translate.data.repository

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class ThemeChoice { SYSTEM, LIGHT, DARK }

/**
 * The few settings this app has. SharedPreferences rather than DataStore: four
 * scalars, read on the main thread once at startup, is not a job for a
 * coroutine-backed store.
 */
class UserPreferencesRepository(context: Context) {



    private val prefs = context.applicationContext
        .getSharedPreferences("translate_prefs", Context.MODE_PRIVATE)

    private val _theme = MutableStateFlow(readTheme())
    val theme: StateFlow<ThemeChoice> = _theme.asStateFlow()

    private val _historyEnabled = MutableStateFlow(prefs.getBoolean(KEY_HISTORY, true))
    val historyEnabled: StateFlow<Boolean> = _historyEnabled.asStateFlow()

    var lastSource: String
        get() = prefs.getString(KEY_SOURCE, null) ?: ""
        set(value) = prefs.edit().putString(KEY_SOURCE, value).apply()

    var lastTarget: String
        get() = prefs.getString(KEY_TARGET, null) ?: ""
        set(value) = prefs.edit().putString(KEY_TARGET, value).apply()

    private val _pairs = MutableStateFlow(prefs.getStringSet(KEY_PAIRS, emptySet()).orEmpty())

    /**
     * The pairs this app has downloaded, as "en|es".
     *
     * ML Kit's own inventory cannot answer this: it reports one language code
     * per model, and the model for English to Spanish is a single artifact, so
     * the list it returns names one side of each pair and looks like a lie on
     * screen. The app records what it downloaded itself.
     */
    val downloadedPairs: StateFlow<Set<String>> = _pairs.asStateFlow()

    fun rememberPair(source: String, target: String) = updatePairs { it + key(source, target) }

    fun forgetPair(source: String, target: String) = updatePairs { it - key(source, target) }

    private fun updatePairs(change: (Set<String>) -> Set<String>) {
        val next = change(_pairs.value)
        prefs.edit().putStringSet(KEY_PAIRS, next).apply()
        _pairs.value = next
    }

    fun setTheme(choice: ThemeChoice) {
        prefs.edit().putString(KEY_THEME, choice.name).apply()
        _theme.value = choice
    }

    fun setHistoryEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_HISTORY, enabled).apply()
        _historyEnabled.value = enabled
    }

    private fun readTheme(): ThemeChoice =
        runCatching { ThemeChoice.valueOf(prefs.getString(KEY_THEME, null) ?: "") }
            .getOrDefault(ThemeChoice.SYSTEM)

    companion object {
        private const val KEY_THEME = "theme"
        private const val KEY_HISTORY = "history_enabled"
        private const val KEY_SOURCE = "last_source"
        private const val KEY_TARGET = "last_target"
        private const val KEY_PAIRS = "downloaded_pairs"

        fun key(source: String, target: String) = "$source|$target"

        fun split(pair: String): Pair<String, String>? {
            val parts = pair.split("|")
            return if (parts.size == 2) parts[0] to parts[1] else null
        }
    }
}
