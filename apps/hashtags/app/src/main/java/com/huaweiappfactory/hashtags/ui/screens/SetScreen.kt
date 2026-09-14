package com.huaweiappfactory.hashtags.ui.screens

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.hashtags.R
import com.huaweiappfactory.hashtags.ads.InterstitialTrigger
import com.huaweiappfactory.hashtags.ads.LocalAdManager
import com.huaweiappfactory.hashtags.ads.findActivity
import com.huaweiappfactory.hashtags.domain.HashtagSet
import com.huaweiappfactory.hashtags.domain.Tags
import com.huaweiappfactory.hashtags.ui.components.TagChip
import com.huaweiappfactory.hashtags.ui.setLabelRes
import com.huaweiappfactory.hashtags.ui.setLiteralName

@OptIn(ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
fun SetScreen(
    viewModel: SetViewModel,
    onBack: () -> Unit,
    onEdit: (Long) -> Unit,
    onMessage: (String) -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val adManager = LocalAdManager.current
    val clipboard = remember(context) {
        context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
    }

    val set = state.set
    val title = set?.let { s -> setLabelRes(s)?.let { stringResource(it) } ?: setLiteralName(s) }.orEmpty()
    val copiedMessage = stringResource(R.string.set_copied, state.selectedCount)
    val failedMessage = stringResource(R.string.set_copy_failed)

    Column(modifier = Modifier.fillMaxSize().testTag("set_screen")) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, modifier = Modifier.testTag("set_back")) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
            }
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f)
            )
            if (set != null && set.isEditable) {
                IconButton(onClick = { onEdit(set.rowId) }, modifier = Modifier.testTag("set_edit")) {
                    Icon(Icons.Default.Edit, contentDescription = stringResource(R.string.set_edit))
                }
            }
        }

        Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
            when {
                state.loading -> Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
                set == null || set.tags.isEmpty() -> Text(
                    text = stringResource(emptyMessageFor(set)),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(24.dp).testTag("set_empty")
                )
                else -> FlowRow(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    set.tags.forEach { tag ->
                        TagChip(
                            tag = tag,
                            selected = tag in state.selected,
                            favourite = tag in state.favourites,
                            onClick = { viewModel.toggle(tag) },
                            onLongClick = { viewModel.toggleFavourite(tag) },
                            modifier = Modifier.testTag("chip_$tag")
                        )
                    }
                }
            }
        }

        if (set != null && set.tags.isNotEmpty()) {
            Surface(tonalElevation = 3.dp, modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)) {
                    Text(
                        text = if (state.isOverLimit) {
                            stringResource(R.string.set_over_limit, state.selectedCount)
                        } else {
                            stringResource(R.string.set_selected_count, state.selectedCount, set.size)
                        },
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = if (state.isOverLimit) MaterialTheme.colorScheme.error
                        else MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.testTag("selected_count")
                    )
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        TextButton(onClick = viewModel::selectAll, modifier = Modifier.testTag("select_all")) {
                            Text(stringResource(R.string.set_select_all))
                        }
                        TextButton(onClick = viewModel::clear, modifier = Modifier.testTag("clear_selection")) {
                            Text(stringResource(R.string.set_clear))
                        }
                        Box(Modifier.weight(1f))
                        Button(
                            enabled = state.selectedCount > 0,
                            onClick = {
                                val text = Tags.toClipboard(state.selectedInOrder)
                                val copied = runCatching {
                                    clipboard?.setPrimaryClip(ClipData.newPlainText("hashtags", text))
                                    clipboard != null
                                }.getOrDefault(false)
                                if (copied) {
                                    viewModel.recordCopy(title)
                                    onMessage(copiedMessage)
                                    // The end of the task, and the only place an ad is
                                    // considered. Never while tags are being chosen.
                                    val activity = context.findActivity()
                                    if (adManager != null && activity != null) {
                                        adManager.maybeShowInterstitial(activity, InterstitialTrigger.TAGS_COPIED)
                                    }
                                } else {
                                    onMessage(failedMessage)
                                }
                            },
                            modifier = Modifier.testTag("copy_button")
                        ) {
                            Text(stringResource(R.string.set_copy))
                        }
                    }
                }
            }
        }
    }
}

private fun emptyMessageFor(set: HashtagSet?): Int = when (set?.kind) {
    HashtagSet.Kind.FAVOURITES -> R.string.set_favourites_empty
    HashtagSet.Kind.RECENT -> R.string.set_recent_empty
    else -> R.string.set_empty
}
