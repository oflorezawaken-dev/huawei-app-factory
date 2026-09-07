package com.huaweiappfactory.plantcue.ui.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.LocalFlorist
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Today
import androidx.compose.ui.graphics.vector.ImageVector
import com.huaweiappfactory.plantcue.R

sealed class Screen(val route: String) {
    object Today : Screen("today")
    object Plants : Screen("plants")
    object Stats : Screen("stats")
    object Settings : Screen("settings")

    object Edit : Screen("plant/edit?plantId={plantId}") {
        fun createRoute(plantId: Long = 0L) = "plant/edit?plantId=$plantId"
    }

    object Detail : Screen("plant/{plantId}") {
        fun createRoute(plantId: Long) = "plant/$plantId"
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
    BottomNavItem(Screen.Plants, R.string.nav_plants, Icons.Default.LocalFlorist, "nav_item_plants"),
    BottomNavItem(Screen.Stats, R.string.nav_stats, Icons.Default.BarChart, "nav_item_stats"),
    BottomNavItem(Screen.Settings, R.string.nav_settings, Icons.Default.Settings, "nav_item_settings")
)
