package com.huaweiappfactory.translate.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.huaweiappfactory.translate.R
import com.huaweiappfactory.translate.TranslateApplication
import com.huaweiappfactory.translate.ads.LocalAdManager
import com.huaweiappfactory.translate.ui.navigation.Screen
import com.huaweiappfactory.translate.ui.screens.HistoryScreen
import com.huaweiappfactory.translate.ui.screens.HistoryViewModel
import com.huaweiappfactory.translate.ui.screens.LanguagesScreen
import com.huaweiappfactory.translate.ui.screens.LanguagesViewModel
import com.huaweiappfactory.translate.ui.screens.SettingsScreen
import com.huaweiappfactory.translate.ui.screens.SettingsViewModel
import com.huaweiappfactory.translate.ui.screens.TranslateScreen
import com.huaweiappfactory.translate.ui.screens.TranslateViewModel
import com.huaweiappfactory.translate.ui.theme.TranslateTheme

private data class Tab(val screen: Screen, val icon: ImageVector, val labelRes: Int)

private val TABS = listOf(
    Tab(Screen.Translate, Icons.Default.Translate, R.string.nav_translate),
    Tab(Screen.Languages, Icons.Default.Download, R.string.nav_languages),
    Tab(Screen.History, Icons.Default.History, R.string.nav_history),
    Tab(Screen.Settings, Icons.Default.Settings, R.string.nav_settings)
)

@Composable
fun TranslateApp() {
    val app = LocalContext.current.applicationContext as TranslateApplication
    val container = app.container
    val theme by container.userPreferencesRepository.theme.collectAsState()
    val historyEnabled by container.userPreferencesRepository.historyEnabled.collectAsState()

    TranslateTheme(themePreference = theme.name) {
        CompositionLocalProvider(LocalAdManager provides container.adManager) {
            val navController = rememberNavController()
            val backStack by navController.currentBackStackEntryAsState()
            val route = backStack?.destination?.route

            // One TranslateViewModel for the whole app, so History can put an
            // entry back on the Translate screen without a second instance
            // quietly holding the old text.
            val translateViewModel: TranslateViewModel = viewModel(
                factory = TranslateViewModel.factory(
                    container.translationEngine,
                    container.translationRepository,
                    container.userPreferencesRepository
                )
            )

            Scaffold(
                bottomBar = {
                    NavigationBar {
                        TABS.forEach { tab ->
                            NavigationBarItem(
                                selected = route == tab.screen.route,
                                onClick = {
                                    navController.navigate(tab.screen.route) {
                                        popUpTo(navController.graph.findStartDestination().id) {
                                            saveState = true
                                        }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                },
                                icon = { Icon(tab.icon, contentDescription = null) },
                                label = { Text(stringResource(tab.labelRes)) }
                            )
                        }
                    }
                }
            ) { padding ->
                NavHost(
                    navController = navController,
                    startDestination = Screen.Translate.route,
                    modifier = Modifier.padding(padding)
                ) {
                    composable(Screen.Translate.route) {
                        TranslateScreen(translateViewModel)
                    }
                    composable(Screen.Languages.route) {
                        val languagesViewModel: LanguagesViewModel = viewModel(
                            factory = LanguagesViewModel.factory(
                                container.translationEngine,
                                container.userPreferencesRepository
                            )
                        )
                        LanguagesScreen(languagesViewModel)
                    }
                    composable(Screen.History.route) {
                        val historyViewModel: HistoryViewModel = viewModel(
                            factory = HistoryViewModel.factory(container.translationRepository)
                        )
                        HistoryScreen(
                            viewModel = historyViewModel,
                            historyEnabled = historyEnabled,
                            onRestore = { source, target, text ->
                                translateViewModel.restore(source, target, text)
                                navController.navigate(Screen.Translate.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                }
                            }
                        )
                    }
                    composable(Screen.Settings.route) {
                        val settingsViewModel: SettingsViewModel = viewModel(
                            factory = SettingsViewModel.factory(
                                container.userPreferencesRepository,
                                container.translationRepository
                            )
                        )
                        SettingsScreen(settingsViewModel)
                    }
                }
            }

            // Leaving the Languages screen can have changed what is downloaded.
            if (route == Screen.Translate.route) {
                androidx.compose.runtime.LaunchedEffect(Unit) {
                    translateViewModel.refreshDownloads()
                }
            }
        }
    }
}
