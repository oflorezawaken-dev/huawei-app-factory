package com.huaweiappfactory.hashtags.ui.navigation

sealed class Screen(val route: String) {
    object Topics : Screen("topics")
    object Settings : Screen("settings")

    /** setId is a domain id: a built-in topic name, "favourites", or "custom:<rowId>". */
    object Set : Screen("set/{setId}") {
        const val ARG = "setId"
        fun of(setId: String) = "set/$setId"
    }

    /** rowId 0 means a new set. */
    object Edit : Screen("edit?rowId={rowId}") {
        const val ARG = "rowId"
        fun of(rowId: Long = 0L) = "edit?rowId=$rowId"
    }
}
