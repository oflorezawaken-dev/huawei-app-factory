package com.huaweiappfactory.habitcue.ui.screens

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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
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
import com.huaweiappfactory.habitcue.R
import com.huaweiappfactory.habitcue.ui.components.ConfirmDeleteDialog
import com.huaweiappfactory.habitcue.ui.components.HabitSwatch
import com.huaweiappfactory.habitcue.ui.components.MonthCalendarGrid
import com.huaweiappfactory.habitcue.ui.components.formatDate
import com.huaweiappfactory.habitcue.ui.components.scheduleSummary
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HabitDetailScreen(
    viewModel: HabitDetailViewModel,
    onBack: () -> Unit,
    onEdit: () -> Unit,
    onDeleted: () -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    var confirmDelete by remember { mutableStateOf(false) }

    LaunchedEffect(state.deleted) { if (state.deleted) onDeleted() }

    val habit = state.habit
    if (confirmDelete && habit != null) {
        ConfirmDeleteDialog(
            title = stringResource(R.string.detail_delete_title, habit.name),
            body = stringResource(R.string.detail_delete_body),
            onConfirm = { confirmDelete = false; viewModel.delete() },
            onDismiss = { confirmDelete = false }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(habit?.name ?: "") },
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
        if (habit == null) return@Scaffold
        val today = LocalDate.now()
        val doneToday = today in state.completedDates

        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    HabitSwatch(habit.colour, habit.name, size = 56.dp)
                    Spacer(Modifier.width(14.dp))
                    Column {
                        Text(habit.name, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                        Text(scheduleSummary(state.schedule), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }

            item {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StreakTile(stringResource(R.string.detail_current_streak), state.currentStreak, Modifier.weight(1f), highlight = true)
                    StreakTile(stringResource(R.string.detail_longest_streak), state.longestStreak, Modifier.weight(1f))
                }
            }

            item {
                FilledTonalButton(
                    onClick = { if (doneToday) viewModel.undoToday() else viewModel.markDoneToday() },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(stringResource(if (doneToday) R.string.detail_undo_today else R.string.action_done))
                }
            }

            item {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            IconButton(onClick = viewModel::previousMonth) {
                                Icon(Icons.Default.ChevronLeft, contentDescription = stringResource(R.string.detail_previous_month))
                            }
                            Text(
                                state.displayedMonth.month.getDisplayName(TextStyle.FULL, Locale.getDefault()) + " " + state.displayedMonth.year,
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.weight(1f),
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center
                            )
                            IconButton(onClick = viewModel::nextMonth) {
                                Icon(Icons.Default.ChevronRight, contentDescription = stringResource(R.string.detail_next_month))
                            }
                        }
                        MonthCalendarGrid(month = state.displayedMonth, completedDates = state.completedDates)
                    }
                }
            }

            item {
                Text(stringResource(R.string.detail_history), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            }
            val history = state.completedDates.sortedDescending()
            if (history.isEmpty()) {
                item { Text(stringResource(R.string.detail_history_empty), color = MaterialTheme.colorScheme.onSurfaceVariant) }
            } else {
                items(history.size) { index ->
                    val date = history[index]
                    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Whatshot, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.width(20.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(formatDate(date))
                    }
                }
            }
            item { Spacer(Modifier.height(24.dp)) }
        }
    }
}

@Composable
private fun StreakTile(label: String, value: Int, modifier: Modifier = Modifier, highlight: Boolean = false) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = if (highlight) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(label, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(6.dp))
            Text(value.toString(), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        }
    }
}
