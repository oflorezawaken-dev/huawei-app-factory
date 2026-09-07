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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.LocalFlorist
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.plantcue.R
import com.huaweiappfactory.plantcue.data.repository.DueItem
import com.huaweiappfactory.plantcue.ui.components.EmptyState
import com.huaweiappfactory.plantcue.ui.components.PlantThumbnail
import com.huaweiappfactory.plantcue.ui.components.careLabel
import com.huaweiappfactory.plantcue.ui.components.formatDate
import java.time.LocalDate

@Composable
fun TodayScreen(
    viewModel: TodayViewModel,
    onAddPlant: () -> Unit,
    onOpenPlant: (Long) -> Unit
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onAddPlant) {
                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.action_add_plant))
            }
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Text(
                text = stringResource(R.string.today_title),
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 24.dp)
            )
            Text(
                text = formatDate(LocalDate.now()),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 20.dp, end = 20.dp, bottom = 8.dp)
            )

            when {
                state.loading -> Unit
                state.plantCount == 0 -> EmptyState(
                    icon = Icons.Default.LocalFlorist,
                    title = stringResource(R.string.today_no_plants_title),
                    body = stringResource(R.string.today_no_plants_body),
                    action = {
                        Button(onClick = onAddPlant) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(Modifier.width(8.dp))
                            Text(stringResource(R.string.action_add_plant))
                        }
                    }
                )
                state.overdue.isEmpty() && state.dueToday.isEmpty() -> EmptyState(
                    icon = Icons.Default.Spa,
                    title = stringResource(R.string.today_empty_title),
                    body = stringResource(R.string.today_empty_body)
                )
                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 96.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    if (state.overdue.isNotEmpty()) {
                        item { SectionLabel(stringResource(R.string.today_overdue), error = true) }
                        items(state.overdue, key = { it.schedule.id }) { item ->
                            DueCard(item, overdue = true, onDone = { viewModel.markDone(item.schedule.id) },
                                onSnooze = { viewModel.snooze(item.schedule.id) }, onOpen = { onOpenPlant(item.plant.id) })
                        }
                    }
                    if (state.dueToday.isNotEmpty()) {
                        item { SectionLabel(stringResource(R.string.today_due)) }
                        items(state.dueToday, key = { it.schedule.id }) { item ->
                            DueCard(item, overdue = false, onDone = { viewModel.markDone(item.schedule.id) },
                                onSnooze = { viewModel.snooze(item.schedule.id) }, onOpen = { onOpenPlant(item.plant.id) })
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String, error: Boolean = false) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        color = if (error) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 8.dp, bottom = 2.dp, start = 4.dp)
    )
}

@Composable
private fun DueCard(item: DueItem, overdue: Boolean, onDone: () -> Unit, onSnooze: () -> Unit, onOpen: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (overdue) MaterialTheme.colorScheme.errorContainer else MaterialTheme.colorScheme.surface
        )
    ) {
        Column(Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                PlantThumbnail(item.plant.photoPath, item.plant.name)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(item.plant.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    val late = item.daysLate.toInt()
                    val subtitle = if (late > 0) {
                        careLabel(item.type) + " · " + pluralStringResource(R.plurals.days_late, late, late)
                    } else {
                        careLabel(item.type) + " · " + stringResource(R.string.due_today)
                    }
                    Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    if (item.plant.room.isNotBlank()) {
                        Text(item.plant.room, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilledTonalButton(onClick = onDone, modifier = Modifier.weight(1f)) {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.action_done))
                }
                OutlinedButton(onClick = onSnooze, modifier = Modifier.weight(1f)) {
                    Text(stringResource(R.string.action_snooze))
                }
            }
            Spacer(Modifier.height(4.dp))
            androidx.compose.material3.TextButton(onClick = onOpen, modifier = Modifier.align(Alignment.End)) {
                Text(stringResource(R.string.action_open_plant))
            }
        }
    }
}
