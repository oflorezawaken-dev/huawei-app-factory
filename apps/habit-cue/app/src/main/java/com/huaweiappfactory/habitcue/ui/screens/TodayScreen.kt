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
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.habitcue.R
import com.huaweiappfactory.habitcue.ui.components.HabitSwatch
import com.huaweiappfactory.habitcue.ui.components.formatDate
import com.huaweiappfactory.habitcue.ui.components.scheduleSummary
import kotlinx.coroutines.launch
import java.time.LocalDate

@Composable
fun TodayScreen(
    viewModel: TodayViewModel,
    onAddHabit: () -> Unit,
    onOpenHabit: (Long) -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val undoLabel = stringResource(R.string.action_undo)
    val doneMessage = stringResource(R.string.today_marked_done)

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = onAddHabit) {
                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.action_add_habit))
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) { data -> Snackbar(snackbarData = data) } }
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
                state.habitCount == 0 -> EmptyToday(
                    titleRes = R.string.today_no_habits_title,
                    bodyRes = R.string.today_no_habits_body,
                    action = {
                        Button(onClick = onAddHabit) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(Modifier.width(8.dp))
                            Text(stringResource(R.string.action_add_habit))
                        }
                    }
                )
                state.due.isEmpty() -> EmptyToday(titleRes = R.string.today_empty_title, bodyRes = R.string.today_empty_body)
                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 96.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(state.due, key = { it.habit.id }) { item ->
                        DueCard(
                            item = item,
                            onDone = {
                                viewModel.markDone(item.habit.id)
                                scope.launch {
                                    val result = snackbarHostState.showSnackbar(doneMessage, actionLabel = undoLabel)
                                    if (result == SnackbarResult.ActionPerformed) viewModel.undo(item.habit.id)
                                }
                            },
                            onOpen = { onOpenHabit(item.habit.id) }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyToday(titleRes: Int, bodyRes: Int, action: (@Composable () -> Unit)? = null) {
    com.huaweiappfactory.habitcue.ui.components.EmptyState(
        icon = Icons.Default.CheckCircle,
        title = stringResource(titleRes),
        body = stringResource(bodyRes),
        action = action
    )
}

@Composable
private fun DueCard(item: TodayItem, onDone: () -> Unit, onOpen: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                HabitSwatch(item.habit.colour, item.habit.name)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(item.habit.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                    Text(scheduleSummary(item.schedule), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(Modifier.height(12.dp))
            Row {
                FilledTonalButton(onClick = onDone, modifier = Modifier.weight(1f)) {
                    Icon(Icons.Default.Check, contentDescription = null)
                    Spacer(Modifier.width(6.dp))
                    Text(stringResource(R.string.action_done))
                }
                Spacer(Modifier.width(8.dp))
                TextButton(onClick = onOpen) { Text(stringResource(R.string.action_open_habit)) }
            }
        }
    }
}
