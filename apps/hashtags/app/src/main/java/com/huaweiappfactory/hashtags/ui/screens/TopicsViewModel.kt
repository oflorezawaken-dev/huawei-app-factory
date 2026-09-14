package com.huaweiappfactory.hashtags.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.hashtags.data.repository.HashtagRepository
import com.huaweiappfactory.hashtags.domain.CopyRecord
import com.huaweiappfactory.hashtags.domain.HashtagSet
import com.huaweiappfactory.hashtags.domain.SetSearch
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn

data class TopicsUiState(
    val query: String = "",
    val yourSets: List<HashtagSet> = emptyList(),
    val topics: List<HashtagSet> = emptyList(),
    val matchingTags: List<String> = emptyList(),
    val recent: List<CopyRecord> = emptyList()
) {
    val isSearching: Boolean get() = query.isNotBlank()
    val isEmptyResult: Boolean
        get() = isSearching && yourSets.isEmpty() && topics.isEmpty() && matchingTags.isEmpty()
}

class TopicsViewModel(
    private val repository: HashtagRepository,
    private val displayName: (HashtagSet) -> String
) : ViewModel() {

    private val query = MutableStateFlow("")

    val uiState: StateFlow<TopicsUiState> =
        combine(repository.allSets, repository.history, query) { sets, history, q ->
            val custom = sets.filter { it.kind != HashtagSet.Kind.BUILT_IN }
            val builtIn = sets.filter { it.kind == HashtagSet.Kind.BUILT_IN }
            TopicsUiState(
                query = q,
                yourSets = SetSearch.filterSets(custom, q, displayName),
                topics = SetSearch.filterSets(builtIn, q, displayName),
                // Loose tags are only interesting while searching: outside a search
                // they would be a wall of 543 chips with no structure.
                matchingTags = if (q.isBlank()) emptyList() else SetSearch.filterTags(sets, q),
                recent = history
            )
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), TopicsUiState())

    fun onQueryChange(value: String) {
        query.value = value
    }

    companion object {
        fun factory(
            repository: HashtagRepository,
            displayName: (HashtagSet) -> String
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                TopicsViewModel(repository, displayName) as T
        }
    }
}
