package com.huaweiappfactory.hashtags.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.hashtags.R
import com.huaweiappfactory.hashtags.ui.components.RemovableTagChip

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun EditSetScreen(
    viewModel: EditSetViewModel,
    onDone: () -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    var confirmDelete by remember { mutableStateOf(false) }

    // Saving and deleting both mean "this screen is finished".
    LaunchedEffect(state.saved, state.deleted) {
        if (state.saved || state.deleted) onDone()
    }

    Column(modifier = Modifier.fillMaxSize().testTag("edit_screen")) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onDone, modifier = Modifier.testTag("edit_back")) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
            }
            Text(
                text = stringResource(if (state.isNew) R.string.edit_new_title else R.string.edit_title),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f)
            )
            if (!state.isNew) {
                TextButton(onClick = { confirmDelete = true }, modifier = Modifier.testTag("edit_delete")) {
                    Text(
                        stringResource(R.string.edit_delete),
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            OutlinedTextField(
                value = state.name,
                onValueChange = viewModel::onNameChange,
                singleLine = true,
                label = { Text(stringResource(R.string.edit_name_label)) },
                modifier = Modifier.fillMaxWidth().testTag("edit_name")
            )

            Spacer(Modifier.height(16.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = state.draft,
                    onValueChange = viewModel::onDraftChange,
                    singleLine = true,
                    label = { Text(stringResource(R.string.edit_tag_hint)) },
                    isError = state.duplicate != null,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { viewModel.addDraft() }),
                    modifier = Modifier.weight(1f).testTag("edit_tag_input")
                )
                Button(
                    onClick = viewModel::addDraft,
                    enabled = state.draft.isNotBlank(),
                    modifier = Modifier.padding(start = 8.dp).testTag("edit_add")
                ) {
                    Icon(Icons.Default.Add, contentDescription = stringResource(R.string.edit_add))
                }
            }

            if (state.duplicate != null) {
                Text(
                    text = stringResource(R.string.edit_duplicate, state.duplicate!!),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.padding(top = 4.dp).testTag("edit_duplicate")
                )
            }

            Spacer(Modifier.height(16.dp))

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                state.tags.forEach { tag ->
                    RemovableTagChip(
                        tag = tag,
                        onRemove = { viewModel.removeTag(tag) },
                        modifier = Modifier.testTag("edit_chip_$tag")
                    )
                }
            }

            Spacer(Modifier.height(24.dp))
        }

        Row(
            modifier = Modifier.fillMaxWidth().padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = when {
                    state.name.isBlank() -> stringResource(R.string.edit_needs_name)
                    state.tags.isEmpty() -> stringResource(R.string.edit_needs_tags)
                    else -> ""
                },
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f)
            )
            Button(
                onClick = viewModel::save,
                enabled = state.canSave,
                modifier = Modifier.testTag("edit_save")
            ) {
                Text(stringResource(R.string.edit_save))
            }
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text(stringResource(R.string.edit_delete_confirm, state.name)) },
            text = { Text(stringResource(R.string.edit_delete_message)) },
            confirmButton = {
                TextButton(onClick = { confirmDelete = false; viewModel.delete() }) {
                    Text(stringResource(R.string.edit_delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) {
                    Text(stringResource(R.string.edit_cancel))
                }
            }
        )
    }

    Box(Modifier.testTag("edit_loading_${state.loading}"))
}
