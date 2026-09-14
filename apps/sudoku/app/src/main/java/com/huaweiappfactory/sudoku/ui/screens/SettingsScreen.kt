package com.huaweiappfactory.sudoku.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
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
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.sudoku.BuildConfig
import com.huaweiappfactory.sudoku.R
import com.huaweiappfactory.sudoku.domain.SudokuGame

@Composable
fun SettingsScreen(viewModel: SettingsViewModel, onBack: () -> Unit) {
    val themeMode by viewModel.themeMode.collectAsState()
    val highlights by viewModel.highlightsEnabled.collectAsState()
    val mistakeLimit by viewModel.mistakeLimitEnabled.collectAsState()
    val timerVisible by viewModel.timerVisible.collectAsState()

    var infoDialog by remember { mutableStateOf<InfoDialog?>(null) }

    Column(modifier = Modifier.fillMaxSize().testTag("settings_screen")) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, modifier = Modifier.testTag("settings_back")) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
            }
            Text(
                text = stringResource(R.string.settings_title),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = stringResource(R.string.settings_theme),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth()) {
                ThemeChip("SYSTEM", R.string.theme_system, themeMode, viewModel::setThemeMode)
                ThemeChip("LIGHT", R.string.theme_light, themeMode, viewModel::setThemeMode)
                ThemeChip("DARK", R.string.theme_dark, themeMode, viewModel::setThemeMode)
            }

            Spacer(Modifier.height(16.dp))
            HorizontalDivider()

            SwitchRow(
                title = stringResource(R.string.settings_highlights),
                description = stringResource(R.string.settings_highlights_desc),
                checked = highlights,
                onCheckedChange = viewModel::setHighlights,
                testTag = "setting_highlights"
            )
            SwitchRow(
                title = stringResource(R.string.settings_mistake_limit),
                description = stringResource(R.string.settings_mistake_limit_desc, SudokuGame.MISTAKE_LIMIT),
                checked = mistakeLimit,
                onCheckedChange = viewModel::setMistakeLimit,
                testTag = "setting_mistake_limit"
            )
            SwitchRow(
                title = stringResource(R.string.settings_timer),
                description = stringResource(R.string.settings_timer_desc),
                checked = timerVisible,
                onCheckedChange = viewModel::setTimerVisible,
                testTag = "setting_timer"
            )

            HorizontalDivider()

            InfoRow(
                title = stringResource(R.string.settings_privacy),
                description = stringResource(R.string.settings_privacy_desc),
                onClick = { infoDialog = InfoDialog(R.string.settings_privacy, R.string.privacy_body) },
                testTag = "setting_privacy"
            )
            InfoRow(
                title = stringResource(R.string.settings_ads),
                description = stringResource(R.string.settings_ads_desc),
                onClick = { infoDialog = InfoDialog(R.string.settings_ads, R.string.ads_body) },
                testTag = "setting_ads"
            )

            HorizontalDivider()
            Spacer(Modifier.height(12.dp))
            Text(
                text = stringResource(R.string.settings_about),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = stringResource(R.string.settings_version, BuildConfig.VERSION_NAME),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(24.dp))
        }
    }

    infoDialog?.let { dialog ->
        AlertDialog(
            onDismissRequest = { infoDialog = null },
            title = { Text(stringResource(dialog.titleRes)) },
            text = { Text(stringResource(dialog.bodyRes)) },
            confirmButton = {
                TextButton(onClick = { infoDialog = null }) { Text(stringResource(R.string.action_close)) }
            }
        )
    }
}

private data class InfoDialog(val titleRes: Int, val bodyRes: Int)

@Composable
private fun ThemeChip(mode: String, labelRes: Int, current: String, onSelect: (String) -> Unit) {
    FilterChip(
        selected = current == mode,
        onClick = { onSelect(mode) },
        label = { Text(stringResource(labelRes)) },
        // The Material default paints a selected chip in the secondary colour, which
        // here is the amber reserved for "look at this"; the theme picker is not that.
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
        ),
        modifier = Modifier
            .padding(end = 8.dp)
            .testTag("theme_${mode.lowercase()}")
    )
}

@Composable
private fun SwitchRow(
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    testTag: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onCheckedChange(!checked) }
            .padding(vertical = 12.dp)
            .testTag(testTag),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
            Text(title, style = MaterialTheme.typography.bodyLarge)
            Text(
                description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@Composable
private fun InfoRow(title: String, description: String, onClick: () -> Unit, testTag: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp)
            .testTag(testTag)
    ) {
        Text(title, style = MaterialTheme.typography.bodyLarge)
        Text(
            description,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
