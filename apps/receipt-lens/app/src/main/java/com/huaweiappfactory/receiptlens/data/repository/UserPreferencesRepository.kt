package com.huaweiappfactory.receiptlens.data.repository

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import java.util.Locale

class UserPreferencesRepository(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("receiptlens_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_DEFAULT_CURRENCY = "pref_default_currency"
        private const val KEY_THEME_MODE = "pref_theme_mode" // SYSTEM, LIGHT, DARK
    }

    val defaultCurrency: Flow<String> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == KEY_DEFAULT_CURRENCY) {
                trySend(getDefaultCurrencySync())
            }
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        trySend(getDefaultCurrencySync())
        awaitClose { prefs.unregisterOnSharedPreferenceChangeListener(listener) }
    }

    val themeMode: Flow<String> = callbackFlow {
        val listener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            if (key == KEY_THEME_MODE) {
                trySend(getThemeModeSync())
            }
        }
        prefs.registerOnSharedPreferenceChangeListener(listener)
        trySend(getThemeModeSync())
        awaitClose { prefs.unregisterOnSharedPreferenceChangeListener(listener) }
    }

    fun getDefaultCurrencySync(): String {
        return prefs.getString(KEY_DEFAULT_CURRENCY, null) ?: inferLocaleCurrency()
    }

    fun setDefaultCurrency(currencyCode: String) {
        prefs.edit().putString(KEY_DEFAULT_CURRENCY, currencyCode).apply()
    }

    fun getThemeModeSync(): String {
        return prefs.getString(KEY_THEME_MODE, "SYSTEM") ?: "SYSTEM"
    }

    fun setThemeMode(themeMode: String) {
        prefs.edit().putString(KEY_THEME_MODE, themeMode).apply()
    }

    private fun inferLocaleCurrency(): String {
        return try {
            val currency = java.util.Currency.getInstance(Locale.getDefault())
            currency.currencyCode
        } catch (_: Exception) {
            "USD"
        }
    }
}
