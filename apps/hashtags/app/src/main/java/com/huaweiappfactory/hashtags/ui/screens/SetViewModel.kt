package com.huaweiappfactory.hashtags.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.hashtags.data.repository.HashtagRepository
import com.huaweiappfactory.hashtags.data.repository.UserPreferencesRepository
import com.huaweiappfactory.hashtags.domain.HashtagSet
import com.huaweiappfactory.hashtags.domain.Tags
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

data class SetUiState(
    val loading: Boolean = true,
    val set: HashtagSet? = null,
    val selected: Set<String> = emptySet(),
    val favourites: Set<String> = emptySet()
) {
    val selectedCount: Int get() = selected.size
    val isOverLimit: Boolean get() = Tags.isOverLimit(selectedCount)
    /** Selection order follows the set, so the pasted string reads the way the set does. */
    val selectedInOrder: List<String>
        get() = set?.tags?.filter { it in selected } ?: emptyList()
}

class SetViewModel(
    private val repository: HashtagRepository,
    private val preferences: UserPreferencesRepository,
    private val setId: String
) : ViewModel() {

    private val _uiState = MutableStateFlow(SetUiState())
    val uiState: StateFlow<SetUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            val resolved = resolve(setId)
            val openSelected = preferences.isOpenFullySelected()
            _uiState.value = SetUiState(
                loading = false,
                set = resolved,
                selected = if (openSelected && resolved != null) resolved.tags.toSet() else emptySet(),
                favourites = repository.favourites.first().toSet()
            )
        }
        viewModelScope.launch {
            repository.favourites.collect { favs ->
                _uiState.value = _uiState.value.copy(favourites = favs.toSet())
                // Favourites is built from the starred tags, so unstarring one while
                // looking at it has to remove it from the set being shown.
                if (setId == HashtagRepository.FAVOURITES_ID) {
                    val rebuilt = HashtagSet(setId, favs, HashtagSet.Kind.FAVOURITES)
                    _uiState.value = _uiState.value.copy(
                        set = rebuilt,
                        selected = _uiState.value.selected intersect favs.toSet()
                    )
                }
            }
        }
    }

    private suspend fun resolve(id: String): HashtagSet? = when {
        id == HashtagRepository.FAVOURITES_ID ->
            HashtagSet(id, repository.favourites.first(), HashtagSet.Kind.FAVOURITES)
        id.startsWith("custom:") ->
            repository.customSet(id.removePrefix("custom:").toLongOrNull() ?: -1L)
        else -> repository.builtInSets().firstOrNull { it.id == id }
    }

    fun toggle(tag: String) {
        val current = _uiState.value.selected
        _uiState.value = _uiState.value.copy(
            selected = if (tag in current) current - tag else current + tag
        )
    }

    fun selectAll() {
        val set = _uiState.value.set ?: return
        _uiState.value = _uiState.value.copy(selected = set.tags.toSet())
    }

    fun clear() {
        _uiState.value = _uiState.value.copy(selected = emptySet())
    }

    fun toggleFavourite(tag: String) = viewModelScope.launch {
        repository.setFavourite(tag, tag !in _uiState.value.favourites)
    }

    /** Called after the clipboard write succeeded, so history reflects reality. */
    fun recordCopy(sourceName: String) = viewModelScope.launch {
        repository.recordCopy(_uiState.value.selectedInOrder, sourceName)
    }

    companion object {
        fun factory(
            repository: HashtagRepository,
            preferences: UserPreferencesRepository,
            setId: String
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                SetViewModel(repository, preferences, setId) as T
        }
    }
}
