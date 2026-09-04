package com.huaweiappfactory.receiptlens.ui.screens

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.receiptlens.data.local.ReceiptEntity
import com.huaweiappfactory.receiptlens.data.repository.ReceiptRepository
import com.huaweiappfactory.receiptlens.data.repository.UserPreferencesRepository
import com.huaweiappfactory.receiptlens.domain.model.CurrencyInfo
import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory
import com.huaweiappfactory.receiptlens.ml.OcrResult
import com.huaweiappfactory.receiptlens.ml.OcrService
import com.huaweiappfactory.receiptlens.ml.ReceiptParser
import com.huaweiappfactory.receiptlens.util.CurrencyUtils
import com.huaweiappfactory.receiptlens.util.ImageStorageManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class ReviewUiState(
    val receiptId: Long = 0L,
    val isEditMode: Boolean = false,
    val imagePath: String? = null,
    val merchantName: String = "",
    val transactionDate: Long = System.currentTimeMillis(),
    val totalAmountString: String = "",
    val taxAmountString: String = "",
    val currency: String = "USD",
    val category: String = ReceiptCategory.OTHER.id,
    val notes: String = "",
    val rawOcrText: String? = null,
    val isOcrProcessing: Boolean = false,
    val ocrNoticeMessage: String? = null,
    val isLowConfidence: Boolean = false,
    val isSaving: Boolean = false,
    val saveSuccess: Boolean = false,
    val merchantError: String? = null,
    val totalError: String? = null
)

class ReviewViewModel(
    private val receiptRepository: ReceiptRepository,
    private val userPreferencesRepository: UserPreferencesRepository,
    private val ocrService: OcrService,
    private val context: Context,
    private val initialReceiptId: Long = 0L,
    private val initialImagePath: String? = null
) : ViewModel() {

    private val _uiState = MutableStateFlow(ReviewUiState(
        receiptId = initialReceiptId,
        isEditMode = initialReceiptId > 0L,
        imagePath = initialImagePath,
        currency = userPreferencesRepository.getDefaultCurrencySync()
    ))
    val uiState: StateFlow<ReviewUiState> = _uiState.asStateFlow()

    init {
        if (initialReceiptId > 0L) {
            loadExistingReceipt(initialReceiptId)
        } else if (!initialImagePath.isNullOrBlank()) {
            processImageOcr(initialImagePath)
        }
    }

    private fun loadExistingReceipt(id: Long) {
        viewModelScope.launch {
            val receipt = receiptRepository.getReceiptByIdSync(id) ?: return@launch
            _uiState.update {
                it.copy(
                    receiptId = receipt.id,
                    isEditMode = true,
                    imagePath = receipt.imagePath,
                    merchantName = receipt.merchantName,
                    transactionDate = receipt.transactionDate,
                    totalAmountString = CurrencyUtils.amountToDecimalString(receipt.totalAmount, receipt.currency),
                    taxAmountString = CurrencyUtils.amountToDecimalString(receipt.taxAmount, receipt.currency),
                    currency = receipt.currency,
                    category = receipt.category,
                    notes = receipt.notes ?: "",
                    rawOcrText = receipt.rawOcrText
                )
            }
        }
    }

    fun processImageFromUri(uri: Uri) {
        viewModelScope.launch {
            _uiState.update { it.copy(isOcrProcessing = true) }
            val saveResult = ImageStorageManager.saveImageFromUri(context, uri)
            saveResult.onSuccess { path ->
                _uiState.update { it.copy(imagePath = path) }
                processImageOcr(path)
            }.onFailure { err ->
                _uiState.update {
                    it.copy(
                        isOcrProcessing = false,
                        ocrNoticeMessage = "Failed to load image: ${err.localizedMessage}"
                    )
                }
            }
        }
    }

    private fun processImageOcr(path: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isOcrProcessing = true) }
            val bitmap = ImageStorageManager.loadBitmap(path)
            if (bitmap == null) {
                _uiState.update {
                    it.copy(
                        isOcrProcessing = false,
                        ocrNoticeMessage = "Could not decode receipt image"
                    )
                }
                return@launch
            }

            val defaultCurrency = userPreferencesRepository.getDefaultCurrencySync()
            when (val ocrResult = ocrService.processImage(bitmap)) {
                is OcrResult.Success -> {
                    val parsed = ReceiptParser.parse(ocrResult.rawText, defaultCurrency)
                    _uiState.update { current ->
                        current.copy(
                            isOcrProcessing = false,
                            merchantName = parsed.merchantName ?: current.merchantName,
                            transactionDate = parsed.transactionDate ?: current.transactionDate,
                            totalAmountString = parsed.totalAmount?.let {
                                CurrencyUtils.amountToDecimalString(it, parsed.currency)
                            } ?: current.totalAmountString,
                            taxAmountString = parsed.taxAmount?.let {
                                CurrencyUtils.amountToDecimalString(it, parsed.currency)
                            } ?: current.taxAmountString,
                            currency = parsed.currency,
                            category = parsed.category,
                            rawOcrText = ocrResult.rawText,
                            isLowConfidence = parsed.isConfidenceLow
                        )
                    }
                }
                is OcrResult.Unavailable -> {
                    // Graceful degrade to manual entry
                    _uiState.update {
                        it.copy(
                            isOcrProcessing = false,
                            ocrNoticeMessage = ocrResult.reason,
                            isLowConfidence = true
                        )
                    }
                }
                is OcrResult.Failure -> {
                    _uiState.update {
                        it.copy(
                            isOcrProcessing = false,
                            ocrNoticeMessage = ocrResult.message,
                            isLowConfidence = true
                        )
                    }
                }
            }
        }
    }

    fun onMerchantNameChange(name: String) {
        _uiState.update { it.copy(merchantName = name, merchantError = null) }
    }

    fun onDateChange(timestamp: Long) {
        _uiState.update { it.copy(transactionDate = timestamp) }
    }

    fun onTotalAmountChange(amount: String) {
        _uiState.update { it.copy(totalAmountString = amount, totalError = null) }
    }

    fun onTaxAmountChange(tax: String) {
        _uiState.update { it.copy(taxAmountString = tax) }
    }

    fun onCurrencyChange(currency: String) {
        _uiState.update { it.copy(currency = currency) }
    }

    fun onCategoryChange(category: String) {
        _uiState.update { it.copy(category = category) }
    }

    fun onNotesChange(notes: String) {
        _uiState.update { it.copy(notes = notes) }
    }

    fun dismissNotice() {
        _uiState.update { it.copy(ocrNoticeMessage = null) }
    }

    fun saveReceipt(onSaved: (Long) -> Unit) {
        val state = _uiState.value
        val merchant = state.merchantName.trim()
        val totalUnits = CurrencyUtils.parseAmountToMinorUnits(state.totalAmountString, state.currency)

        var hasError = false
        if (merchant.isBlank()) {
            _uiState.update { it.copy(merchantError = "Merchant name is required") }
            hasError = true
        }
        if (totalUnits == null || totalUnits <= 0) {
            _uiState.update { it.copy(totalError = "Valid total amount is required") }
            hasError = true
        }

        if (hasError) return

        val taxUnits = if (state.taxAmountString.isNotBlank()) {
            CurrencyUtils.parseAmountToMinorUnits(state.taxAmountString, state.currency)
        } else {
            null
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            val entity = ReceiptEntity(
                id = state.receiptId,
                merchantName = merchant,
                transactionDate = state.transactionDate,
                totalAmount = totalUnits!!,
                taxAmount = taxUnits,
                currency = state.currency,
                category = state.category,
                notes = state.notes.trim().ifEmpty { null },
                imagePath = state.imagePath,
                rawOcrText = state.rawOcrText
            )

            val savedId = if (state.isEditMode) {
                receiptRepository.updateReceipt(entity)
                entity.id
            } else {
                receiptRepository.insertReceipt(entity)
            }

            _uiState.update { it.copy(isSaving = false, saveSuccess = true) }
            onSaved(savedId)
        }
    }

    companion object {
        fun provideFactory(
            receiptRepository: ReceiptRepository,
            userPreferencesRepository: UserPreferencesRepository,
            ocrService: OcrService,
            context: Context,
            receiptId: Long,
            imagePath: String?
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return ReviewViewModel(
                    receiptRepository,
                    userPreferencesRepository,
                    ocrService,
                    context,
                    receiptId,
                    imagePath
                ) as T
            }
        }
    }
}
