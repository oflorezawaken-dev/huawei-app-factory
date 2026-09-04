package com.huaweiappfactory.receiptlens.ui.screens

import android.content.Context
import android.content.Intent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.receiptlens.data.local.ReceiptEntity
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import com.huaweiappfactory.receiptlens.export.ReceiptCsvExporter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class DetailUiState(
    val receipt: ReceiptEntity? = null,
    val isLoading: Boolean = true,
    val isDeleted: Boolean = false
)

class DetailViewModel(
    private val receiptRepository: ReceiptRepository,
    private val receiptId: Long
) : ViewModel() {

    private val _uiState = MutableStateFlow(DetailUiState())
    val uiState: StateFlow<DetailUiState> = _uiState.asStateFlow()

    init {
        loadReceipt()
    }

    private fun loadReceipt() {
        viewModelScope.launch {
            receiptRepository.getReceiptById(receiptId).collect { entity ->
                _uiState.update {
                    it.copy(
                        receipt = entity,
                        isLoading = false
                    )
                }
            }
        }
    }

    fun deleteReceipt(onDeleted: () -> Unit) {
        val currentReceipt = _uiState.value.receipt ?: return
        viewModelScope.launch {
            receiptRepository.deleteReceipt(currentReceipt)
            _uiState.update { it.copy(isDeleted = true) }
            onDeleted()
        }
    }

    fun shareReceipt(context: Context) {
        val currentReceipt = _uiState.value.receipt ?: return
        val textSummary = ReceiptCsvExporter.formatSingleReceiptSummary(context, currentReceipt)
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, "Receipt: ${currentReceipt.merchantName}")
            putExtra(Intent.EXTRA_TEXT, textSummary)
        }
        val chooser = Intent.createChooser(shareIntent, "Share Receipt")
        chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(chooser)
    }

    companion object {
        fun provideFactory(
            receiptRepository: ReceiptRepository,
            receiptId: Long
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return DetailViewModel(receiptRepository, receiptId) as T
            }
        }
    }
}
