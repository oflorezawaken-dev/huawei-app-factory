package com.huaweiappfactory.sudoku.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.LifecycleEventObserver
import com.huaweiappfactory.sudoku.R
import com.huaweiappfactory.sudoku.ads.InterstitialTrigger
import com.huaweiappfactory.sudoku.ads.LocalAdManager
import com.huaweiappfactory.sudoku.ads.findActivity
import com.huaweiappfactory.sudoku.domain.Difficulty
import com.huaweiappfactory.sudoku.domain.StatsCalculator
import com.huaweiappfactory.sudoku.domain.SudokuGame
import com.huaweiappfactory.sudoku.ui.components.ActionRow
import com.huaweiappfactory.sudoku.ui.components.NumberPad
import com.huaweiappfactory.sudoku.ui.components.SudokuGrid
import com.huaweiappfactory.sudoku.ui.difficultyLabel

@Composable
fun GameScreen(
    viewModel: GameViewModel,
    onLeave: () -> Unit,
    onPlayAgain: (Difficulty) -> Unit
) {
    val state by viewModel.uiState.collectAsState()
    var confirmLeave by remember { mutableStateOf(false) }

    // The timer stops whenever the game leaves the screen, and the position is saved.
    // A pause the player asked for survives the round trip: onStart never overrides it.
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_STOP -> viewModel.onStop()
                Lifecycle.Event.ON_START -> viewModel.onStart()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            viewModel.onStop()
        }
    }

    BackHandler(enabled = state.finish == null) {
        if (state.loading) onLeave() else confirmLeave = true
    }

    Column(modifier = Modifier.fillMaxSize().testTag("game_screen")) {
        GameTopBar(
            difficulty = state.difficulty,
            elapsedSeconds = state.elapsedSeconds,
            timerVisible = state.timerVisible,
            mistakes = state.mistakes,
            mistakeLimitEnabled = state.mistakeLimitEnabled,
            paused = state.paused,
            enabled = !state.loading && state.finish == null,
            onBack = { if (state.loading) onLeave() else confirmLeave = true },
            onTogglePause = { if (state.paused) viewModel.resume() else viewModel.pause() }
        )

        Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
            when {
                state.loading -> LoadingBoard()
                state.failed -> FailedBoard(onRetry = viewModel::retry)
                else -> Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    SudokuGrid(
                        cells = state.cells,
                        hidden = state.paused,
                        onCellClick = viewModel::select
                    )
                    if (state.paused) {
                        PausedNotice(onResume = viewModel::resume)
                    } else {
                        ActionRow(
                            canUndo = state.canUndo,
                            notesMode = state.notesMode,
                            hintsLeft = state.hintsLeft,
                            enabled = state.finish == null,
                            onUndo = viewModel::undo,
                            onErase = viewModel::erase,
                            onToggleNotes = viewModel::toggleNotesMode,
                            onHint = viewModel::hint
                        )
                        NumberPad(
                            remainingByDigit = state.remainingByDigit,
                            notesMode = state.notesMode,
                            enabled = state.finish == null,
                            onDigit = viewModel::input
                        )
                    }
                    Spacer(Modifier.height(4.dp))
                }
            }
        }
    }

    state.finish?.let { finish ->
        FinishDialog(
            finish = finish,
            difficulty = state.difficulty,
            onPlayAgain = { onPlayAgain(state.difficulty) },
            onHome = onLeave
        )
    }

    if (confirmLeave) {
        AlertDialog(
            onDismissRequest = { confirmLeave = false },
            title = { Text(stringResource(R.string.quit_title)) },
            text = { Text(stringResource(R.string.quit_message)) },
            confirmButton = {
                TextButton(onClick = { confirmLeave = false; onLeave() }) {
                    Text(stringResource(R.string.quit_confirm))
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmLeave = false }) {
                    Text(stringResource(R.string.quit_cancel))
                }
            }
        )
    }
}

@Composable
private fun GameTopBar(
    difficulty: Difficulty,
    elapsedSeconds: Int,
    timerVisible: Boolean,
    mistakes: Int,
    mistakeLimitEnabled: Boolean,
    paused: Boolean,
    enabled: Boolean,
    onBack: () -> Unit,
    onTogglePause: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onBack, modifier = Modifier.testTag("game_back")) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.cd_back))
        }
        Text(
            text = stringResource(difficultyLabel(difficulty)),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = if (mistakeLimitEnabled) {
                stringResource(R.string.board_mistakes, mistakes, SudokuGame.MISTAKE_LIMIT)
            } else {
                stringResource(R.string.board_mistakes_open, mistakes)
            },
            style = MaterialTheme.typography.bodyMedium,
            color = if (mistakes > 0) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.testTag("game_mistakes")
        )
        if (timerVisible) {
            Text(
                text = StatsCalculator.formatDuration(elapsedSeconds),
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(start = 12.dp).testTag("game_timer")
            )
        }
        IconButton(onClick = onTogglePause, enabled = enabled, modifier = Modifier.testTag("game_pause")) {
            Icon(
                if (paused) Icons.Default.PlayArrow else Icons.Default.Pause,
                contentDescription = stringResource(if (paused) R.string.board_resume else R.string.board_pause)
            )
        }
    }
}

@Composable
private fun LoadingBoard() {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        CircularProgressIndicator()
        Spacer(Modifier.height(16.dp))
        Text(stringResource(R.string.home_generating), style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun FailedBoard(onRetry: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.padding(24.dp)
    ) {
        Text(stringResource(R.string.home_generation_failed), style = MaterialTheme.typography.bodyLarge)
        Spacer(Modifier.height(16.dp))
        Button(onClick = onRetry, modifier = Modifier.testTag("generation_retry")) {
            Text(stringResource(R.string.action_retry))
        }
    }
}

@Composable
private fun PausedNotice(onResume: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth().padding(24.dp)
    ) {
        Text(
            stringResource(R.string.board_paused_title),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(8.dp))
        Text(
            stringResource(R.string.board_paused_message),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(16.dp))
        Button(onClick = onResume, modifier = Modifier.testTag("resume_button")) {
            Text(stringResource(R.string.board_resume))
        }
    }
}

/**
 * The end of a puzzle: the one place an interstitial may appear, and only when the
 * frequency policy allows it. The dialog is shown either way.
 */
@Composable
private fun FinishDialog(
    finish: FinishState,
    difficulty: Difficulty,
    onPlayAgain: () -> Unit,
    onHome: () -> Unit
) {
    val adManager = LocalAdManager.current
    val activity = LocalContext.current.findActivity()

    LaunchedEffect(finish) {
        if (adManager != null && activity != null) {
            adManager.maybeShowInterstitial(activity, InterstitialTrigger.PUZZLE_FINISHED)
        }
    }

    AlertDialog(
        onDismissRequest = onHome,
        title = {
            Text(
                stringResource(if (finish.won) R.string.win_title else R.string.lost_title),
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                if (!finish.won) {
                    Text(stringResource(R.string.lost_message, SudokuGame.MISTAKE_LIMIT))
                    Spacer(Modifier.height(8.dp))
                }
                Text(stringResource(R.string.win_time, StatsCalculator.formatDuration(finish.elapsedSeconds)))
                Text(stringResource(R.string.win_mistakes, finish.mistakes))
                Text(stringResource(R.string.win_hints, finish.hintsUsed))
                if (finish.personalBest) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.win_personal_best, stringResource(difficultyLabel(difficulty))),
                        color = MaterialTheme.colorScheme.secondary,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        },
        confirmButton = {
            Button(onClick = onPlayAgain, modifier = Modifier.testTag("finish_play_again")) {
                Text(stringResource(R.string.win_new_game))
            }
        },
        dismissButton = {
            TextButton(onClick = onHome, modifier = Modifier.testTag("finish_home")) {
                Text(stringResource(R.string.win_home))
            }
        },
        modifier = Modifier.testTag("finish_dialog")
    )
}
