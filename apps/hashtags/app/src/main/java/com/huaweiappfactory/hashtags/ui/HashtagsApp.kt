package com.huaweiappfactory.hashtags.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.huaweiappfactory.hashtags.HashtagsApplication
import com.huaweiappfactory.hashtags.ads.LocalAdManager
import com.huaweiappfactory.hashtags.domain.HashtagSet
import com.huaweiappfactory.hashtags.ui.navigation.Screen
import com.huaweiappfactory.hashtags.ui.screens.EditSetScreen
import com.huaweiappfactory.hashtags.ui.screens.EditSetViewModel
import com.huaweiappfactory.hashtags.ui.screens.SetScreen
import com.huaweiappfactory.hashtags.ui.screens.SetViewModel
import com.huaweiappfactory.hashtags.ui.screens.SettingsScreen
import com.huaweiappfactory.hashtags.ui.screens.SettingsViewModel
import com.huaweiappfactory.hashtags.ui.screens.TopicsScreen
import com.huaweiappfactory.hashtags.ui.screens.TopicsViewModel
import com.huaweiappfactory.hashtags.ui.theme.HashtagsTheme
import kotlinx.coroutines.launch

@Composable
fun HashtagsApp() {
    val app = LocalContext.current.applicationContext as HashtagsApplication
    val container = app.container
    val themeMode by container.userPreferencesRepository.themeMode.collectAsState(initial = "SYSTEM")
    val context = LocalContext.current

    // Search has to match what the user sees, and what they see for a built-in set
    // is a translated topic name the domain layer cannot resolve on its own.
    val displayName: (HashtagSet) -> String = remember(context) {
        { set -> setLabelRes(set)?.let { context.getString(it) } ?: setLiteralName(set) }
    }

    HashtagsTheme(themePreference = themeMode) {
        CompositionLocalProvider(LocalAdManager provides container.adManager) {
            val navController = rememberNavController()
            val snackbarHostState = remember { SnackbarHostState() }
            val scope = rememberCoroutineScope()

            Scaffold(
                snackbarHost = { SnackbarHost(snackbarHostState) },
                modifier = Modifier.fillMaxSize()
            ) { innerPadding ->
                NavHost(
                    navController = navController,
                    startDestination = Screen.Topics.route,
                    modifier = Modifier.padding(innerPadding)
                ) {
                    composable(Screen.Topics.route) {
                        val vm: TopicsViewModel = viewModel(
                            factory = TopicsViewModel.factory(container.hashtagRepository, displayName)
                        )
                        TopicsScreen(
                            viewModel = vm,
                            onOpenSet = { navController.navigate(Screen.Set.of(it)) },
                            onNewSet = { navController.navigate(Screen.Edit.of()) },
                            onOpenSettings = { navController.navigate(Screen.Settings.route) }
                        )
                    }
                    composable(
                        route = Screen.Set.route,
                        arguments = listOf(navArgument(Screen.Set.ARG) { type = NavType.StringType })
                    ) { entry ->
                        val setId = entry.arguments?.getString(Screen.Set.ARG).orEmpty()
                        val vm: SetViewModel = viewModel(
                            key = "set-$setId",
                            factory = SetViewModel.factory(
                                container.hashtagRepository,
                                container.userPreferencesRepository,
                                setId
                            )
                        )
                        SetScreen(
                            viewModel = vm,
                            onBack = { navController.popBackStack() },
                            onEdit = { rowId -> navController.navigate(Screen.Edit.of(rowId)) },
                            onMessage = { message ->
                                scope.launch { snackbarHostState.showSnackbar(message) }
                            }
                        )
                    }
                    composable(
                        route = Screen.Edit.route,
                        arguments = listOf(
                            navArgument(Screen.Edit.ARG) { type = NavType.LongType; defaultValue = 0L }
                        )
                    ) { entry ->
                        val rowId = entry.arguments?.getLong(Screen.Edit.ARG) ?: 0L
                        val vm: EditSetViewModel = viewModel(
                            key = "edit-$rowId-${entry.id}",
                            factory = EditSetViewModel.factory(container.hashtagRepository, rowId)
                        )
                        EditSetScreen(
                            viewModel = vm,
                            // Deleting a set makes the screen behind it stale, so go
                            // back to the topic list rather than to a set that is gone.
                            onDone = {
                                navController.popBackStack(Screen.Topics.route, inclusive = false)
                            }
                        )
                    }
                    composable(Screen.Settings.route) {
                        val vm: SettingsViewModel = viewModel(
                            factory = SettingsViewModel.factory(container.userPreferencesRepository)
                        )
                        SettingsScreen(viewModel = vm, onBack = { navController.popBackStack() })
                    }
                }
            }
        }
    }
}
