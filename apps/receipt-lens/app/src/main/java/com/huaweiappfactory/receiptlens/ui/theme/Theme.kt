package com.huaweiappfactory.receiptlens.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val DarkColorScheme = darkColorScheme(
    primary = UtilityDarkPrimary,
    onPrimary = Color(0xFF003062),
    primaryContainer = UtilityDarkPrimaryContainer,
    onPrimaryContainer = UtilityDarkOnPrimaryContainer,
    secondary = UtilitySlateSecondary,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFF3E4758),
    onSecondaryContainer = UtilitySlateContainer,
    tertiary = UtilityTertiary,
    onTertiary = Color.White,
    background = UtilityDarkBackground,
    onBackground = UtilityDarkOnBackground,
    surface = UtilityDarkSurface,
    onSurface = UtilityDarkOnSurface,
    surfaceVariant = UtilityDarkSurfaceVariant,
    onSurfaceVariant = UtilityDarkOnSurfaceVariant,
    outline = UtilityDarkOutline,
    outlineVariant = UtilityDarkOutlineSubtle
)

private val LightColorScheme = lightColorScheme(
    primary = UtilityBluePrimary,
    onPrimary = UtilityBlueOnPrimary,
    primaryContainer = UtilityBlueContainer,
    onPrimaryContainer = UtilityBlueOnContainer,
    secondary = UtilitySlateSecondary,
    onSecondary = Color.White,
    secondaryContainer = UtilitySlateContainer,
    onSecondaryContainer = UtilitySlateOnContainer,
    tertiary = UtilityTertiary,
    onTertiary = Color.White,
    background = UtilityBackground,
    onBackground = UtilityOnBackground,
    surface = UtilitySurface,
    onSurface = UtilityOnSurface,
    surfaceVariant = UtilitySurfaceVariant,
    onSurfaceVariant = UtilityOnSurfaceVariant,
    outline = UtilityOutline,
    outlineVariant = UtilityOutlineSubtle
)

@Composable
fun ReceiptLensTheme(
    themePreference: String = "SYSTEM", // "SYSTEM", "LIGHT", "DARK"
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val darkTheme = when (themePreference) {
        "LIGHT" -> false
        "DARK" -> true
        else -> isSystemInDarkTheme()
    }

    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
