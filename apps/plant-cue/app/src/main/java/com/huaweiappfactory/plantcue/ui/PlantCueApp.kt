package com.huaweiappfactory.plantcue.ui

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
import com.huaweiappfactory.plantcue.PlantCueApplication
import com.huaweiappfactory.plantcue.ads.LocalAdManager
import com.huaweiappfactory.plantcue.ui.navigation.BOTTOM_NAV_ITEMS
import com.huaweiappfactory.plantcue.ui.navigation.Screen
import com.huaweiappfactory.plantcue.ui.screens.PlantDetailScreen
import com.huaweiappfactory.plantcue.ui.screens.PlantDetailViewModel
import com.huaweiappfactory.plantcue.ui.screens.PlantEditScreen
import com.huaweiappfactory.plantcue.ui.screens.PlantEditViewModel
import com.huaweiappfactory.plantcue.ui.screens.PlantsScreen
import com.huaweiappfactory.plantcue.ui.screens.PlantsViewModel
import com.huaweiappfactory.plantcue.ui.screens.SettingsScreen
import com.huaweiappfactory.plantcue.ui.screens.SettingsViewModel
import com.huaweiappfactory.plantcue.ui.screens.StatsScreen
import com.huaweiappfactory.plantcue.ui.screens.StatsViewModel
import com.huaweiappfactory.plantcue.ui.screens.TodayScreen
import com.huaweiappfactory.plantcue.ui.screens.TodayViewModel
import com.huaweiappfactory.plantcue.ui.theme.PlantCueTheme

/** True for a session opened from the reminder notification: no interstitials then. */
val LocalInterstitialsSuppressed = compositionLocalOf { false }

@Composable
fun PlantCueApp(launchedFromNotification: Boolean = false) {
    val app = LocalContext.current.applicationContext as PlantCueApplication
    val container = app.container
    val themeMode by container.userPreferencesRepository.themeMode.collectAsState(initial = "SYSTEM")

    PlantCueTheme(themePreference = themeMode) {
        CompositionLocalProvider(
            LocalAdManager provides container.adManager,
            LocalInterstitialsSuppressed provides launchedFromNotification
        ) {
            val navController = rememberNavController()
            val backStack by navController.currentBackStackEntryAsState()
            val currentRoute = backStack?.destination?.route
            val showBottomBar = currentRoute in listOf(
                Screen.Today.route, Screen.Plants.route, Screen.Stats.route, Screen.Settings.route
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
                        val vm: TodayViewModel = viewModel(factory = TodayViewModel.factory(container.plantRepository))
                        TodayScreen(
                            viewModel = vm,
                            onAddPlant = { navController.navigate(Screen.Edit.createRoute(0L)) },
                            onOpenPlant = { id -> navController.navigate(Screen.Detail.createRoute(id)) }
                        )
                    }
                    composable(Screen.Plants.route) {
                        val vm: PlantsViewModel = viewModel(factory = PlantsViewModel.factory(container.plantRepository))
                        PlantsScreen(
                            viewModel = vm,
                            onAddPlant = { navController.navigate(Screen.Edit.createRoute(0L)) },
                            onOpenPlant = { id -> navController.navigate(Screen.Detail.createRoute(id)) }
                        )
                    }
                    composable(Screen.Stats.route) {
                        val vm: StatsViewModel = viewModel(factory = StatsViewModel.factory(container.plantRepository))
                        StatsScreen(viewModel = vm)
                    }
                    composable(Screen.Settings.route) {
                        val vm: SettingsViewModel = viewModel(factory = SettingsViewModel.factory(container.userPreferencesRepository))
                        SettingsScreen(viewModel = vm)
                    }
                    composable(
                        route = Screen.Edit.route,
                        arguments = listOf(navArgument("plantId") { type = NavType.LongType; defaultValue = 0L })
                    ) { entry ->
                        val plantId = entry.arguments?.getLong("plantId") ?: 0L
                        val vm: PlantEditViewModel = viewModel(
                            factory = PlantEditViewModel.factory(container.plantRepository, container.userPreferencesRepository, plantId)
                        )
                        PlantEditScreen(
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
                        arguments = listOf(navArgument("plantId") { type = NavType.LongType })
                    ) { entry ->
                        val plantId = entry.arguments?.getLong("plantId") ?: 0L
                        val vm: PlantDetailViewModel = viewModel(factory = PlantDetailViewModel.factory(container.plantRepository, plantId))
                        PlantDetailScreen(
                            viewModel = vm,
                            onBack = { navController.popBackStack() },
                            onEdit = { navController.navigate(Screen.Edit.createRoute(plantId)) },
                            onDeleted = { navController.popBackStack(Screen.Today.route, inclusive = false) }
                        )
                    }
                }
            }
        }
    }
}
