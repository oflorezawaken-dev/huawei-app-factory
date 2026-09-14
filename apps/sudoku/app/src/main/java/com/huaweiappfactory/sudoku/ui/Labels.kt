package com.huaweiappfactory.sudoku.ui

import androidx.annotation.StringRes
import com.huaweiappfactory.sudoku.R
import com.huaweiappfactory.sudoku.domain.Difficulty

/** The one place a difficulty becomes a translated word. */
@StringRes
fun difficultyLabel(difficulty: Difficulty): Int = when (difficulty) {
    Difficulty.EASY -> R.string.difficulty_easy
    Difficulty.MEDIUM -> R.string.difficulty_medium
    Difficulty.HARD -> R.string.difficulty_hard
    Difficulty.EXPERT -> R.string.difficulty_expert
}
