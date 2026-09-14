package com.huaweiappfactory.sudoku.domain

/** One finished game, in the order it was played. */
data class GameOutcome(
    val difficulty: Difficulty,
    val won: Boolean,
    val elapsedSeconds: Int,
    val finishedAtMillis: Long
)

data class DifficultyStats(
    val difficulty: Difficulty,
    val played: Int,
    val won: Int,
    val bestSeconds: Int?,
    val averageSeconds: Int?
) {
    /** 0..100, rounded. Zero when nothing has been played. */
    val winRatePercent: Int get() = if (played == 0) 0 else Math.round(won * 100f / played)
}

data class OverallStats(
    val perDifficulty: List<DifficultyStats>,
    val currentStreak: Int,
    val longestStreak: Int
) {
    val totalPlayed: Int get() = perDifficulty.sumOf { it.played }
    val totalWon: Int get() = perDifficulty.sumOf { it.won }
    val hasData: Boolean get() = totalPlayed > 0
}

/**
 * Turns the list of finished games into the numbers the Statistics screen shows.
 * Best and average times count wins only — an abandoned game says nothing about speed.
 * A streak is consecutive wins in finishing order, across every difficulty.
 */
object StatsCalculator {

    fun compute(outcomes: List<GameOutcome>): OverallStats {
        val ordered = outcomes.sortedBy { it.finishedAtMillis }

        val perDifficulty = Difficulty.entries.map { difficulty ->
            val games = ordered.filter { it.difficulty == difficulty }
            val winTimes = games.filter { it.won }.map { it.elapsedSeconds }
            DifficultyStats(
                difficulty = difficulty,
                played = games.size,
                won = winTimes.size,
                bestSeconds = winTimes.minOrNull(),
                averageSeconds = if (winTimes.isEmpty()) null else Math.round(winTimes.average()).toInt()
            )
        }

        var current = 0
        var longest = 0
        for (outcome in ordered) {
            if (outcome.won) {
                current++
                if (current > longest) longest = current
            } else {
                current = 0
            }
        }

        return OverallStats(perDifficulty, current, longest)
    }

    /** True when [seconds] beats every previous win at [difficulty]. */
    fun isPersonalBest(previous: List<GameOutcome>, difficulty: Difficulty, seconds: Int): Boolean {
        val best = previous.filter { it.won && it.difficulty == difficulty }.minOfOrNull { it.elapsedSeconds }
        return best == null || seconds < best
    }

    /** mm:ss, or h:mm:ss past an hour. Locale-independent on purpose. */
    fun formatDuration(seconds: Int): String {
        val safe = seconds.coerceAtLeast(0)
        val hours = safe / 3600
        val minutes = (safe % 3600) / 60
        val secs = safe % 60
        return if (hours > 0) {
            "%d:%02d:%02d".format(hours, minutes, secs)
        } else {
            "%02d:%02d".format(minutes, secs)
        }
    }
}
