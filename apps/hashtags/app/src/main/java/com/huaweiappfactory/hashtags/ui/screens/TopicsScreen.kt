package com.huaweiappfactory.hashtags.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.hashtags.R
import com.huaweiappfactory.hashtags.ads.AdPlacement
import com.huaweiappfactory.hashtags.ads.PetalBanner
import com.huaweiappfactory.hashtags.domain.HashtagSet
import com.huaweiappfactory.hashtags.ui.setLabelRes
import com.huaweiappfactory.hashtags.ui.setLiteralName

@Composable
fun TopicsScreen(
    viewModel: TopicsViewModel,
    onOpenSet: (String) -> Unit,
    onNewSet: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val state by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize().testTag("topics_screen")) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 4.dp, top = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.topics_title),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.weight(1f)
            )
            IconButton(onClick = onOpenSettings, modifier = Modifier.testTag("open_settings")) {
                Icon(Icons.Default.Settings, contentDescription = stringResource(R.string.topics_settings))
            }
        }

        OutlinedTextField(
            value = state.query,
            onValueChange = viewModel::onQueryChange,
            singleLine = true,
            placeholder = { Text(stringResource(R.string.topics_search_hint)) },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
            trailingIcon = {
                if (state.isSearching) {
                    IconButton(onClick = { viewModel.onQueryChange("") }) {
                        Icon(Icons.Default.Close, contentDescription = stringResource(R.string.cd_clear_search))
                    }
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 8.dp)
                .testTag("search_field")
        )

        LazyColumn(
            modifier = Modifier.weight(1f).fillMaxWidth(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                start = 20.dp, end = 20.dp, bottom = 16.dp
            ),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (state.isEmptyResult) {
                item {
                    Spacer(Modifier.height(32.dp))
                    Text(
                        text = stringResource(R.string.topics_empty_search, state.query),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.testTag("empty_search")
                    )
                }
            }

            if (state.matchingTags.isNotEmpty()) {
                item { SectionHeader(stringResource(R.string.topics_search_hint)) }
                item {
                    Text(
                        text = state.matchingTags.joinToString(" "),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SectionHeader(stringResource(R.string.topics_your_sets), Modifier.weight(1f))
                    TextButton(onClick = onNewSet, modifier = Modifier.testTag("new_set")) {
                        Icon(Icons.Default.Add, contentDescription = null)
                        Text(
                            stringResource(R.string.topics_new_set),
                            modifier = Modifier.padding(start = 4.dp)
                        )
                    }
                }
            }
            items(state.yourSets, key = { it.id }) { set ->
                SetCard(set = set, onClick = { onOpenSet(set.id) })
            }

            item { SectionHeader(stringResource(R.string.topics_browse)) }
            items(state.topics, key = { it.id }) { set ->
                SetCard(set = set, onClick = { onOpenSet(set.id) })
            }
        }

        PetalBanner(placement = AdPlacement.TOPICS_BANNER)
    }
}

@Composable
private fun SectionHeader(text: String, modifier: Modifier = Modifier) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        modifier = modifier.padding(top = 12.dp)
    )
}

@Composable
private fun SetCard(set: HashtagSet, onClick: () -> Unit) {
    val labelRes = setLabelRes(set)
    Card(
        colors = CardDefaults.cardColors(
            containerColor = if (set.kind == HashtagSet.Kind.BUILT_IN) {
                MaterialTheme.colorScheme.surfaceVariant
            } else {
                MaterialTheme.colorScheme.primaryContainer
            }
        ),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .testTag("set_${set.id}")
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = labelRes?.let { stringResource(it) } ?: setLiteralName(set),
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = stringResource(R.string.topics_tag_count, set.size),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}
