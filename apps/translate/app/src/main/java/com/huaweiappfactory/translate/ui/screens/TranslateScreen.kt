package com.huaweiappfactory.translate.ui.screens

import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.translate.R
import com.huaweiappfactory.translate.domain.Languages
import com.huaweiappfactory.translate.domain.ModelSize
import com.huaweiappfactory.translate.ui.components.LanguagePicker

/**
 * The whole app in one screen. No ad here, by rule: this is where the work
 * happens and where an interruption would cost the user the thing they came for.
 */
@Composable
fun TranslateScreen(viewModel: TranslateViewModel, modifier: Modifier = Modifier) {
    val state by viewModel.state.collectAsState()
    val clipboard = LocalClipboardManager.current
    val context = LocalContext.current

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            LanguagePicker(
                label = stringResource(R.string.translate_from),
                selectedCode = state.effectiveSource,
                languages = state.languages,
                downloaded = state.downloaded,
                onPick = viewModel::onSourceChange,
                modifier = Modifier.weight(1f)
            )
            IconButton(
                onClick = viewModel::swap,
                modifier = Modifier.testTag("swap")
            ) {
                Icon(
                    Icons.Default.SwapHoriz,
                    contentDescription = stringResource(R.string.translate_swap)
                )
            }
            LanguagePicker(
                label = stringResource(R.string.translate_to),
                selectedCode = state.target,
                languages = state.languages,
                downloaded = state.downloaded,
                onPick = viewModel::onTargetChange,
                modifier = Modifier.weight(1f)
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            FilterChip(
                selected = state.autoDetect,
                onClick = { viewModel.onAutoDetectChange(!state.autoDetect) },
                label = { Text(stringResource(R.string.translate_detect)) },
                modifier = Modifier.testTag("detect")
            )
            if (state.autoDetect && state.detected != null) {
                Text(
                    text = stringResource(
                        R.string.translate_detected,
                        Languages.displayName(state.detected!!)
                    ),
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        }

        OutlinedTextField(
            value = state.input,
            onValueChange = viewModel::onInputChange,
            label = { Text(stringResource(R.string.translate_input_hint)) },
            minLines = 3,
            modifier = Modifier
                .fillMaxWidth()
                .testTag("input")
        )

        if (!Languages.isTranslatable(state.effectiveSource, state.target)) {
            Text(
                text = stringResource(R.string.translate_same_language),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error
            )
        } else if (!state.pairReady) {
            PackNeededCard(
                sizeLabel = ModelSize.formatBytes(state.pendingBytes),
                downloading = state.downloading,
                downloadedBytes = state.downloadedBytes,
                totalBytes = state.totalBytes,
                onDownload = viewModel::download
            )
        }

        Button(
            onClick = { viewModel.translate() },
            enabled = state.canTranslate,
            modifier = Modifier
                .fillMaxWidth()
                .testTag("translate")
        ) {
            Text(
                if (state.translating) stringResource(R.string.translate_working)
                else stringResource(R.string.translate_action)
            )
        }

        if (state.output.isNotEmpty()) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(
                        text = state.output,
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.testTag("output")
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        TextButton(onClick = {
                            clipboard.setText(AnnotatedString(state.output))
                        }) {
                            Icon(Icons.Default.ContentCopy, contentDescription = null)
                            Text(
                                stringResource(R.string.translate_copy),
                                modifier = Modifier.padding(start = 4.dp)
                            )
                        }
                        TextButton(onClick = {
                            val send = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, state.output)
                            }
                            context.startActivity(Intent.createChooser(send, null))
                        }) {
                            Icon(Icons.Default.Share, contentDescription = null)
                            Text(
                                stringResource(R.string.translate_share),
                                modifier = Modifier.padding(start = 4.dp)
                            )
                        }
                    }
                }
            }
        }

        state.error?.let { error ->
            Text(
                text = stringResource(
                    when (error) {
                        TranslateError.DOWNLOAD_FAILED -> R.string.error_download
                        TranslateError.TRANSLATION_FAILED -> R.string.error_translation
                        TranslateError.ENGINE_UNAVAILABLE -> R.string.error_engine
                    }
                ),
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier.testTag("error")
            )
        }
    }
}

/**
 * The cost of the offline promise, stated before it is needed rather than as an
 * error afterwards. This card is most of the product design.
 */
@Composable
private fun PackNeededCard(
    sizeLabel: String,
    downloading: Boolean,
    downloadedBytes: Long,
    totalBytes: Long,
    onDownload: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = stringResource(R.string.pack_needed_title),
                style = MaterialTheme.typography.titleSmall
            )
            Text(
                text = stringResource(R.string.pack_needed_body, sizeLabel),
                style = MaterialTheme.typography.bodySmall
            )
            if (downloading) {
                if (totalBytes > 0) {
                    LinearProgressIndicator(
                        progress = { downloadedBytes.toFloat() / totalBytes },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Text(
                        text = stringResource(
                            R.string.pack_downloading,
                            ModelSize.formatBytes(downloadedBytes),
                            ModelSize.formatBytes(totalBytes)
                        ),
                        style = MaterialTheme.typography.bodySmall
                    )
                } else {
                    LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                    Text(
                        text = stringResource(R.string.pack_preparing),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            } else {
                OutlinedButton(onClick = onDownload, modifier = Modifier.testTag("download")) {
                    Text(stringResource(R.string.pack_download))
                }
            }
        }
    }
}
