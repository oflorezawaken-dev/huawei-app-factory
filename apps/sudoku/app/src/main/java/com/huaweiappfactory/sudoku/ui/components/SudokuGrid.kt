package com.huaweiappfactory.sudoku.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import com.huaweiappfactory.sudoku.R
import com.huaweiappfactory.sudoku.domain.SudokuBoard
import com.huaweiappfactory.sudoku.ui.screens.CellUi
import com.huaweiappfactory.sudoku.ui.theme.LocalBoardColors

/**
 * The 9x9 grid. Always square, sized from the available width, so it fits without
 * scrolling on a small screen. Block separators are drawn on top of the cells so a
 * highlighted cell never hides them.
 */
@Composable
fun SudokuGrid(
    cells: List<CellUi>,
    hidden: Boolean,
    onCellClick: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalBoardColors.current

    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(1f)
            .testTag("sudoku_grid")
    ) {
        val side = minOf(maxWidth, maxHeight)
        val cellSize = side / SudokuBoard.SIZE
        val digitSize = (cellSize.value * 0.52f).sp
        val noteSize = (cellSize.value * 0.22f).sp

        Column(
            modifier = Modifier
                .size(side)
                .align(Alignment.Center)
                .background(colors.cellBackground)
        ) {
            for (row in 0 until SudokuBoard.SIZE) {
                Row(modifier = Modifier.fillMaxWidth()) {
                    for (col in 0 until SudokuBoard.SIZE) {
                        val index = SudokuBoard.indexOf(row, col)
                        val cell = cells.getOrNull(index)
                        GridCell(
                            cell = cell,
                            row = row,
                            col = col,
                            hidden = hidden,
                            cellSize = cellSize,
                            digitSize = digitSize,
                            noteSize = noteSize,
                            onClick = { onCellClick(index) }
                        )
                    }
                }
            }
        }

        // Grid lines on top: thin between cells, thick between blocks, thick around the edge.
        Box(
            modifier = Modifier
                .size(side)
                .align(Alignment.Center)
                .drawBehind {
                    val step = size.width / SudokuBoard.SIZE
                    for (i in 0..SudokuBoard.SIZE) {
                        val thick = i % SudokuBoard.BOX == 0
                        val width = if (thick) 2.5f * density else 0.8f * density
                        val color = if (thick) colors.blockLine else colors.gridLine
                        val pos = (i * step).coerceAtMost(size.width - width / 2)
                        drawLine(color, Offset(pos, 0f), Offset(pos, size.height), width)
                        drawLine(color, Offset(0f, pos), Offset(size.width, pos), width)
                    }
                }
        )
    }
}

@Composable
private fun GridCell(
    cell: CellUi?,
    row: Int,
    col: Int,
    hidden: Boolean,
    cellSize: Dp,
    digitSize: TextUnit,
    noteSize: TextUnit,
    onClick: () -> Unit
) {
    val colors = LocalBoardColors.current
    val background = when {
        cell == null -> colors.cellBackground
        cell.conflict -> colors.conflictCell
        cell.selected -> colors.selectedCell
        cell.sameValue -> colors.sameValueCell
        cell.related -> colors.relatedCell
        else -> colors.cellBackground
    }
    val description = when {
        cell == null || cell.value == 0 -> stringResource(R.string.cd_cell_empty, row + 1, col + 1)
        cell.given -> stringResource(R.string.cd_cell_given, row + 1, col + 1, cell.value)
        else -> stringResource(R.string.cd_cell_value, row + 1, col + 1, cell.value)
    }

    Box(
        modifier = Modifier
            .size(cellSize)
            .background(background)
            .clickable(onClick = onClick)
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center
    ) {
        if (hidden || cell == null) return@Box
        when {
            cell.value != 0 -> Text(
                text = cell.value.toString(),
                fontSize = digitSize,
                // Conflicts are marked by weight as well as colour, never by colour alone.
                fontWeight = if (cell.given || cell.conflict) FontWeight.Bold else FontWeight.Normal,
                color = when {
                    cell.conflict -> colors.conflictText
                    cell.given -> colors.givenText
                    else -> colors.entryText
                }
            )
            cell.notes != 0 -> NoteGrid(mask = cell.notes, fontSize = noteSize, color = colors.noteText)
        }
    }
}

/** The nine pencil marks, each in its fixed position so a digit never moves. */
@Composable
private fun NoteGrid(mask: Int, fontSize: TextUnit, color: Color) {
    Column(modifier = Modifier.fillMaxSize()) {
        for (band in 0 until 3) {
            Row(modifier = Modifier.fillMaxWidth().weight(1f)) {
                for (slot in 0 until 3) {
                    val digit = band * 3 + slot + 1
                    Box(modifier = Modifier.weight(1f).fillMaxSize(), contentAlignment = Alignment.Center) {
                        if (SudokuBoard.hasNote(mask, digit)) {
                            Text(
                                text = digit.toString(),
                                fontSize = fontSize,
                                color = color,
                                textAlign = TextAlign.Center,
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = fontSize)
                            )
                        }
                    }
                }
            }
        }
    }
}
