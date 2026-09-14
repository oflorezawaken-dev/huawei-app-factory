package com.huaweiappfactory.hashtags.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = DarkPrimary,
    onPrimary = DarkOnPrimary,
    primaryContainer = DarkPrimaryContainer,
    onPrimaryContainer = DarkOnPrimaryContainer,
    secondary = TealSecondaryContainer,
    onSecondary = TealOnSecondaryContainer,
    secondaryContainer = Argb(0xFF00504A),
    onSecondaryContainer = TealSecondaryContainer,
    tertiary = AmberTertiaryContainer,
    onTertiary = AmberOnTertiaryContainer,
    tertiaryContainer = Argb(0xFF6A3A00),
    onTertiaryContainer = AmberTertiaryContainer,
    error = Argb(0xFFFFB4AB),
    onError = Argb(0xFF601410),
    errorContainer = Argb(0xFF8C1D18),
    onErrorContainer = Argb(0xFFF9DEDC),
    background = DarkBackground,
    onBackground = DarkOnBackground,
    surface = DarkSurface,
    onSurface = DarkOnBackground,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = DarkOnSurfaceVariant,
    outline = DarkOutline,
    outlineVariant = DarkOutlineVariant
)

private val LightColorScheme = lightColorScheme(
    primary = PurplePrimary,
    onPrimary = PurpleOnPrimary,
    primaryContainer = PurplePrimaryContainer,
    onPrimaryContainer = PurpleOnPrimaryContainer,
    secondary = TealSecondary,
    onSecondary = TealOnSecondary,
    secondaryContainer = TealSecondaryContainer,
    onSecondaryContainer = TealOnSecondaryContainer,
    tertiary = AmberTertiary,
    onTertiary = AmberOnTertiary,
    tertiaryContainer = AmberTertiaryContainer,
    onTertiaryContainer = AmberOnTertiaryContainer,
    error = WarnError,
    errorContainer = WarnErrorContainer,
    background = LightBackground,
    onBackground = LightOnBackground,
    surface = LightSurface,
    onSurface = LightOnBackground,
    surfaceVariant = LightSurfaceVariant,
    onSurfaceVariant = LightOnSurfaceVariant,
    outline = LightOutline,
    outlineVariant = LightOutlineVariant
)

private fun Argb(argb: Long) = androidx.compose.ui.graphics.Color(argb)

@Composable
fun HashtagsTheme(
    themePreference: String = "SYSTEM", // SYSTEM, LIGHT, DARK
    content: @Composable () -> Unit
) {
    val dark = when (themePreference) {
        "LIGHT" -> false
        "DARK" -> true
        else -> isSystemInDarkTheme()
    }

    // enableEdgeToEdge() takes the system bar icons from the SYSTEM dark mode, so
    // forcing the light theme on a dark phone leaves white icons on a white bar.
    // The app's own choice has to drive them. (Learned on sudoku, 2026-09-14.)
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !dark
                isAppearanceLightNavigationBars = !dark
            }
        }
    }

    MaterialTheme(
        colorScheme = if (dark) DarkColorScheme else LightColorScheme,
        content = content
    )
}
