package com.huaweiappfactory.habitcue.ui.screens

import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.SortByAlpha
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.Card
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
import com.huaweiappfactory.habitcue.R
import com.huaweiappfactory.habitcue.ads.AdPlacement
import com.huaweiappfactory.habitcue.ads.PetalBanner
import com.huaweiappfactory.habitcue.ui.components.EmptyState
import com.huaweiappfactory.habitcue.ui.components.HabitSwatch
import com.huaweiappfactory.habitcue.ui.components.scheduleSummary

@Composable
fun HabitsScreen(
    viewModel: HabitsViewModel,
    onAddHabit: () -> Unit,
    onOpenHabit: (Long) -> Unit
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onAddHabit) {
                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.action_add_habit))
            }
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            Row(
                modifier = Modifier.fillMaxWidth().padding(start = 20.dp, end = 8.dp, top = 24.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    stringResource(R.string.habits_title),
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = {
                    viewModel.setSort(if (state.sort == HabitSort.STREAK) HabitSort.NAME else HabitSort.STREAK)
                }) {
                    Icon(
                        if (state.sort == HabitSort.STREAK) Icons.Default.SortByAlpha else Icons.Default.LocalFireDepartment,
                        contentDescription = stringResource(
                            if (state.sort == HabitSort.STREAK) R.string.habits_sort_name else R.string.habits_sort_streak
                        )
                    )
                }
            }

            if (!state.loading && state.habits.isEmpty()) {
                EmptyState(
                    icon = Icons.Default.CheckCircle,
                    title = stringResource(R.string.habits_empty_title),
                    body = stringResource(R.string.habits_empty_body),
                    modifier = Modifier.weight(1f)
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxWidth().weight(1f),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 88.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(state.habits, key = { it.habit.id }) { row -> HabitRowItem(row) { onOpenHabit(row.habit.id) } }
                }
            }
            PetalBanner(placement = AdPlacement.HABITS_BANNER)
        }
    }
}

@Composable
private fun HabitRowItem(row: HabitRow, onClick: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            HabitSwatch(row.habit.colour, row.habit.name)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(row.habit.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(scheduleSummary(row.schedule), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (row.currentStreak > 0) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Whatshot, contentDescription = null, tint = MaterialTheme.colorScheme.secondary)
                    Spacer(Modifier.width(4.dp))
                    Text(row.currentStreak.toString(), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
