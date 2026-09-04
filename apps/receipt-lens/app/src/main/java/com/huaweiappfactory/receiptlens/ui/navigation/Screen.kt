package com.huaweiappfactory.receiptlens.ui.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.ui.graphics.vector.ImageVector
import com.example.R

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object History : Screen("history?category={category}") {
        fun createRoute(category: String? = null) = if (category != null) "history?category=$category" else "history"
    }
    object Statistics : Screen("statistics")
    object Settings : Screen("settings")

    object Scan : Screen("scan")
    object Review : Screen("review?receiptId={receiptId}&imagePath={imagePath}") {
        fun createRoute(receiptId: Long = 0L, imagePath: String? = null): String {
            val encodedPath = imagePath?.let { java.net.URLEncoder.encode(it, "UTF-8") } ?: ""
            return "review?receiptId=$receiptId&imagePath=$encodedPath"
        }
    }
    object Detail : Screen("detail/{receiptId}") {
        fun createRoute(receiptId: Long) = "detail/$receiptId"
    }
}

data class BottomNavItem(
    val screen: Screen,
    @StringRes val labelRes: Int,
    val icon: ImageVector,
    val testTag: String
)

val BOTTOM_NAV_ITEMS = listOf(
    BottomNavItem(Screen.Home, R.string.nav_home, Icons.Default.Home, "nav_item_home"),
    BottomNavItem(Screen.History, R.string.nav_history, Icons.AutoMirrored.Filled.ReceiptLong, "nav_item_history"),
    BottomNavItem(Screen.Statistics, R.string.nav_statistics, Icons.Default.BarChart, "nav_item_statistics"),
    BottomNavItem(Screen.Settings, R.string.nav_settings, Icons.Default.Settings, "nav_item_settings")
)
