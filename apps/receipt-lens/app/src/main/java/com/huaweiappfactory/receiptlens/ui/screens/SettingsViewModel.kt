package com.huaweiappfactory.receiptlens.ui.screens

import android.content.Context
import android.content.Intent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.receiptlens.ads.AdManager
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import com.huaweiappfactory.receiptlens.data.repository.UserPreferencesRepository
import com.huaweiappfactory.receiptlens.export.ReceiptCsvExporter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SettingsUiState(
    val defaultCurrency: String = "USD",
    val themeMode: String = "SYSTEM", // "SYSTEM", "LIGHT", "DARK"
    val isExporting: Boolean = false,
    val exportMessage: String? = null,
    val isPetalAdsReady: Boolean = false
)

class SettingsViewModel(
    private val userPreferencesRepository: UserPreferencesRepository,
    private val receiptRepository: ReceiptRepository,
    private val adManager: AdManager
) : ViewModel() {

    val uiState: StateFlow<SettingsUiState> = combine(
        userPreferencesRepository.defaultCurrency,
        userPreferencesRepository.themeMode
    ) { curr, theme ->
        SettingsUiState(
            defaultCurrency = curr,
            themeMode = theme,
            isPetalAdsReady = adManager.isAvailable()
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = SettingsUiState()
    )

    fun onCurrencySelected(currencyCode: String) {
        userPreferencesRepository.setDefaultCurrency(currencyCode)
    }

    fun onThemeSelected(themeMode: String) {
        userPreferencesRepository.setThemeMode(themeMode)
    }

    fun exportAllReceipts(context: Context) {
        viewModelScope.launch {
            val receipts = receiptRepository.getAllReceiptsSnapshot()
            val exportResult = ReceiptCsvExporter.exportReceiptsToCsv(context, receipts)
            exportResult.onSuccess { uri ->
                val shareIntent = ReceiptCsvExporter.createShareCsvIntent(context, uri)
                val chooser = Intent.createChooser(shareIntent, "Export Receipts CSV")
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(chooser)
            }
        }
    }

    companion object {
        fun provideFactory(
            userPreferencesRepository: UserPreferencesRepository,
            receiptRepository: ReceiptRepository,
            adManager: AdManager
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return SettingsViewModel(userPreferencesRepository, receiptRepository, adManager) as T
            }
        }
    }
}
