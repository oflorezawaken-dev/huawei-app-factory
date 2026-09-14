package com.huaweiappfactory.sudoku.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = DarkPrimary,
    onPrimary = DarkOnPrimary,
    primaryContainer = DarkPrimaryContainer,
    onPrimaryContainer = DarkOnPrimaryContainer,
    secondary = AmberSecondaryContainer,
    onSecondary = AmberOnSecondaryContainer,
    secondaryContainer = Argb(0xFF6A3A00),
    onSecondaryContainer = AmberSecondaryContainer,
    tertiary = TealTertiaryContainer,
    onTertiary = TealOnTertiaryContainer,
    tertiaryContainer = Argb(0xFF004D44),
    onTertiaryContainer = TealTertiaryContainer,
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
    primary = BluePrimary,
    onPrimary = BlueOnPrimary,
    primaryContainer = BluePrimaryContainer,
    onPrimaryContainer = BlueOnPrimaryContainer,
    secondary = AmberSecondary,
    onSecondary = AmberOnSecondary,
    secondaryContainer = AmberSecondaryContainer,
    onSecondaryContainer = AmberOnSecondaryContainer,
    tertiary = TealTertiary,
    onTertiary = TealOnTertiary,
    tertiaryContainer = TealTertiaryContainer,
    onTertiaryContainer = TealOnTertiaryContainer,
    error = ConflictError,
    errorContainer = ConflictErrorContainer,
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

/** Board colours travel beside the Material scheme so the grid can read them directly. */
val LocalBoardColors = staticCompositionLocalOf { LightBoardColors }

@Composable
fun SudokuTheme(
    themePreference: String = "SYSTEM", // SYSTEM, LIGHT, DARK
    content: @Composable () -> Unit
) {
    val dark = when (themePreference) {
        "LIGHT" -> false
        "DARK" -> true
        else -> isSystemInDarkTheme()
    }

    // enableEdgeToEdge() picks the system bar icons from the SYSTEM dark mode, so a
    // player who forces the light theme on a dark phone gets white status icons on a
    // white background. The app's own choice has to drive them.
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

    CompositionLocalProvider(LocalBoardColors provides if (dark) DarkBoardColors else LightBoardColors) {
        MaterialTheme(
            colorScheme = if (dark) DarkColorScheme else LightColorScheme,
            content = content
        )
    }
}
