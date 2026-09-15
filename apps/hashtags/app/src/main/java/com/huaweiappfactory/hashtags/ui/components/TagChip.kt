package com.huaweiappfactory.hashtags.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.hashtags.R

/**
 * A tag is always "#" followed by ASCII, so it is left-to-right text even when
 * the app is not. Without this, Arabic reorders the leading "#" to the far end
 * and every chip reads "travel#" -- seen on the phone, not in a preview.
 */
fun TextStyle.asTag(): TextStyle = copy(textDirection = TextDirection.Ltr)

/**
 * One tag.
 *
 * Selection is shown by fill AND weight AND a border, never by colour alone: a
 * grid of thirty chips is exactly where a colour-only state becomes unreadable.
 * The chip can look smaller than 48dp but its touch target never is.
 */
@androidx.compose.foundation.ExperimentalFoundationApi
@Composable
fun TagChip(
    tag: String,
    selected: Boolean,
    favourite: Boolean,
    onClick: () -> Unit,
    onLongClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    val scheme = MaterialTheme.colorScheme
    val description = stringResource(
        if (selected) R.string.cd_tag_selected else R.string.cd_tag_unselected, tag
    )
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(if (selected) scheme.secondaryContainer else scheme.surfaceVariant)
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = if (selected) scheme.secondary else scheme.outlineVariant,
                shape = RoundedCornerShape(20.dp)
            )
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
            .sizeIn(minHeight = 48.dp)
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .semantics { contentDescription = description }
    ) {
        if (favourite) {
            Icon(
                Icons.Default.Star,
                contentDescription = null,
                tint = scheme.tertiary,
                modifier = Modifier.sizeIn(maxWidth = 16.dp, maxHeight = 16.dp).padding(end = 2.dp)
            )
        }
        Text(
            text = tag,
            style = MaterialTheme.typography.bodyMedium.asTag(),
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
            color = if (selected) scheme.onSecondaryContainer else scheme.onSurfaceVariant
        )
    }
}

/** A tag in the editor, where the only action is removing it. */
@Composable
fun RemovableTagChip(tag: String, onRemove: () -> Unit, modifier: Modifier = Modifier) {
    val scheme = MaterialTheme.colorScheme
    val description = stringResource(R.string.cd_remove_tag, tag)
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(scheme.primaryContainer)
            .sizeIn(minHeight = 48.dp)
            .padding(start = 14.dp, end = 8.dp)
            .semantics { contentDescription = description }
    ) {
        Text(
            text = tag,
            style = MaterialTheme.typography.bodyMedium.asTag(),
            color = scheme.onPrimaryContainer
        )
        Icon(
            Icons.Default.Close,
            contentDescription = null,
            tint = scheme.onPrimaryContainer,
            modifier = Modifier
                .padding(start = 4.dp)
                .clip(RoundedCornerShape(20.dp))
                .clickable(onClick = onRemove)
                .sizeIn(minWidth = 40.dp, minHeight = 40.dp)
                .padding(10.dp)
        )
    }
}
