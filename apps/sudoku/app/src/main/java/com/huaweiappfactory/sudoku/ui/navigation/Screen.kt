package com.huaweiappfactory.sudoku.ui.navigation

import com.huaweiappfactory.sudoku.domain.Difficulty

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object Stats : Screen("stats")
    object Settings : Screen("settings")

    /** An empty difficulty means "continue the saved game". */
    object Game : Screen("game?difficulty={difficulty}") {
        const val ARG_DIFFICULTY = "difficulty"
        fun newGame(difficulty: Difficulty) = "game?difficulty=${difficulty.name}"
        fun continueGame() = "game?difficulty="
    }
}
