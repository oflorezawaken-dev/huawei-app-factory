package com.huaweiappfactory.sudoku.ui.screens

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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import com.huaweiappfactory.sudoku.domain.DifficultyStats
import com.huaweiappfactory.sudoku.domain.StatsCalculator
import com.huaweiappfactory.sudoku.ui.difficultyLabel

@Composable
fun StatsScreen(viewModel: StatsViewModel, onBack: () -> Unit) {
    val stats by viewModel.stats.collectAsState()

    Column(modifier = Modifier.fillMaxSize().testTag("stats_screen")) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack, modifier = Modifier.testTag("stats_back")) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
            }
            Text(
                text = stringResource(R.string.stats_title),
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
            val current = stats
            if (current == null || !current.hasData) {
                Spacer(Modifier.height(40.dp))
                Text(
                    text = stringResource(R.string.stats_empty),
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.testTag("stats_empty")
                )
            } else {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                    StreakTile(
                        label = stringResource(R.string.stats_current_streak),
                        value = current.currentStreak.toString(),
                        modifier = Modifier.weight(1f)
                    )
                    StreakTile(
                        label = stringResource(R.string.stats_longest_streak),
                        value = current.longestStreak.toString(),
                        modifier = Modifier.weight(1f)
                    )
                }
                Spacer(Modifier.height(16.dp))
                current.perDifficulty.forEach { row ->
                    DifficultyCard(row)
                    Spacer(Modifier.height(10.dp))
                }
            }
            Spacer(Modifier.height(16.dp))
        }

        PetalBanner(placement = AdPlacement.STATS_BANNER)
    }
}

@Composable
private fun StreakTile(label: String, value: String, modifier: Modifier = Modifier) {
    Card(
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer),
        modifier = modifier
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

@Composable
private fun DifficultyCard(stats: DifficultyStats) {
    val none = stringResource(R.string.stats_no_value)
    Card(modifier = Modifier.fillMaxWidth().testTag("stats_${stats.difficulty.name.lowercase()}")) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = stringResource(difficultyLabel(stats.difficulty)),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(8.dp))
            StatRow(stringResource(R.string.stats_played), stats.played.toString())
            StatRow(stringResource(R.string.stats_won), stats.won.toString())
            StatRow(stringResource(R.string.stats_win_rate), "${stats.winRatePercent}%")
            StatRow(
                stringResource(R.string.stats_best_time),
                stats.bestSeconds?.let { StatsCalculator.formatDuration(it) } ?: none
            )
            StatRow(
                stringResource(R.string.stats_average_time),
                stats.averageSeconds?.let { StatsCalculator.formatDuration(it) } ?: none
            )
        }
    }
}

@Composable
private fun StatRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
    }
}
