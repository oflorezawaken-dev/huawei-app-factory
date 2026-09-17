package com.huaweiappfactory.translate.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.translate.domain.Language

/**
 * One side of the pair.
 *
 * Full width rather than a chip: ~360dp is the whole budget on the test phone
 * (factory rule 8), language names in German and Turkish are long, and a
 * one-handed tap in a hurry is the actual use.
 */
@Composable
fun LanguagePicker(
    label: String,
    selectedCode: String,
    languages: List<Language>,
    downloaded: Set<String>,
    onPick: (String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    var expanded by remember { mutableStateOf(false) }
    val selected = languages.firstOrNull { it.code == selectedCode }

    Column(modifier = modifier) {
        Text(label, style = MaterialTheme.typography.labelMedium)
        OutlinedButton(
            onClick = { expanded = true },
            enabled = enabled && languages.isNotEmpty(),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(
                text = selected?.displayName ?: selectedCode,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        Box {
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                modifier = Modifier.heightIn(max = 420.dp)
            ) {
                languages.forEach { language ->
                    DropdownMenuItem(
                        text = {
                            Column {
                                Text(language.displayName)
                                // Downloaded is the difference between "works on
                                // the plane" and "needs 27 MB first", so it is
                                // on the row, not hidden behind another screen.
                                if (language.code in downloaded) {
                                    Text(
                                        text = "✓",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        },
                        onClick = {
                            expanded = false
                            onPick(language.code)
                        },
                        modifier = Modifier.padding(horizontal = 4.dp)
                    )
                }
            }
        }
    }
}
