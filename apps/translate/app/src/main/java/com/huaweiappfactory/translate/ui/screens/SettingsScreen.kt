package com.huaweiappfactory.translate.ui.screens

import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.core.net.toUri
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.translate.R
import com.huaweiappfactory.translate.ads.AdPlacement
import com.huaweiappfactory.translate.ads.PetalBanner
import com.huaweiappfactory.translate.data.repository.ThemeChoice

private const val PRIVACY_URL =
    "https://oflorezawaken-dev.github.io/huawei-app-factory/translate/privacy/"

@Composable
fun SettingsScreen(viewModel: SettingsViewModel, modifier: Modifier = Modifier) {
    val theme by viewModel.theme.collectAsState()
    val historyEnabled by viewModel.historyEnabled.collectAsState()
    val context = LocalContext.current

    Column(modifier = modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(stringResource(R.string.settings_theme), style = MaterialTheme.typography.titleSmall)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ThemeChip(ThemeChoice.SYSTEM, R.string.settings_theme_system, theme, viewModel::setTheme)
                ThemeChip(ThemeChoice.LIGHT, R.string.settings_theme_light, theme, viewModel::setTheme)
                ThemeChip(ThemeChoice.DARK, R.string.settings_theme_dark, theme, viewModel::setTheme)
            }

            HorizontalDivider()

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        stringResource(R.string.settings_history),
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Text(
                        stringResource(R.string.settings_history_body),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
                Switch(checked = historyEnabled, onCheckedChange = viewModel::setHistoryEnabled)
            }
            if (historyEnabled) {
                TextButton(onClick = viewModel::clearHistory) {
                    Text(stringResource(R.string.settings_clear_history))
                }
            }

            HorizontalDivider()

            Text(
                stringResource(R.string.settings_privacy_title),
                style = MaterialTheme.typography.titleSmall
            )
            Text(
                stringResource(R.string.settings_privacy_body),
                style = MaterialTheme.typography.bodySmall
            )
            TextButton(onClick = {
                context.startActivity(Intent(Intent.ACTION_VIEW, PRIVACY_URL.toUri()))
            }) {
                Text(stringResource(R.string.settings_privacy_link))
            }
        }

        PetalBanner(AdPlacement.SETTINGS_BANNER)
    }
}

@Composable
private fun ThemeChip(
    choice: ThemeChoice,
    labelRes: Int,
    selected: ThemeChoice,
    onPick: (ThemeChoice) -> Unit
) {
    FilterChip(
        selected = selected == choice,
        onClick = { onPick(choice) },
        label = { Text(stringResource(labelRes)) }
    )
}
