package com.huaweiappfactory.habitcue.ui.screens

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.habitcue.R
import com.huaweiappfactory.habitcue.domain.ScheduleType
import com.huaweiappfactory.habitcue.ui.components.parseColour
import com.huaweiappfactory.habitcue.ui.theme.HABIT_COLOURS
import java.time.DayOfWeek
import java.time.format.TextStyle
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HabitEditScreen(
    viewModel: HabitEditViewModel,
    onBack: () -> Unit,
    onSaved: (Long) -> Unit
) {
    val state by viewModel.uiState.collectAsState()

    val requestNotifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { _ ->
        viewModel.notificationPromptHandled()
        state.savedId?.let(onSaved)
    }

    var showNotifIntro by remember { mutableStateOf(false) }
    LaunchedEffect(state.savedId, state.askNotificationPermission) {
        val id = state.savedId ?: return@LaunchedEffect
        if (state.askNotificationPermission && Build.VERSION.SDK_INT >= 33) {
            showNotifIntro = true
        } else {
            viewModel.notificationPromptHandled()
            onSaved(id)
        }
    }

    if (showNotifIntro) {
        AlertDialog(
            onDismissRequest = { },
            title = { Text(stringResource(R.string.notif_intro_title)) },
            text = { Text(stringResource(R.string.notif_intro_body)) },
            confirmButton = {
                TextButton(onClick = {
                    showNotifIntro = false
                    if (Build.VERSION.SDK_INT >= 33) requestNotifications.launch(Manifest.permission.POST_NOTIFICATIONS)
                }) { Text(stringResource(R.string.notif_intro_allow)) }
            },
            dismissButton = {
                TextButton(onClick = {
                    showNotifIntro = false
                    viewModel.notificationPromptHandled()
                    state.savedId?.let(onSaved)
                }) { Text(stringResource(R.string.notif_intro_later)) }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(if (state.isNew) R.string.edit_title_new else R.string.edit_title_edit)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
                    }
                }
            )
        }
    ) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = state.name, onValueChange = viewModel::onName,
                label = { Text(stringResource(R.string.edit_name)) },
                isError = state.nameError,
                supportingText = if (state.nameError) { { Text(stringResource(R.string.edit_name_required)) } } else null,
                singleLine = true, modifier = Modifier.fillMaxWidth()
            )

            Text(stringResource(R.string.edit_colour), style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                HABIT_COLOURS.forEach { hex ->
                    val selected = state.colour == hex
                    Column(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(parseColour(hex))
                            .then(if (selected) Modifier.border(2.dp, MaterialTheme.colorScheme.onSurface, CircleShape) else Modifier)
                            .clickable { viewModel.onColour(hex) },
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        if (selected) {
                            Icon(
                                Icons.Default.Check, contentDescription = null,
                                tint = com.huaweiappfactory.habitcue.ui.components.bestOnColour(parseColour(hex)),
                                modifier = Modifier.padding(8.dp)
                            )
                        }
                    }
                }
            }

            Text(stringResource(R.string.edit_schedule), style = MaterialTheme.typography.titleMedium)
            val options = listOf(
                ScheduleType.DAILY to R.string.schedule_option_daily,
                ScheduleType.SPECIFIC_WEEKDAYS to R.string.schedule_option_weekdays,
                ScheduleType.TIMES_PER_WEEK to R.string.schedule_option_times_per_week
            )
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                options.forEachIndexed { i, (type, label) ->
                    SegmentedButton(
                        selected = state.scheduleType == type,
                        onClick = { viewModel.onScheduleType(type) },
                        shape = SegmentedButtonDefaults.itemShape(i, options.size)
                    ) { Text(stringResource(label)) }
                }
            }

            when (state.scheduleType) {
                ScheduleType.SPECIFIC_WEEKDAYS -> {
                    Card(Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp)) {
                            Row(
                                modifier = Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                DayOfWeek.entries.forEach { day ->
                                    FilterChip(
                                        selected = day in state.weekdays,
                                        onClick = { viewModel.toggleWeekday(day) },
                                        label = { Text(day.getDisplayName(TextStyle.NARROW, Locale.getDefault())) }
                                    )
                                }
                            }
                            if (state.weekdaysError) {
                                Spacer(Modifier.height(6.dp))
                                Text(
                                    stringResource(R.string.edit_weekdays_required),
                                    color = MaterialTheme.colorScheme.error,
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }
                }
                ScheduleType.TIMES_PER_WEEK -> {
                    Card(Modifier.fillMaxWidth()) {
                        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(stringResource(R.string.edit_times_per_week), style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
                            var text by remember(state.timesPerWeek) { mutableStateOf(state.timesPerWeek.toString()) }
                            OutlinedTextField(
                                value = text,
                                onValueChange = { v ->
                                    val digits = v.filter { it.isDigit() }.take(1)
                                    text = digits
                                    digits.toIntOrNull()?.let(viewModel::onTimesPerWeek)
                                },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                                modifier = Modifier.size(width = 64.dp, height = 56.dp)
                            )
                        }
                    }
                }
                ScheduleType.DAILY -> Unit
            }

            Spacer(Modifier.height(8.dp))
            Button(onClick = { viewModel.save() }, enabled = !state.saving, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.action_save))
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}
