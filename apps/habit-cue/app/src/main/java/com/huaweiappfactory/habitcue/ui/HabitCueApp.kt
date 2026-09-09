package com.huaweiappfactory.habitcue.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.huaweiappfactory.habitcue.HabitCueApplication
import com.huaweiappfactory.habitcue.ads.LocalAdManager
import com.huaweiappfactory.habitcue.ui.navigation.BOTTOM_NAV_ITEMS
import com.huaweiappfactory.habitcue.ui.navigation.Screen
import com.huaweiappfactory.habitcue.ui.screens.HabitDetailScreen
import com.huaweiappfactory.habitcue.ui.screens.HabitDetailViewModel
import com.huaweiappfactory.habitcue.ui.screens.HabitEditScreen
import com.huaweiappfactory.habitcue.ui.screens.HabitEditViewModel
import com.huaweiappfactory.habitcue.ui.screens.HabitsScreen
import com.huaweiappfactory.habitcue.ui.screens.HabitsViewModel
import com.huaweiappfactory.habitcue.ui.screens.SettingsScreen
import com.huaweiappfactory.habitcue.ui.screens.SettingsViewModel
import com.huaweiappfactory.habitcue.ui.screens.StatsScreen
import com.huaweiappfactory.habitcue.ui.screens.StatsViewModel
import com.huaweiappfactory.habitcue.ui.screens.TodayScreen
import com.huaweiappfactory.habitcue.ui.screens.TodayViewModel
import com.huaweiappfactory.habitcue.ui.theme.HabitCueTheme

/** True for a session opened from the reminder notification: no interstitials then. */
val LocalInterstitialsSuppressed = compositionLocalOf { false }

@Composable
fun HabitCueApp(launchedFromNotification: Boolean = false) {
    val app = LocalContext.current.applicationContext as HabitCueApplication
    val container = app.container
    val themeMode by container.userPreferencesRepository.themeMode.collectAsState(initial = "SYSTEM")

    HabitCueTheme(themePreference = themeMode) {
        CompositionLocalProvider(
            LocalAdManager provides container.adManager,
            LocalInterstitialsSuppressed provides launchedFromNotification
        ) {
            val navController = rememberNavController()
            val backStack by navController.currentBackStackEntryAsState()
            val currentRoute = backStack?.destination?.route
            val showBottomBar = currentRoute in listOf(
                Screen.Today.route, Screen.Habits.route, Screen.Stats.route, Screen.Settings.route
            )

            Scaffold(
                bottomBar = {
                    if (showBottomBar) {
                        NavigationBar(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant,
                            tonalElevation = 0.dp,
                            modifier = Modifier.testTag("app_bottom_navigation")
                        ) {
                            BOTTOM_NAV_ITEMS.forEach { item ->
                                val selected = currentRoute == item.screen.route
                                NavigationBarItem(
                                    icon = { Icon(item.icon, contentDescription = stringResource(item.labelRes)) },
                                    label = {
                                        Text(
                                            stringResource(item.labelRes),
                                            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium
                                        )
                                    },
                                    selected = selected,
                                    onClick = {
                                        if (!selected) {
                                            navController.navigate(item.screen.route) {
                                                popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                                launchSingleTop = true
                                                restoreState = true
                                            }
                                        }
                                    },
                                    modifier = Modifier.testTag(item.testTag)
                                )
                            }
                        }
                    }
                },
                modifier = Modifier.fillMaxSize()
            ) { innerPadding ->
                NavHost(
                    navController = navController,
                    startDestination = Screen.Today.route,
                    modifier = Modifier.padding(innerPadding)
                ) {
                    composable(Screen.Today.route) {
                        val vm: TodayViewModel = viewModel(factory = TodayViewModel.factory(container.habitRepository))
                        TodayScreen(
                            viewModel = vm,
                            onAddHabit = { navController.navigate(Screen.Edit.createRoute(0L)) },
                            onOpenHabit = { id -> navController.navigate(Screen.Detail.createRoute(id)) }
                        )
                    }
                    composable(Screen.Habits.route) {
                        val vm: HabitsViewModel = viewModel(factory = HabitsViewModel.factory(container.habitRepository))
                        HabitsScreen(
                            viewModel = vm,
                            onAddHabit = { navController.navigate(Screen.Edit.createRoute(0L)) },
                            onOpenHabit = { id -> navController.navigate(Screen.Detail.createRoute(id)) }
                        )
                    }
                    composable(Screen.Stats.route) {
                        val vm: StatsViewModel = viewModel(factory = StatsViewModel.factory(container.habitRepository))
                        StatsScreen(viewModel = vm)
                    }
                    composable(Screen.Settings.route) {
                        val vm: SettingsViewModel = viewModel(factory = SettingsViewModel.factory(container.userPreferencesRepository))
                        SettingsScreen(viewModel = vm)
                    }
                    composable(
                        route = Screen.Edit.route,
                        arguments = listOf(navArgument("habitId") { type = NavType.LongType; defaultValue = 0L })
                    ) { entry ->
                        val habitId = entry.arguments?.getLong("habitId") ?: 0L
                        val vm: HabitEditViewModel = viewModel(
                            factory = HabitEditViewModel.factory(container.habitRepository, container.userPreferencesRepository, habitId)
                        )
                        HabitEditScreen(
                            viewModel = vm,
                            onBack = { navController.popBackStack() },
                            onSaved = { savedId ->
                                navController.navigate(Screen.Detail.createRoute(savedId)) {
                                    popUpTo(Screen.Today.route)
                                }
                            }
                        )
                    }
                    composable(
                        route = Screen.Detail.route,
                        arguments = listOf(navArgument("habitId") { type = NavType.LongType })
                    ) { entry ->
                        val habitId = entry.arguments?.getLong("habitId") ?: 0L
                        val vm: HabitDetailViewModel = viewModel(factory = HabitDetailViewModel.factory(container.habitRepository, habitId))
                        HabitDetailScreen(
                            viewModel = vm,
                            onBack = { navController.popBackStack() },
                            onEdit = { navController.navigate(Screen.Edit.createRoute(habitId)) },
                            onDeleted = { navController.popBackStack(Screen.Today.route, inclusive = false) }
                        )
                    }
                }
            }
        }
    }
}
