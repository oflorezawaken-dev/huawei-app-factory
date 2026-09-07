package com.huaweiappfactory.plantcue.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val DarkColorScheme = darkColorScheme(
    primary = DarkPrimary,
    onPrimary = DarkOnPrimary,
    primaryContainer = DarkPrimaryContainer,
    onPrimaryContainer = DarkOnPrimaryContainer,
    secondary = PotSecondaryContainer,
    onSecondary = PotOnSecondaryContainer,
    secondaryContainer = Color3(0xFF4A3B35),
    onSecondaryContainer = PotSecondaryContainer,
    tertiary = WaterTertiaryContainer,
    onTertiary = WaterOnTertiaryContainer,
    tertiaryContainer = Color3(0xFF004D44),
    onTertiaryContainer = WaterTertiaryContainer,
    error = Color3(0xFFF2B8B5),
    onError = Color3(0xFF601410),
    errorContainer = Color3(0xFF8C1D18),
    onErrorContainer = Color3(0xFFF9DEDC),
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
    primary = LeafPrimary,
    onPrimary = LeafOnPrimary,
    primaryContainer = LeafPrimaryContainer,
    onPrimaryContainer = LeafOnPrimaryContainer,
    secondary = PotSecondary,
    onSecondary = PotOnSecondary,
    secondaryContainer = PotSecondaryContainer,
    onSecondaryContainer = PotOnSecondaryContainer,
    tertiary = WaterTertiary,
    onTertiary = WaterOnTertiary,
    tertiaryContainer = WaterTertiaryContainer,
    onTertiaryContainer = WaterOnTertiaryContainer,
    error = OverdueError,
    errorContainer = OverdueErrorContainer,
    background = LightBackground,
    onBackground = LightOnBackground,
    surface = LightSurface,
    onSurface = LightOnBackground,
    surfaceVariant = LightSurfaceVariant,
    onSurfaceVariant = LightOnSurfaceVariant,
    outline = LightOutline,
    outlineVariant = LightOutlineVariant
)

private fun Color3(argb: Long) = androidx.compose.ui.graphics.Color(argb)

@Composable
fun PlantCueTheme(
    themePreference: String = "SYSTEM", // SYSTEM, LIGHT, DARK
    content: @Composable () -> Unit
) {
    val dark = when (themePreference) {
        "LIGHT" -> false
        "DARK" -> true
        else -> isSystemInDarkTheme()
    }
    MaterialTheme(
        colorScheme = if (dark) DarkColorScheme else LightColorScheme,
        content = content
    )
}
