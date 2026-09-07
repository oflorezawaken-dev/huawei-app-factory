package com.huaweiappfactory.plantcue.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.plantcue.R
import com.huaweiappfactory.plantcue.domain.CareAction
import com.huaweiappfactory.plantcue.domain.CareType
import com.huaweiappfactory.plantcue.ui.components.ConfirmDeleteDialog
import com.huaweiappfactory.plantcue.ui.components.PlantThumbnail
import com.huaweiappfactory.plantcue.ui.components.careLabel
import com.huaweiappfactory.plantcue.ui.components.formatDate
import java.time.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlantDetailScreen(
    viewModel: PlantDetailViewModel,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onDeleted: () -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    var confirmDelete by remember { mutableStateOf(false) }

    LaunchedEffect(state.deleted) { if (state.deleted) onDeleted() }

    val plant = state.plant?.plant
    if (confirmDelete && plant != null) {
        ConfirmDeleteDialog(
            title = stringResource(R.string.detail_delete_title, plant.name),
            body = stringResource(R.string.detail_delete_body),
            onConfirm = { confirmDelete = false; viewModel.delete() },
            onDismiss = { confirmDelete = false }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(plant?.name ?: "") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back)) }
                },
                actions = {
                    IconButton(onClick = onEdit) { Icon(Icons.Default.Edit, contentDescription = stringResource(R.string.action_edit)) }
                    IconButton(onClick = { confirmDelete = true }) {
                        Icon(Icons.Default.Delete, contentDescription = stringResource(R.string.action_delete), tint = MaterialTheme.colorScheme.error)
                    }
                }
            )
        }
    ) { padding ->
        val pws = state.plant
        if (pws == null) return@Scaffold
        val today = LocalDate.now()

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    PlantThumbnail(pws.plant.photoPath, pws.plant.name, size = 96.dp, corner = 22.dp)
                    Spacer(Modifier.width(16.dp))
                    Column {
                        Text(pws.plant.name, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                        if (pws.plant.room.isNotBlank()) Text(pws.plant.room, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        if (pws.plant.notes.isNotBlank()) {
                            Spacer(Modifier.height(4.dp))
                            Text(pws.plant.notes, style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }

            item { Text(stringResource(R.string.detail_schedules), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold) }
            items(pws.schedules.sortedBy { it.nextDueEpochDay }, key = { it.id }) { s ->
                val due = LocalDate.ofEpochDay(s.nextDueEpochDay)
                val overdue = due.isBefore(today)
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(14.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(careLabel(CareType.valueOf(s.careType)), style = MaterialTheme.typography.titleMedium)
                                Text(
                                    if (due.isEqual(today)) stringResource(R.string.due_today) else formatDate(due),
                                    color = if (overdue) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
                                    fontWeight = if (overdue) FontWeight.SemiBold else FontWeight.Normal
                                )
                                s.lastDoneEpochDay?.let {
                                    Text(stringResource(R.string.detail_last_done, formatDate(LocalDate.ofEpochDay(it))),
                                        style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
                            Text(stringResource(R.string.edit_every_short, s.intervalDays), style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Spacer(Modifier.height(10.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FilledTonalButton(onClick = { viewModel.markDone(s.id) }, modifier = Modifier.weight(1f)) {
                                Icon(Icons.Default.Check, contentDescription = null); Spacer(Modifier.width(6.dp)); Text(stringResource(R.string.action_done))
                            }
                            if (!due.isAfter(today)) {
                                OutlinedButton(onClick = { viewModel.snooze(s.id) }, modifier = Modifier.weight(1f)) {
                                    Text(stringResource(R.string.action_snooze))
                                }
                            }
                        }
                    }
                }
            }

            item {
                Spacer(Modifier.height(8.dp))
                Text(stringResource(R.string.detail_history), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            if (state.events.isEmpty()) {
                item { Text(stringResource(R.string.detail_history_empty), color = MaterialTheme.colorScheme.onSurfaceVariant) }
            } else {
                items(state.events, key = { it.id }) { e ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            stringResource(if (e.action == CareAction.DONE.name) R.string.history_done else R.string.history_snoozed),
                            style = MaterialTheme.typography.labelLarge,
                            color = if (e.action == CareAction.DONE.name) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.width(88.dp)
                        )
                        Text(careLabel(CareType.valueOf(e.careType)), modifier = Modifier.weight(1f))
                        Text(formatDate(LocalDate.ofEpochDay(e.atEpochDay)), style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            item { Spacer(Modifier.height(24.dp)) }
        }
    }
}
