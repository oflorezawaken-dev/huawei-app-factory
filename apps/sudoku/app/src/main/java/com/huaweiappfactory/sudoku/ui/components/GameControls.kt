package com.huaweiappfactory.sudoku.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.automirrored.outlined.Backspace
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.huaweiappfactory.sudoku.R

/** Undo, erase, notes and hint. A disabled control stays in place, dimmed, so nothing jumps. */
@Composable
fun ActionRow(
    canUndo: Boolean,
    notesMode: Boolean,
    hintsLeft: Int,
    enabled: Boolean,
    onUndo: () -> Unit,
    onErase: () -> Unit,
    onToggleNotes: () -> Unit,
    onHint: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth().padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        ActionButton(
            icon = Icons.AutoMirrored.Filled.Undo,
            label = stringResource(R.string.action_undo),
            enabled = enabled && canUndo,
            onClick = onUndo,
            testTag = "action_undo"
        )
        ActionButton(
            icon = Icons.AutoMirrored.Outlined.Backspace,
            label = stringResource(R.string.action_erase),
            enabled = enabled,
            onClick = onErase,
            testTag = "action_erase"
        )
        ActionButton(
            icon = Icons.Outlined.Edit,
            label = stringResource(if (notesMode) R.string.notes_on else R.string.notes_off),
            enabled = enabled,
            highlighted = notesMode,
            onClick = onToggleNotes,
            testTag = "action_notes"
        )
        ActionButton(
            icon = Icons.Default.Lightbulb,
            label = stringResource(R.string.action_hint),
            caption = stringResource(R.string.hints_left, hintsLeft),
            enabled = enabled && hintsLeft > 0,
            onClick = onHint,
            testTag = "action_hint"
        )
    }
}

@Composable
private fun ActionButton(
    icon: ImageVector,
    label: String,
    enabled: Boolean,
    onClick: () -> Unit,
    testTag: String,
    caption: String? = null,
    highlighted: Boolean = false
) {
    val tint = if (highlighted) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(enabled = enabled, onClick = onClick)
            .sizeIn(minWidth = 56.dp, minHeight = 56.dp)
            .padding(horizontal = 8.dp, vertical = 6.dp)
            .alpha(if (enabled) 1f else 0.38f)
            .testTag(testTag)
            .semantics { contentDescription = caption?.let { "$label, $it" } ?: label }
    ) {
        Icon(icon, contentDescription = null, tint = tint)
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = tint,
            fontWeight = if (highlighted) FontWeight.Bold else FontWeight.Normal
        )
        if (caption != null) {
            Text(
                text = caption,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Digits 1-9 with how many of each are still missing. A finished digit is dimmed
 * instead of removed, so the pad never reflows under the player's thumb.
 */
@Composable
fun NumberPad(
    remainingByDigit: List<Int>,
    notesMode: Boolean,
    enabled: Boolean,
    onDigit: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth().padding(horizontal = 4.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        for (digit in 1..9) {
            val remaining = remainingByDigit.getOrElse(digit - 1) { 0 }
            val active = enabled && remaining > 0
            val description = stringResource(
                if (notesMode) R.string.cd_number_notes else R.string.cd_number,
                digit
            )
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable(enabled = active) { onDigit(digit) }
                    .alpha(if (active) 1f else 0.35f)
                    .testTag("pad_$digit")
                    .semantics { contentDescription = description }
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(
                            if (notesMode) MaterialTheme.colorScheme.secondaryContainer
                            else MaterialTheme.colorScheme.primaryContainer
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = digit.toString(),
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (notesMode) MaterialTheme.colorScheme.onSecondaryContainer
                        else MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
                Text(
                    text = remaining.toString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
