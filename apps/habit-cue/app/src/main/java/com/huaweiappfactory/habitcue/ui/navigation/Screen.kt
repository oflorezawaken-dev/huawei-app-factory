package com.huaweiappfactory.habitcue.ui.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Today
import androidx.compose.ui.graphics.vector.ImageVector
import com.huaweiappfactory.habitcue.R

sealed class Screen(val route: String) {
    object Today : Screen("today")
    object Habits : Screen("habits")
    object Stats : Screen("stats")
    object Settings : Screen("settings")

    object Edit : Screen("habit/edit?habitId={habitId}") {
        fun createRoute(habitId: Long = 0L) = "habit/edit?habitId=$habitId"
    }

    object Detail : Screen("habit/{habitId}") {
        fun createRoute(habitId: Long) = "habit/$habitId"
    }
}

data class BottomNavItem(
    val screen: Screen,
    @StringRes val labelRes: Int,
    val icon: ImageVector,
    val testTag: String
)

val BOTTOM_NAV_ITEMS = listOf(
    BottomNavItem(Screen.Today, R.string.nav_today, Icons.Default.Today, "nav_item_today"),
    BottomNavItem(Screen.Habits, R.string.nav_habits, Icons.Default.CheckCircle, "nav_item_habits"),
    BottomNavItem(Screen.Stats, R.string.nav_stats, Icons.Default.BarChart, "nav_item_stats"),
    BottomNavItem(Screen.Settings, R.string.nav_settings, Icons.Default.Settings, "nav_item_settings")
)
