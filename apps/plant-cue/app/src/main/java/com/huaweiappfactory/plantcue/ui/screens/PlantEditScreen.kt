package com.huaweiappfactory.plantcue.ui.screens

import android.Manifest
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.content.FileProvider
import com.huaweiappfactory.plantcue.R
import com.huaweiappfactory.plantcue.ui.components.PlantThumbnail
import com.huaweiappfactory.plantcue.util.ImageStorageManager
import java.io.File

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlantEditScreen(
    viewModel: PlantEditViewModel,
    onBack: () -> Unit,
    onSaved: (Long) -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    var cameraFile by remember { mutableStateOf<File?>(null) }
    val takePicture = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        val f = cameraFile
        if (ok && f != null) viewModel.onPhotoCaptured(context, f) else f?.delete()
        cameraFile = null
    }
    val pickPhoto = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri: Uri? ->
        if (uri != null) viewModel.onPhotoPicked(context, uri)
    }
    val requestNotifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { _ ->
        viewModel.notificationPromptHandled()
        state.savedId?.let(onSaved)
    }

    // After the first save: explain reminders once, then request the permission.
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

    if (state.photoError) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissPhotoError() },
            title = { Text(stringResource(R.string.edit_photo_error_title)) },
            text = { Text(stringResource(R.string.edit_photo_error)) },
            confirmButton = { TextButton(onClick = { viewModel.dismissPhotoError() }) { Text(stringResource(R.string.action_ok)) } }
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
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Photo
            Row(verticalAlignment = Alignment.CenterVertically) {
                PlantThumbnail(state.photoPath, state.name.ifBlank { stringResource(R.string.edit_title_new) }, size = 88.dp, corner = 20.dp)
                Spacer(Modifier.width(16.dp))
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    OutlinedButton(onClick = {
                        val f = ImageStorageManager.newCameraTempFile(context)
                        cameraFile = f
                        val uri = FileProvider.getUriForFile(context, context.packageName + ".fileprovider", f)
                        takePicture.launch(uri)
                    }) {
                        Icon(Icons.Default.AddAPhoto, contentDescription = null); Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.edit_photo_take))
                    }
                    OutlinedButton(onClick = { pickPhoto.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) }) {
                        Icon(Icons.Default.PhotoLibrary, contentDescription = null); Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.edit_photo_gallery))
                    }
                    if (state.photoPath != null) {
                        TextButton(onClick = { viewModel.removePhoto() }) {
                            Icon(Icons.Default.Delete, contentDescription = null); Spacer(Modifier.width(6.dp))
                            Text(stringResource(R.string.edit_photo_remove))
                        }
                    }
                }
            }

            OutlinedTextField(
                value = state.name, onValueChange = viewModel::onName,
                label = { Text(stringResource(R.string.edit_name)) },
                isError = state.nameError,
                supportingText = if (state.nameError) { { Text(stringResource(R.string.edit_name_required)) } } else null,
                singleLine = true, modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = state.room, onValueChange = viewModel::onRoom,
                label = { Text(stringResource(R.string.edit_room)) }, singleLine = true, modifier = Modifier.fillMaxWidth()
            )
            if (state.roomSuggestions.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    state.roomSuggestions.take(4).forEach { room ->
                        AssistChip(onClick = { viewModel.onRoom(room) }, label = { Text(room) })
                    }
                }
            }
            OutlinedTextField(
                value = state.notes, onValueChange = viewModel::onNotes,
                label = { Text(stringResource(R.string.edit_notes)) }, minLines = 2, modifier = Modifier.fillMaxWidth()
            )

            Text(stringResource(R.string.edit_schedules), style = MaterialTheme.typography.titleMedium)
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    IntervalRow(stringResource(R.string.care_water), enabled = true, onEnabled = null,
                        days = state.waterEveryDays, onDays = viewModel::onWaterDays)
                    IntervalRow(stringResource(R.string.care_fertilise), enabled = state.fertiliseEnabled, onEnabled = viewModel::onFertiliseEnabled,
                        days = state.fertiliseEveryDays, onDays = viewModel::onFertiliseDays)
                    IntervalRow(stringResource(R.string.care_mist), enabled = state.mistEnabled, onEnabled = viewModel::onMistEnabled,
                        days = state.mistEveryDays, onDays = viewModel::onMistDays)
                }
            }

            Spacer(Modifier.height(8.dp))
            Button(onClick = { viewModel.save() }, enabled = !state.saving, modifier = Modifier.fillMaxWidth()) {
                Text(stringResource(R.string.action_save))
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

@Composable
private fun IntervalRow(label: String, enabled: Boolean, onEnabled: ((Boolean) -> Unit)?, days: Int, onDays: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        if (onEnabled != null) {
            Switch(checked = enabled, onCheckedChange = onEnabled)
            Spacer(Modifier.width(12.dp))
        }
        Column(Modifier.weight(1f)) {
            Text(label, style = MaterialTheme.typography.bodyLarge)
            if (enabled) {
                Text(pluralStringResource(R.plurals.edit_every_days, days, days), style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        if (enabled) {
            // Local text state so the field can be emptied while typing a new number;
            // only valid integers are committed upstream.
            var text by remember(days) { mutableStateOf(days.toString()) }
            OutlinedTextField(
                value = text,
                onValueChange = { v ->
                    val digits = v.filter { it.isDigit() }.take(3)
                    text = digits
                    digits.toIntOrNull()?.let(onDays)
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                singleLine = true,
                modifier = Modifier.width(84.dp),
                suffix = { Text(stringResource(R.string.edit_days_suffix)) }
            )
        }
    }
}
