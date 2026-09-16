package com.huaweiappfactory.translate.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp

/**
 * One screen, because the spike has one question to answer: does Huawei ML Kit
 * translate on a real device? Everything the product needs beyond this --
 * history, a pack manager, detection, sharing -- waits until the answer is yes.
 */
@Composable
fun TranslateScreen(viewModel: TranslateViewModel) {
    val state by viewModel.state.collectAsState()

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                LanguagePicker(
                    label = "From",
                    code = state.source,
                    options = state.supported,
                    onPick = viewModel::onSourceChange,
                    modifier = Modifier.weight(1f)
                )
                LanguagePicker(
                    label = "To",
                    code = state.target,
                    options = state.supported,
                    onPick = viewModel::onTargetChange,
                    modifier = Modifier.weight(1f)
                )
            }

            Text(
                text = if (state.supported.isEmpty()) {
                    "No language list yet - ML Kit has not answered."
                } else {
                    state.supported.size.toString() + " languages on device"
                },
                style = MaterialTheme.typography.bodySmall
            )

            OutlinedTextField(
                value = state.input,
                onValueChange = viewModel::onInputChange,
                label = { Text("Text") },
                minLines = 3,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("input")
            )

            if (!state.modelReady) {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            "This pair is not on the phone yet. Each language is a download " +
                                "of about 25-30 MB; afterwards it works with no network.",
                            style = MaterialTheme.typography.bodySmall
                        )
                        if (state.downloading) {
                            val total = state.totalBytes
                            if (total > 0) {
                                LinearProgressIndicator(
                                    progress = { state.downloadedBytes.toFloat() / total },
                                    modifier = Modifier.fillMaxWidth()
                                )
                                Text(
                                    (state.downloadedBytes / 1_000_000).toString() + " of " +
                                        (total / 1_000_000).toString() + " MB",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            } else {
                                LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                            }
                        } else {
                            OutlinedButton(
                                onClick = viewModel::download,
                                modifier = Modifier.testTag("download")
                            ) { Text("Download this pair") }
                        }
                    }
                }
            }

            Button(
                onClick = viewModel::translate,
                enabled = state.modelReady && state.input.isNotBlank() && !state.busy,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("translate")
            ) { Text(if (state.busy) "Translating..." else "Translate") }

            if (state.output.isNotEmpty()) {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        text = state.output,
                        modifier = Modifier
                            .padding(12.dp)
                            .testTag("output"),
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }

            state.error?.let { message ->
                Text(
                    text = message,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.testTag("error")
                )
            }
        }
    }
}

@Composable
private fun LanguagePicker(
    label: String,
    code: String,
    options: Set<String>,
    onPick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    Column(modifier = modifier) {
        Text(label, style = MaterialTheme.typography.labelSmall)
        OutlinedButton(onClick = { expanded = true }, modifier = Modifier.fillMaxWidth()) {
            Text(code)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            options.sorted().forEach { option ->
                DropdownMenuItem(
                    text = { Text(option) },
                    onClick = {
                        expanded = false
                        onPick(option)
                    }
                )
            }
        }
    }
}
