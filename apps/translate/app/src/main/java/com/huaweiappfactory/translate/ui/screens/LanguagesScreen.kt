package com.huaweiappfactory.translate.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.translate.R
import com.huaweiappfactory.translate.ads.AdPlacement
import com.huaweiappfactory.translate.ads.PetalBanner
import com.huaweiappfactory.translate.data.repository.UserPreferencesRepository

@Composable
fun LanguagesScreen(viewModel: LanguagesViewModel, modifier: Modifier = Modifier) {
    val state by viewModel.state.collectAsState()
    var pendingDelete by remember { mutableStateOf<DownloadedPair?>(null) }

    Column(modifier = modifier.fillMaxSize()) {
        when {
            state.loading -> Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalArrangement = Arrangement.Center
            ) { CircularProgressIndicator() }

            state.failed -> Text(
                text = stringResource(R.string.languages_unavailable),
                color = MaterialTheme.colorScheme.error,
                modifier = Modifier.padding(16.dp)
            )

            else -> LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                item { SectionHeader(stringResource(R.string.languages_downloaded)) }
                if (state.pairs.isEmpty()) {
                    item {
                        Text(
                            text = stringResource(R.string.languages_empty),
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
                items(state.pairs, key = { "have-${it.source}-${it.target}" }) { pair ->
                    PairRow(
                        pair = pair,
                        busy = state.busyPair == UserPreferencesRepository.key(pair.source, pair.target),
                        onDelete = { pendingDelete = pair }
                    )
                }

                item { SectionHeader(stringResource(R.string.languages_available)) }
                item {
                    Text(
                        text = stringResource(R.string.languages_available_body),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                items(state.available, key = { "get-${it.code}" }) { language ->
                    Text(
                        text = language.displayName,
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
            }
        }

        PetalBanner(AdPlacement.LANGUAGES_BANNER)
    }

    pendingDelete?.let { pair ->
        AlertDialog(
            onDismissRequest = { pendingDelete = null },
            title = { Text(stringResource(R.string.languages_delete_title, pair.label)) },
            text = { Text(stringResource(R.string.languages_delete_body, pair.label)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.delete(pair)
                    pendingDelete = null
                }) { Text(stringResource(R.string.languages_delete)) }
            },
            dismissButton = {
                TextButton(onClick = { pendingDelete = null }) {
                    Text(stringResource(R.string.action_cancel))
                }
            }
        )
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleSmall,
        modifier = Modifier.padding(top = 12.dp, bottom = 4.dp)
    )
}

@Composable
private fun PairRow(pair: DownloadedPair, busy: Boolean, onDelete: () -> Unit) {
    val description = stringResource(R.string.cd_delete_language, pair.label)
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = pair.label,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f)
        )
        if (busy) {
            CircularProgressIndicator(modifier = Modifier.padding(8.dp))
        } else {
            OutlinedButton(
                onClick = onDelete,
                modifier = Modifier.semantics { contentDescription = description }
            ) { Text(stringResource(R.string.languages_delete)) }
        }
    }
}
