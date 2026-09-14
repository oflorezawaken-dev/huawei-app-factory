package com.huaweiappfactory.sudoku.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class StatsCalculatorTest {

    private fun outcome(
        difficulty: Difficulty,
        won: Boolean,
        seconds: Int,
        at: Long
    ) = GameOutcome(difficulty, won, seconds, at)

    @Test
    fun `an empty history has no data`() {
        val stats = StatsCalculator.compute(emptyList())
        assertFalse(stats.hasData)
        assertEquals(0, stats.currentStreak)
        assertEquals(0, stats.longestStreak)
        stats.perDifficulty.forEach {
            assertEquals(0, it.played)
            assertNull(it.bestSeconds)
            assertNull(it.averageSeconds)
            assertEquals(0, it.winRatePercent)
        }
    }

    @Test
    fun `best and average count wins only`() {
        val stats = StatsCalculator.compute(
            listOf(
                outcome(Difficulty.EASY, won = true, seconds = 300, at = 1),
                outcome(Difficulty.EASY, won = true, seconds = 200, at = 2),
                outcome(Difficulty.EASY, won = false, seconds = 10, at = 3)
            )
        )
        val easy = stats.perDifficulty.first { it.difficulty == Difficulty.EASY }
        assertEquals(3, easy.played)
        assertEquals(2, easy.won)
        assertEquals(200, easy.bestSeconds)
        assertEquals(250, easy.averageSeconds)
        assertEquals(67, easy.winRatePercent)
    }

    @Test
    fun `difficulties are counted separately`() {
        val stats = StatsCalculator.compute(
            listOf(
                outcome(Difficulty.EASY, won = true, seconds = 100, at = 1),
                outcome(Difficulty.EXPERT, won = true, seconds = 900, at = 2)
            )
        )
        assertEquals(100, stats.perDifficulty.first { it.difficulty == Difficulty.EASY }.bestSeconds)
        assertEquals(900, stats.perDifficulty.first { it.difficulty == Difficulty.EXPERT }.bestSeconds)
        assertNull(stats.perDifficulty.first { it.difficulty == Difficulty.MEDIUM }.bestSeconds)
        assertEquals(2, stats.totalPlayed)
        assertEquals(2, stats.totalWon)
    }

    @Test
    fun `a streak is consecutive wins in finishing order across difficulties`() {
        val stats = StatsCalculator.compute(
            listOf(
                outcome(Difficulty.EASY, won = true, seconds = 100, at = 1),
                outcome(Difficulty.MEDIUM, won = true, seconds = 200, at = 2),
                outcome(Difficulty.HARD, won = true, seconds = 300, at = 3),
                outcome(Difficulty.EASY, won = false, seconds = 50, at = 4),
                outcome(Difficulty.EASY, won = true, seconds = 120, at = 5)
            )
        )
        assertEquals(1, stats.currentStreak)
        assertEquals(3, stats.longestStreak)
    }

    @Test
    fun `the order the games are passed in does not matter`() {
        val games = listOf(
            outcome(Difficulty.EASY, won = true, seconds = 100, at = 5),
            outcome(Difficulty.EASY, won = false, seconds = 50, at = 4),
            outcome(Difficulty.EASY, won = true, seconds = 300, at = 3),
            outcome(Difficulty.EASY, won = true, seconds = 200, at = 2)
        )
        val stats = StatsCalculator.compute(games)
        assertEquals(1, stats.currentStreak)
        assertEquals(2, stats.longestStreak)
    }

    @Test
    fun `a loss ends the current streak`() {
        val stats = StatsCalculator.compute(
            listOf(
                outcome(Difficulty.EASY, won = true, seconds = 100, at = 1),
                outcome(Difficulty.EASY, won = false, seconds = 60, at = 2)
            )
        )
        assertEquals(0, stats.currentStreak)
        assertEquals(1, stats.longestStreak)
    }

    @Test
    fun `a personal best needs a faster win at the same difficulty`() {
        val history = listOf(
            outcome(Difficulty.MEDIUM, won = true, seconds = 240, at = 1),
            outcome(Difficulty.MEDIUM, won = false, seconds = 10, at = 2),
            outcome(Difficulty.HARD, won = true, seconds = 120, at = 3)
        )
        assertTrue(StatsCalculator.isPersonalBest(history, Difficulty.MEDIUM, 239))
        assertFalse(StatsCalculator.isPersonalBest(history, Difficulty.MEDIUM, 240))
        assertFalse(StatsCalculator.isPersonalBest(history, Difficulty.HARD, 200))
        // Nothing to beat yet at this difficulty.
        assertTrue(StatsCalculator.isPersonalBest(history, Difficulty.EXPERT, 3600))
    }

    @Test
    fun `durations format as mm ss and grow an hour field`() {
        assertEquals("00:00", StatsCalculator.formatDuration(0))
        assertEquals("00:09", StatsCalculator.formatDuration(9))
        assertEquals("01:05", StatsCalculator.formatDuration(65))
        assertEquals("59:59", StatsCalculator.formatDuration(3599))
        assertEquals("1:00:00", StatsCalculator.formatDuration(3600))
        assertEquals("2:03:04", StatsCalculator.formatDuration(7384))
        assertEquals("00:00", StatsCalculator.formatDuration(-5))
    }
}
