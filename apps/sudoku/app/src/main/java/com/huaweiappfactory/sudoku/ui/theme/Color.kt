package com.huaweiappfactory.sudoku.ui.theme

import androidx.compose.ui.graphics.Color

// Calm, high-contrast puzzle palette. Primary: deep blue. Secondary: amber, used only
// for state the player must notice (the selected digit, a personal best).
val BluePrimary = Color(0xFF1565C0)
val BlueOnPrimary = Color(0xFFFFFFFF)
val BluePrimaryContainer = Color(0xFFD3E3FD)
val BlueOnPrimaryContainer = Color(0xFF001B3D)

val AmberSecondary = Color(0xFFEF6C00)
val AmberOnSecondary = Color(0xFFFFFFFF)
val AmberSecondaryContainer = Color(0xFFFFDDB8)
val AmberOnSecondaryContainer = Color(0xFF2E1500)

val TealTertiary = Color(0xFF00695C)
val TealOnTertiary = Color(0xFFFFFFFF)
val TealTertiaryContainer = Color(0xFFB2DFDB)
val TealOnTertiaryContainer = Color(0xFF00201C)

val ConflictError = Color(0xFFB3261E)
val ConflictErrorContainer = Color(0xFFFFDAD6)

val LightBackground = Color(0xFFFAFAFC)
val LightOnBackground = Color(0xFF1A1C1E)
val LightSurface = Color(0xFFFFFFFF)
val LightSurfaceVariant = Color(0xFFDFE2EB)
val LightOnSurfaceVariant = Color(0xFF43474E)
val LightOutline = Color(0xFF73777F)
val LightOutlineVariant = Color(0xFFC3C6CF)

val DarkPrimary = Color(0xFFA6C8FF)
val DarkOnPrimary = Color(0xFF003062)
val DarkPrimaryContainer = Color(0xFF00468A)
val DarkOnPrimaryContainer = Color(0xFFD3E3FD)
val DarkBackground = Color(0xFF121316)
val DarkOnBackground = Color(0xFFE2E2E6)
val DarkSurface = Color(0xFF1A1C1E)
val DarkSurfaceVariant = Color(0xFF43474E)
val DarkOnSurfaceVariant = Color(0xFFC3C6CF)
val DarkOutline = Color(0xFF8D9199)
val DarkOutlineVariant = Color(0xFF43474E)

/** Board-specific colours the Material scheme does not carry. */
data class BoardColors(
    val gridLine: Color,
    val blockLine: Color,
    val cellBackground: Color,
    val givenText: Color,
    val entryText: Color,
    val noteText: Color,
    val selectedCell: Color,
    val relatedCell: Color,
    val sameValueCell: Color,
    val conflictCell: Color,
    val conflictText: Color
)

val LightBoardColors = BoardColors(
    gridLine = Color(0xFFC3C6CF),
    blockLine = Color(0xFF3C4149),
    cellBackground = Color(0xFFFFFFFF),
    givenText = Color(0xFF1A1C1E),
    entryText = BluePrimary,
    noteText = Color(0xFF6B7078),
    selectedCell = Color(0xFFBBD6FB),
    relatedCell = Color(0xFFE8EEF8),
    sameValueCell = Color(0xFFD3E3FD),
    conflictCell = Color(0xFFFFDAD6),
    conflictText = ConflictError
)

val DarkBoardColors = BoardColors(
    gridLine = Color(0xFF3A3E45),
    blockLine = Color(0xFFB9BDC5),
    cellBackground = Color(0xFF1A1C1E),
    givenText = Color(0xFFE2E2E6),
    entryText = Color(0xFF8FBBFF),
    noteText = Color(0xFF9BA0A8),
    selectedCell = Color(0xFF294A72),
    relatedCell = Color(0xFF23272D),
    sameValueCell = Color(0xFF1F3454),
    conflictCell = Color(0xFF5C1A16),
    conflictText = Color(0xFFFFB4AB)
)
