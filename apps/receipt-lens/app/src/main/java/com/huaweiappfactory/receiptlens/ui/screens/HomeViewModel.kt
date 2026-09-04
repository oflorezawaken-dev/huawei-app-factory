package com.huaweiappfactory.receiptlens.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.receiptlens.data.local.ReceiptEntity
import com.huaweiappfactory.receiptlens.data.model.OverallStatistics
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import com.huaweiappfactory.receiptlens.data.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class HomeUiState(
    val recentReceipts: List<ReceiptEntity> = emptyList(),
    val defaultCurrency: String = "USD",
    val totalAmountDefaultCurrency: Long = 0L,
    val thisMonthAmountDefaultCurrency: Long = 0L,
    val totalReceiptsCount: Int = 0,
    val hasCurrencies: List<String> = emptyList()
)

class HomeViewModel(
    private val receiptRepository: ReceiptRepository,
    private val userPreferencesRepository: UserPreferencesRepository
) : ViewModel() {

    val uiState: StateFlow<HomeUiState> = combine(
        receiptRepository.getRecentReceipts(limit = 5),
        receiptRepository.getStatistics(),
        userPreferencesRepository.defaultCurrency
    ) { recent, stats, defaultCurr ->
        val currencyData = stats.perCurrencySpending[defaultCurr.uppercase()]
            ?: stats.perCurrencySpending.values.firstOrNull()

        HomeUiState(
            recentReceipts = recent,
            defaultCurrency = currencyData?.currency ?: defaultCurr,
            totalAmountDefaultCurrency = currencyData?.totalAmount ?: 0L,
            thisMonthAmountDefaultCurrency = currencyData?.thisMonthAmount ?: 0L,
            totalReceiptsCount = stats.totalReceiptsCount,
            hasCurrencies = stats.perCurrencySpending.keys.toList()
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = HomeUiState()
    )

    companion object {
        fun provideFactory(
            receiptRepository: ReceiptRepository,
            userPreferencesRepository: UserPreferencesRepository
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return HomeViewModel(receiptRepository, userPreferencesRepository) as T
            }
        }
    }
}
