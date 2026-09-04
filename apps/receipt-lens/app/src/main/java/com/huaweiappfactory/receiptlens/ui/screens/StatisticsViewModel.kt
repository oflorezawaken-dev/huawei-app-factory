package com.huaweiappfactory.receiptlens.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.receiptlens.data.model.CurrencySpending
import com.huaweiappfactory.receiptlens.data.model.OverallStatistics
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import com.huaweiappfactory.receiptlens.data.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update

data class StatisticsUiState(
    val statistics: OverallStatistics = OverallStatistics(0, emptyMap()),
    val selectedCurrency: String = "USD",
    val availableCurrencies: List<String> = emptyList(),
    val currentCurrencySpending: CurrencySpending? = null
)

class StatisticsViewModel(
    private val receiptRepository: ReceiptRepository,
    private val userPreferencesRepository: UserPreferencesRepository
) : ViewModel() {

    private val _selectedCurrency = MutableStateFlow<String?>(null)

    val uiState: StateFlow<StatisticsUiState> = combine(
        receiptRepository.getStatistics(),
        userPreferencesRepository.defaultCurrency,
        _selectedCurrency
    ) { stats, defaultCurr, chosenCurr ->
        val available = stats.perCurrencySpending.keys.toList()
        val activeCurrency = chosenCurr ?: available.firstOrNull() ?: defaultCurr
        val spending = stats.perCurrencySpending[activeCurrency.uppercase()]

        StatisticsUiState(
            statistics = stats,
            selectedCurrency = activeCurrency,
            availableCurrencies = available,
            currentCurrencySpending = spending
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = StatisticsUiState()
    )

    fun onSelectCurrency(currency: String) {
        _selectedCurrency.value = currency
    }

    companion object {
        fun provideFactory(
            receiptRepository: ReceiptRepository,
            userPreferencesRepository: UserPreferencesRepository
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return StatisticsViewModel(receiptRepository, userPreferencesRepository) as T
            }
        }
    }
}
