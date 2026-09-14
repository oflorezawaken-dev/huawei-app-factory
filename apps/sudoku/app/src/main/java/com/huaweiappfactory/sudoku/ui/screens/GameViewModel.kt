package com.huaweiappfactory.sudoku.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.huaweiappfactory.sudoku.data.repository.GameRepository
import com.huaweiappfactory.sudoku.data.repository.UserPreferencesRepository
import com.huaweiappfactory.sudoku.domain.Difficulty
import com.huaweiappfactory.sudoku.domain.MoveResult
import com.huaweiappfactory.sudoku.domain.StatsCalculator
import com.huaweiappfactory.sudoku.domain.SudokuBoard
import com.huaweiappfactory.sudoku.domain.SudokuGame
import com.huaweiappfactory.sudoku.domain.SudokuGenerator
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** One cell, already resolved for drawing. The board composable does no thinking. */
data class CellUi(
    val value: Int,
    val notes: Int,
    val given: Boolean,
    val conflict: Boolean,
    val selected: Boolean,
    val related: Boolean,
    val sameValue: Boolean
)

/** How the puzzle ended. Present only once the game is over. */
data class FinishState(
    val won: Boolean,
    val elapsedSeconds: Int,
    val mistakes: Int,
    val hintsUsed: Int,
    val personalBest: Boolean
)

data class GameUiState(
    val loading: Boolean = true,
    val failed: Boolean = false,
    val difficulty: Difficulty = Difficulty.MEDIUM,
    val cells: List<CellUi> = emptyList(),
    val selected: Int? = null,
    val notesMode: Boolean = false,
    val mistakes: Int = 0,
    val mistakeLimitEnabled: Boolean = false,
    val hintsLeft: Int = SudokuGame.HINTS_PER_PUZZLE,
    val canUndo: Boolean = false,
    val elapsedSeconds: Int = 0,
    val timerVisible: Boolean = true,
    val highlightsEnabled: Boolean = true,
    val paused: Boolean = false,
    val remainingByDigit: List<Int> = List(9) { SudokuBoard.SIZE },
    val finish: FinishState? = null
)

class GameViewModel(
    private val repository: GameRepository,
    private val preferences: UserPreferencesRepository,
    private val requestedDifficulty: Difficulty?
) : ViewModel() {

    private val _uiState = MutableStateFlow(GameUiState())
    val uiState: StateFlow<GameUiState> = _uiState.asStateFlow()

    private var game: SudokuGame? = null
    private var ticker: Job? = null
    private var pausedByPlayer = false

    init {
        load()
    }

    /**
     * Starts the requested difficulty, or restores the saved game when the screen was
     * opened from Continue. A saved game that cannot be read is discarded rather than
     * crashing the app.
     */
    private fun load() = viewModelScope.launch {
        _uiState.value = GameUiState(
            loading = true,
            timerVisible = preferences.isTimerVisible(),
            highlightsEnabled = preferences.isHighlightsEnabled(),
            mistakeLimitEnabled = preferences.isMistakeLimitEnabled()
        )
        val restored = if (requestedDifficulty == null) runCatching { repository.loadSavedGame() }.getOrNull() else null
        val loaded = restored ?: generate(requestedDifficulty ?: Difficulty.MEDIUM)
        if (loaded == null) {
            _uiState.value = _uiState.value.copy(loading = false, failed = true)
            return@launch
        }
        game = loaded
        if (restored == null) repository.saveGame(loaded)
        publish()
        startTicker()
    }

    /** Generation is CPU-bound; it never runs on the main thread. One retry, then give up. */
    private suspend fun generate(difficulty: Difficulty): SudokuGame? = withContext(Dispatchers.Default) {
        repeat(2) {
            val attempt = runCatching { SudokuGame.from(SudokuGenerator.generate(difficulty)) }.getOrNull()
            if (attempt != null) return@withContext attempt
        }
        null
    }

    fun retry() = load()

    fun select(index: Int) {
        val state = _uiState.value
        if (state.paused || state.finish != null) return
        _uiState.value = state.copy(selected = if (state.selected == index) null else index)
        publish()
    }

    fun toggleNotesMode() {
        _uiState.value = _uiState.value.copy(notesMode = !_uiState.value.notesMode)
    }

    fun input(digit: Int) {
        val current = game ?: return
        val state = _uiState.value
        val index = state.selected ?: return
        if (state.paused || state.finish != null) return
        val result = if (state.notesMode) current.toggleNote(index, digit) else current.setValue(index, digit)
        if (result == MoveResult.REJECTED || result == MoveResult.NO_CHANGE) {
            publish()
            return
        }
        afterMove(result)
    }

    fun erase() {
        val current = game ?: return
        val index = _uiState.value.selected ?: return
        if (_uiState.value.paused || _uiState.value.finish != null) return
        current.erase(index)
        persist()
        publish()
    }

    fun hint() {
        val current = game ?: return
        val state = _uiState.value
        if (state.paused || state.finish != null) return
        afterMove(current.hint(state.selected))
    }

    fun undo() {
        val current = game ?: return
        if (_uiState.value.paused || _uiState.value.finish != null) return
        if (current.undo()) {
            persist()
            publish()
        }
    }

    fun pause() {
        if (_uiState.value.finish != null) return
        pausedByPlayer = true
        stopTicker()
        _uiState.value = _uiState.value.copy(paused = true)
        persist()
    }

    fun resume() {
        if (_uiState.value.finish != null || _uiState.value.loading) return
        pausedByPlayer = false
        _uiState.value = _uiState.value.copy(paused = false)
        startTicker()
    }

    /** The board left the screen: stop counting and save where the player is. */
    fun onStop() {
        stopTicker()
        persist()
    }

    /** The board is back. A pause the player asked for is never lifted for them. */
    fun onStart() {
        if (pausedByPlayer || _uiState.value.finish != null || _uiState.value.loading) return
        startTicker()
    }

    private fun afterMove(result: MoveResult) {
        val current = game ?: return
        when {
            result == MoveResult.SOLVED -> finish(won = true)
            _uiState.value.mistakeLimitEnabled && current.isOutOfMistakes() -> finish(won = false)
            else -> {
                persist()
                publish()
            }
        }
    }

    private fun finish(won: Boolean) = viewModelScope.launch {
        val current = game ?: return@launch
        stopTicker()
        val previous = runCatching { repository.allOutcomes() }.getOrDefault(emptyList())
        val best = won && StatsCalculator.isPersonalBest(previous, current.difficulty, current.elapsedSeconds)
        runCatching {
            repository.recordResult(current, won)
            repository.clearSavedGame()
        }
        publish()
        _uiState.value = _uiState.value.copy(
            finish = FinishState(
                won = won,
                elapsedSeconds = current.elapsedSeconds,
                mistakes = current.mistakes,
                hintsUsed = current.hintsUsed,
                personalBest = best
            )
        )
    }

    private fun stopTicker() {
        ticker?.cancel()
        ticker = null
    }

    private fun startTicker() {
        ticker?.cancel()
        ticker = viewModelScope.launch {
            while (isActive) {
                delay(1000)
                val current = game ?: continue
                if (_uiState.value.paused || _uiState.value.finish != null) continue
                current.elapsedSeconds += 1
                _uiState.value = _uiState.value.copy(elapsedSeconds = current.elapsedSeconds)
                if (current.elapsedSeconds % 15 == 0) persist()
            }
        }
    }

    private fun persist() {
        val current = game ?: return
        if (_uiState.value.finish != null) return
        viewModelScope.launch { runCatching { repository.saveGame(current) } }
    }

    /** Recomputes the whole board view from the engine. 81 cells is cheap enough to redo per move. */
    private fun publish() {
        val current = game ?: return
        val state = _uiState.value
        val conflicts = current.conflicts()
        val selected = state.selected
        val selectedValue = selected?.let { current.valueAt(it) } ?: 0
        val highlight = state.highlightsEnabled

        val cells = (0 until SudokuBoard.CELLS).map { index ->
            val value = current.valueAt(index)
            CellUi(
                value = value,
                notes = current.notesAt(index),
                given = current.isGiven(index),
                conflict = index in conflicts,
                selected = selected == index,
                related = highlight && selected != null && selected != index &&
                    SudokuBoard.peersOf(selected).contains(index),
                sameValue = highlight && value != 0 && value == selectedValue && selected != index
            )
        }

        _uiState.value = state.copy(
            loading = false,
            failed = false,
            difficulty = current.difficulty,
            cells = cells,
            mistakes = current.mistakes,
            hintsLeft = current.hintsLeft,
            canUndo = current.canUndo,
            elapsedSeconds = current.elapsedSeconds,
            remainingByDigit = (1..9).map { current.remaining(it) }
        )
    }

    override fun onCleared() {
        ticker?.cancel()
        super.onCleared()
    }

    companion object {
        fun factory(
            repository: GameRepository,
            preferences: UserPreferencesRepository,
            difficulty: Difficulty?
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                GameViewModel(repository, preferences, difficulty) as T
        }
    }
}
