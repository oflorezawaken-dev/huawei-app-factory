package com.huaweiappfactory.receiptlens.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.receiptlens.data.local.ReceiptEntity
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class HistoryUiState(
    val searchQuery: String = "",
    val selectedCategory: String = "ALL",
    val selectedCurrency: String = "ALL",
    val sortBy: String = "NEWEST", // "NEWEST", "OLDEST", "HIGHEST", "LOWEST"
    val availableCurrencies: List<String> = emptyList(),
    val receipts: List<ReceiptEntity> = emptyList(),
    val totalReceiptsInDb: Int = 0
)

class HistoryViewModel(
    private val receiptRepository: ReceiptRepository,
    initialCategory: String? = null
) : ViewModel() {

    private val _searchQuery = MutableStateFlow("")
    private val _selectedCategory = MutableStateFlow(initialCategory ?: "ALL")
    private val _selectedCurrency = MutableStateFlow("ALL")
    private val _sortBy = MutableStateFlow("NEWEST")

    @OptIn(ExperimentalCoroutinesApi::class)
    val uiState: StateFlow<HistoryUiState> = combine(
        _searchQuery,
        _selectedCategory,
        _selectedCurrency,
        _sortBy
    ) { query, category, currency, sort ->
        FilterParams(query, category, currency, sort)
    }.flatMapLatest { params ->
        combine(
            receiptRepository.searchReceipts(
                query = params.query,
                category = params.category,
                currency = params.currency,
                sortBy = params.sort
            ),
            receiptRepository.getDistinctCurrencies(),
            receiptRepository.getTotalCount()
        ) { receipts, currencies, totalCount ->
            HistoryUiState(
                searchQuery = params.query,
                selectedCategory = params.category,
                selectedCurrency = params.currency,
                sortBy = params.sort,
                availableCurrencies = currencies,
                receipts = receipts,
                totalReceiptsInDb = totalCount
            )
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = HistoryUiState(selectedCategory = initialCategory ?: "ALL")
    )

    private data class FilterParams(
        val query: String,
        val category: String,
        val currency: String,
        val sort: String
    )

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun onCategorySelect(category: String) {
        _selectedCategory.value = category
    }

    fun onCurrencySelect(currency: String) {
        _selectedCurrency.value = currency
    }

    fun onSortChange(sort: String) {
        _sortBy.value = sort
    }

    fun clearFilters() {
        _searchQuery.value = ""
        _selectedCategory.value = "ALL"
        _selectedCurrency.value = "ALL"
        _sortBy.value = "NEWEST"
    }

    fun deleteReceipt(receipt: ReceiptEntity) {
        viewModelScope.launch {
            receiptRepository.deleteReceipt(receipt)
        }
    }

    companion object {
        fun provideFactory(
            receiptRepository: ReceiptRepository,
            initialCategory: String? = null
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return HistoryViewModel(receiptRepository, initialCategory) as T
            }
        }
    }
}
