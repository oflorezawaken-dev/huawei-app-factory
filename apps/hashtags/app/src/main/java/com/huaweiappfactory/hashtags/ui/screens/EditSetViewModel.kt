package com.huaweiappfactory.hashtags.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.hashtags.data.repository.HashtagRepository
import com.huaweiappfactory.hashtags.domain.Tags
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class EditUiState(
    val loading: Boolean = true,
    val isNew: Boolean = true,
    val name: String = "",
    val tags: List<String> = emptyList(),
    val draft: String = "",
    /** The tag a duplicate was rejected for, so the screen can say which one. */
    val duplicate: String? = null,
    val saved: Boolean = false,
    val deleted: Boolean = false
) {
    val canSave: Boolean get() = name.isNotBlank() && tags.isNotEmpty()
}

class EditSetViewModel(
    private val repository: HashtagRepository,
    private val rowId: Long
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditUiState())
    val uiState: StateFlow<EditUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            if (rowId <= 0L) {
                _uiState.value = EditUiState(loading = false, isNew = true)
            } else {
                val existing = repository.customSet(rowId)
                _uiState.value = EditUiState(
                    loading = false,
                    isNew = existing == null,
                    name = existing?.customName.orEmpty(),
                    tags = existing?.tags.orEmpty()
                )
            }
        }
    }

    fun onNameChange(value: String) {
        _uiState.value = _uiState.value.copy(name = value)
    }

    fun onDraftChange(value: String) {
        _uiState.value = _uiState.value.copy(draft = value, duplicate = null)
    }

    /**
     * Adds whatever is in the draft field. Tags.addTo does the normalising and the
     * duplicate check, so "Travel", "#travel" and " travel " all collapse to one.
     */
    fun addDraft() {
        val state = _uiState.value
        val added = Tags.addTo(state.tags, state.draft)
        if (added == null) {
            val normalised = Tags.normalise(state.draft)
            _uiState.value = state.copy(duplicate = normalised, draft = if (normalised == null) "" else state.draft)
            return
        }
        _uiState.value = state.copy(tags = added, draft = "", duplicate = null)
    }

    fun removeTag(tag: String) {
        _uiState.value = _uiState.value.copy(tags = _uiState.value.tags - tag)
    }

    fun save() = viewModelScope.launch {
        val state = _uiState.value
        if (!state.canSave) return@launch
        if (rowId > 0L) {
            repository.updateCustomSet(rowId, state.name, state.tags)
        } else {
            repository.createCustomSet(state.name, state.tags)
        }
        _uiState.value = state.copy(saved = true)
    }

    fun delete() = viewModelScope.launch {
        if (rowId > 0L) repository.deleteCustomSet(rowId)
        _uiState.value = _uiState.value.copy(deleted = true)
    }

    companion object {
        fun factory(repository: HashtagRepository, rowId: Long): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    EditSetViewModel(repository, rowId) as T
            }
    }
}
