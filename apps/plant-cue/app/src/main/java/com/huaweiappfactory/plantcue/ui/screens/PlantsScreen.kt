package com.huaweiappfactory.plantcue.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.LocalFlorist
import androidx.compose.material.icons.filled.SortByAlpha
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Card
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.plantcue.R
import com.huaweiappfactory.plantcue.ads.AdPlacement
import com.huaweiappfactory.plantcue.ads.PetalBanner
import com.huaweiappfactory.plantcue.data.local.PlantWithSchedules
import com.huaweiappfactory.plantcue.domain.CareType
import com.huaweiappfactory.plantcue.ui.components.EmptyState
import com.huaweiappfactory.plantcue.ui.components.PlantThumbnail
import com.huaweiappfactory.plantcue.ui.components.careLabel
import com.huaweiappfactory.plantcue.ui.components.formatDate
import java.time.LocalDate

@Composable
fun PlantsScreen(
    viewModel: PlantsViewModel,
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
            Row(
                modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 8.dp, top = 24.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    stringResource(R.string.plants_title),
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = {
                    viewModel.setSort(if (state.sort == PlantSort.NAME) PlantSort.NEXT_DUE else PlantSort.NAME)
                }) {
                    Icon(
                        if (state.sort == PlantSort.NAME) Icons.Default.Schedule else Icons.Default.SortByAlpha,
                        contentDescription = stringResource(
                            if (state.sort == PlantSort.NAME) R.string.plants_sort_due else R.string.plants_sort_name
                        )
                    )
                }
            }

            if (state.rooms.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    FilterChip(selected = state.roomFilter == null, onClick = { viewModel.setRoomFilter(null) },
                        label = { Text(stringResource(R.string.plants_filter_all)) })
                    state.rooms.forEach { room ->
                        FilterChip(selected = state.roomFilter == room, onClick = { viewModel.setRoomFilter(room) }, label = { Text(room) })
                    }
                }
            }

            if (!state.loading && state.plants.isEmpty()) {
                EmptyState(
                    icon = Icons.Default.LocalFlorist,
                    title = stringResource(R.string.plants_empty_title),
                    body = stringResource(R.string.plants_empty_body),
                    modifier = Modifier.weight(1f)
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxWidth().weight(1f),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 88.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(state.plants, key = { it.plant.id }) { pws -> PlantRow(pws) { onOpenPlant(pws.plant.id) } }
                }
            }
            PetalBanner(placement = AdPlacement.PLANTS_BANNER)
        }
    }
}

@Composable
private fun PlantRow(pws: PlantWithSchedules, onClick: () -> Unit) {
    val today = LocalDate.now()
    val next = pws.schedules.minByOrNull { it.nextDueEpochDay }
    Card(modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            PlantThumbnail(pws.plant.photoPath, pws.plant.name)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(pws.plant.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                if (pws.plant.room.isNotBlank()) {
                    Text(pws.plant.room, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            if (next != null) {
                val due = LocalDate.ofEpochDay(next.nextDueEpochDay)
                val overdue = due.isBefore(today)
                Column(horizontalAlignment = Alignment.End) {
                    Text(careLabel(CareType.valueOf(next.careType)), style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        if (due.isEqual(today)) stringResource(R.string.due_today) else formatDate(due),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = if (overdue) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}
