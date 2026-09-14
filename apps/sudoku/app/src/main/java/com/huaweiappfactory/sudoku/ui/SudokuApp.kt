package com.huaweiappfactory.sudoku.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.huaweiappfactory.sudoku.SudokuApplication
import com.huaweiappfactory.sudoku.ads.LocalAdManager
import com.huaweiappfactory.sudoku.domain.Difficulty
import com.huaweiappfactory.sudoku.ui.navigation.Screen
import com.huaweiappfactory.sudoku.ui.screens.GameScreen
import com.huaweiappfactory.sudoku.ui.screens.GameViewModel
import com.huaweiappfactory.sudoku.ui.screens.HomeScreen
import com.huaweiappfactory.sudoku.ui.screens.HomeViewModel
import com.huaweiappfactory.sudoku.ui.screens.SettingsScreen
import com.huaweiappfactory.sudoku.ui.screens.SettingsViewModel
import com.huaweiappfactory.sudoku.ui.screens.StatsScreen
import com.huaweiappfactory.sudoku.ui.screens.StatsViewModel
import com.huaweiappfactory.sudoku.ui.theme.SudokuTheme

@Composable
fun SudokuApp() {
    val app = LocalContext.current.applicationContext as SudokuApplication
    val container = app.container
    val themeMode by container.userPreferencesRepository.themeMode.collectAsState(initial = "SYSTEM")

    SudokuTheme(themePreference = themeMode) {
        CompositionLocalProvider(LocalAdManager provides container.adManager) {
            val navController = rememberNavController()

            Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                NavHost(
                    navController = navController,
                    startDestination = Screen.Home.route,
                    modifier = Modifier.padding(innerPadding)
                ) {
                    composable(Screen.Home.route) {
                        val vm: HomeViewModel = viewModel(factory = HomeViewModel.factory(container.gameRepository))
                        HomeScreen(
                            viewModel = vm,
                            onContinue = { navController.navigate(Screen.Game.continueGame()) },
                            onNewGame = { navController.navigate(Screen.Game.newGame(it)) },
                            onOpenStats = { navController.navigate(Screen.Stats.route) },
                            onOpenSettings = { navController.navigate(Screen.Settings.route) }
                        )
                    }
                    composable(
                        route = Screen.Game.route,
                        arguments = listOf(
                            navArgument(Screen.Game.ARG_DIFFICULTY) {
                                type = NavType.StringType
                                defaultValue = ""
                            }
                        )
                    ) { entry ->
                        // An empty argument means "continue the saved game".
                        val raw = entry.arguments?.getString(Screen.Game.ARG_DIFFICULTY).orEmpty()
                        val difficulty = if (raw.isBlank()) null else Difficulty.fromName(raw)
                        val vm: GameViewModel = viewModel(
                            // The key makes "play again" build a new view model instead of
                            // reusing the finished one.
                            key = "game-$raw-${entry.id}",
                            factory = GameViewModel.factory(
                                container.gameRepository,
                                container.userPreferencesRepository,
                                difficulty
                            )
                        )
                        GameScreen(
                            viewModel = vm,
                            onLeave = {
                                navController.popBackStack(Screen.Home.route, inclusive = false)
                            },
                            onPlayAgain = { again ->
                                navController.navigate(Screen.Game.newGame(again)) {
                                    popUpTo(Screen.Home.route) { inclusive = false }
                                }
                            }
                        )
                    }
                    composable(Screen.Stats.route) {
                        val vm: StatsViewModel = viewModel(factory = StatsViewModel.factory(container.gameRepository))
                        StatsScreen(viewModel = vm, onBack = { navController.popBackStack() })
                    }
                    composable(Screen.Settings.route) {
                        val vm: SettingsViewModel =
                            viewModel(factory = SettingsViewModel.factory(container.userPreferencesRepository))
                        SettingsScreen(viewModel = vm, onBack = { navController.popBackStack() })
                    }
                }
            }
        }
    }
}
