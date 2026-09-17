package com.huaweiappfactory.translate.ui.navigation

sealed class Screen(val route: String) {
    object Translate : Screen("translate")
    object Languages : Screen("languages")
    object History : Screen("history")
    object Settings : Screen("settings")
}
