package com.huaweiappfactory.sudoku.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.sudoku.R
import com.huaweiappfactory.sudoku.ads.AdPlacement
import com.huaweiappfactory.sudoku.ads.PetalBanner
import com.huaweiappfactory.sudoku.domain.Difficulty
import com.huaweiappfactory.sudoku.domain.StatsCalculator
import com.huaweiappfactory.sudoku.ui.difficultyLabel

@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onContinue: () -> Unit,
    onNewGame: (Difficulty) -> Unit,
    onOpenStats: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val saved by viewModel.savedGame.collectAsState()

    Column(modifier = Modifier.fillMaxSize().testTag("home_screen")) {
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            Spacer(Modifier.height(40.dp))
            Text(
                text = stringResource(R.string.app_name),
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Text(
                text = stringResource(R.string.home_tagline),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(Modifier.height(28.dp))

            saved?.let { game ->
                Card(
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable(onClick = onContinue)
                        .testTag("home_continue_card")
                ) {
                    Row(
                        modifier = Modifier.padding(20.dp).fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Default.PlayArrow,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                        Column(modifier = Modifier.weight(1f).padding(start = 12.dp)) {
                            Text(
                                text = stringResource(R.string.home_continue),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                            Text(
                                text = stringResource(
                                    R.string.home_continue_detail,
                                    stringResource(difficultyLabel(game.difficulty)),
                                    StatsCalculator.formatDuration(game.elapsedSeconds),
                                    (game.progress * 100).toInt()
                                ),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowForward,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
                Spacer(Modifier.height(24.dp))
            }

            Text(
                text = stringResource(R.string.home_new_game),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(12.dp))

            Difficulty.entries.forEach { difficulty ->
                Button(
                    onClick = { onNewGame(difficulty) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 5.dp)
                        .testTag("difficulty_${difficulty.name.lowercase()}")
                ) {
                    Text(stringResource(difficultyLabel(difficulty)))
                }
            }

            Spacer(Modifier.height(20.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onOpenStats,
                    modifier = Modifier.weight(1f).testTag("home_stats_button")
                ) {
                    Icon(Icons.Default.BarChart, contentDescription = null)
                    Text(
                        text = stringResource(R.string.home_statistics),
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
                TextButton(
                    onClick = onOpenSettings,
                    modifier = Modifier.weight(1f).testTag("home_settings_button")
                ) {
                    Icon(Icons.Default.Settings, contentDescription = null)
                    Text(
                        text = stringResource(R.string.home_settings),
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
            }

            Spacer(Modifier.height(16.dp))
        }

        PetalBanner(placement = AdPlacement.HOME_BANNER)
    }
}
