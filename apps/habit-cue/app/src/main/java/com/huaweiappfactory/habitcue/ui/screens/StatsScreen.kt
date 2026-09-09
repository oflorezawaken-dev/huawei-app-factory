package com.huaweiappfactory.habitcue.ui.screens

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
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.habitcue.R
import com.huaweiappfactory.habitcue.ads.AdPlacement
import com.huaweiappfactory.habitcue.ads.InterstitialTrigger
import com.huaweiappfactory.habitcue.ads.LocalAdManager
import com.huaweiappfactory.habitcue.ads.PetalBanner
import com.huaweiappfactory.habitcue.ads.findActivity
import com.huaweiappfactory.habitcue.ui.LocalInterstitialsSuppressed

@Composable
fun StatsScreen(viewModel: StatsViewModel) {
    val stats by viewModel.stats.collectAsState()

    // Natural pause: the user is looking at numbers, not checking off a habit.
    val adManager = LocalAdManager.current
    val suppressed = LocalInterstitialsSuppressed.current
    val activity = LocalContext.current.findActivity()
    LaunchedEffect(Unit) {
        if (!suppressed && adManager != null && activity != null) {
            adManager.maybeShowInterstitial(activity, InterstitialTrigger.OPEN_STATISTICS)
        }
    }

    Column(Modifier.fillMaxSize()) {
        Column(
            Modifier.fillMaxWidth().weight(1f).verticalScroll(rememberScrollState()).padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(stringResource(R.string.stats_title), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(4.dp))
            val s = stats
            if (s == null) return@Column
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(stringResource(R.string.stats_habits), s.habitCount.toString(), Modifier.weight(1f), highlight = true)
                StatTile(stringResource(R.string.stats_best_streak), s.bestStreak.toString(), Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatTile(stringResource(R.string.stats_completions_month), s.completionsThisMonth.toString(), Modifier.weight(1f))
                StatTile(stringResource(R.string.stats_completion_rate), s.completionRatePercent?.let { "$it%" } ?: stringResource(R.string.stats_no_data), Modifier.weight(1f))
            }
            if (s.habitCount == 0) {
                Spacer(Modifier.height(8.dp))
                Text(stringResource(R.string.stats_empty), color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        PetalBanner(placement = AdPlacement.STATS_BANNER)
    }
}

@Composable
private fun StatTile(label: String, value: String, modifier: Modifier = Modifier, highlight: Boolean = false) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(
            containerColor = if (highlight) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(label, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(6.dp))
            Text(value, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        }
    }
}
