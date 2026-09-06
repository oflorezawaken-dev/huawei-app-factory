package com.huaweiappfactory.receiptlens.ui

import android.net.Uri
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.ExitTransition
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
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
import com.huaweiappfactory.receiptlens.ReceiptLensApplication
import com.huaweiappfactory.receiptlens.ui.navigation.BOTTOM_NAV_ITEMS
import com.huaweiappfactory.receiptlens.ui.navigation.Screen
import com.huaweiappfactory.receiptlens.ui.screens.DetailScreen
import com.huaweiappfactory.receiptlens.ui.screens.DetailViewModel
import com.huaweiappfactory.receiptlens.ui.screens.HistoryScreen
import com.huaweiappfactory.receiptlens.ui.screens.HistoryViewModel
import com.huaweiappfactory.receiptlens.ui.screens.HomeScreen
import com.huaweiappfactory.receiptlens.ui.screens.HomeViewModel
import com.huaweiappfactory.receiptlens.ui.screens.ReviewReceiptScreen
import com.huaweiappfactory.receiptlens.ui.screens.ReviewViewModel
import com.huaweiappfactory.receiptlens.ui.screens.ScanScreen
import com.huaweiappfactory.receiptlens.ui.screens.SettingsScreen
import com.huaweiappfactory.receiptlens.ui.screens.SettingsViewModel
import com.huaweiappfactory.receiptlens.ui.screens.StatisticsScreen
import com.huaweiappfactory.receiptlens.ui.screens.StatisticsViewModel
import com.huaweiappfactory.receiptlens.ui.theme.ReceiptLensTheme
import java.net.URLDecoder

@Composable
fun ReceiptLensApp() {
    val context = LocalContext.current.applicationContext as ReceiptLensApplication
    val container = context.container
    val userPreferencesRepository = container.userPreferencesRepository
    val themeMode by userPreferencesRepository.themeMode.collectAsState(initial = "SYSTEM")

    ReceiptLensTheme(themePreference = themeMode) {
        val navController = rememberNavController()
        val navBackStackEntry by navController.currentBackStackEntryAsState()
        val currentRoute = navBackStackEntry?.destination?.route

        // Determine if bottom navigation should be displayed
        val showBottomBar = currentRoute in listOf(
            Screen.Home.route,
            Screen.History.route,
            Screen.Statistics.route,
            Screen.Settings.route
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
                            val selected = currentRoute?.startsWith(item.screen.route.substringBefore("?")) == true
                            NavigationBarItem(
                                icon = { Icon(imageVector = item.icon, contentDescription = stringResource(item.labelRes)) },
                                label = {
                                    Text(
                                        text = stringResource(item.labelRes),
                                        fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium
                                    )
                                },
                                selected = selected,
                                colors = NavigationBarItemDefaults.colors(
                                    selectedIconColor = MaterialTheme.colorScheme.onPrimaryContainer,
                                    selectedTextColor = MaterialTheme.colorScheme.onPrimaryContainer,
                                    indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                                    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                                    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant
                                ),
                                onClick = {
                                    if (!selected) {
                                        navController.navigate(item.screen.route) {
                                            popUpTo(navController.graph.findStartDestination().id) {
                                                saveState = true
                                            }
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
                startDestination = Screen.Home.route,
                enterTransition = { EnterTransition.None },
                exitTransition = { ExitTransition.None },
                modifier = Modifier.padding(innerPadding)
            ) {
                // HOME
                composable(Screen.Home.route) {
                    val homeViewModel: HomeViewModel = viewModel(
                        factory = HomeViewModel.provideFactory(
                            container.receiptRepository,
                            container.userPreferencesRepository
                        )
                    )
                    HomeScreen(
                        viewModel = homeViewModel,
                        onNavigateToScan = { navController.navigate(Screen.Scan.route) },
                        onNavigateToManualEntry = {
                            navController.navigate(Screen.Review.createRoute(0L, null))
                        },
                        onNavigateToHistory = { navController.navigate(Screen.History.createRoute()) },
                        onNavigateToDetail = { id ->
                            navController.navigate(Screen.Detail.createRoute(id))
                        },
                        onImageImported = { uri ->
                            // Encode URI and open Review
                            navController.navigate(Screen.Review.createRoute(0L, uri.toString()))
                        }
                    )
                }

                // SCAN
                composable(Screen.Scan.route) {
                    ScanScreen(
                        onPhotoAccepted = { imagePath ->
                            navController.navigate(Screen.Review.createRoute(0L, imagePath)) {
                                popUpTo(Screen.Scan.route) { inclusive = true }
                            }
                        },
                        onNavigateBack = { navController.popBackStack() },
                        onImportImage = { uri ->
                            navController.navigate(Screen.Review.createRoute(0L, uri.toString())) {
                                popUpTo(Screen.Scan.route) { inclusive = true }
                            }
                        },
                        onManualEntry = {
                            navController.navigate(Screen.Review.createRoute(0L, null)) {
                                popUpTo(Screen.Scan.route) { inclusive = true }
                            }
                        }
                    )
                }

                // REVIEW / MANUAL / EDIT
                composable(
                    route = Screen.Review.route,
                    arguments = listOf(
                        navArgument("receiptId") {
                            type = NavType.LongType
                            defaultValue = 0L
                        },
                        navArgument("imagePath") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        }
                    )
                ) { backStackEntry ->
                    val receiptId = backStackEntry.arguments?.getLong("receiptId") ?: 0L
                    val rawImagePath = backStackEntry.arguments?.getString("imagePath")
                    val imagePath = if (!rawImagePath.isNullOrBlank()) {
                        try {
                            URLDecoder.decode(rawImagePath, "UTF-8")
                        } catch (_: Exception) {
                            rawImagePath
                        }
                    } else null

                    val isUri = imagePath?.startsWith("content://") == true || imagePath?.startsWith("file://") == true
                    val actualPath = if (isUri) null else imagePath

                    val reviewViewModel: ReviewViewModel = viewModel(
                        factory = ReviewViewModel.provideFactory(
                            container.receiptRepository,
                            container.userPreferencesRepository,
                            container.ocrService,
                            context,
                            receiptId,
                            actualPath
                        )
                    )

                    // If uri passed, process it
                    if (isUri && imagePath != null) {
                        reviewViewModel.processImageFromUri(Uri.parse(imagePath))
                    }

                    ReviewReceiptScreen(
                        viewModel = reviewViewModel,
                        onNavigateBack = { navController.popBackStack() },
                        onReceiptSaved = { savedId ->
                            navController.navigate(Screen.Detail.createRoute(savedId)) {
                                popUpTo(Screen.Home.route)
                            }
                        }
                    )
                }

                // HISTORY
                composable(
                    route = Screen.History.route,
                    arguments = listOf(
                        navArgument("category") {
                            type = NavType.StringType
                            nullable = true
                            defaultValue = null
                        }
                    )
                ) { backStackEntry ->
                    val category = backStackEntry.arguments?.getString("category")
                    val historyViewModel: HistoryViewModel = viewModel(
                        factory = HistoryViewModel.provideFactory(
                            container.receiptRepository,
                            category
                        )
                    )
                    HistoryScreen(
                        viewModel = historyViewModel,
                        onNavigateToDetail = { id ->
                            navController.navigate(Screen.Detail.createRoute(id))
                        },
                        onNavigateToScan = { navController.navigate(Screen.Scan.route) }
                    )
                }

                // DETAIL
                composable(
                    route = Screen.Detail.route,
                    arguments = listOf(
                        navArgument("receiptId") { type = NavType.LongType }
                    )
                ) { backStackEntry ->
                    val receiptId = backStackEntry.arguments?.getLong("receiptId") ?: 0L
                    val detailViewModel: DetailViewModel = viewModel(
                        factory = DetailViewModel.provideFactory(
                            container.receiptRepository,
                            receiptId
                        )
                    )
                    DetailScreen(
                        viewModel = detailViewModel,
                        onNavigateBack = { navController.popBackStack() },
                        onNavigateToEdit = { editId ->
                            navController.navigate(Screen.Review.createRoute(editId, null))
                        }
                    )
                }

                // STATISTICS
                composable(Screen.Statistics.route) {
                    val statisticsViewModel: StatisticsViewModel = viewModel(
                        factory = StatisticsViewModel.provideFactory(
                            container.receiptRepository,
                            container.userPreferencesRepository
                        )
                    )
                    StatisticsScreen(
                        viewModel = statisticsViewModel,
                        onNavigateToScan = { navController.navigate(Screen.Scan.route) }
                    )
                }

                // SETTINGS
                composable(Screen.Settings.route) {
                    val settingsViewModel: SettingsViewModel = viewModel(
                        factory = SettingsViewModel.provideFactory(
                            container.userPreferencesRepository,
                            container.receiptRepository,
                            container.adManager
                        )
                    )
                    SettingsScreen(viewModel = settingsViewModel)
                }
            }
        }
    }
}
