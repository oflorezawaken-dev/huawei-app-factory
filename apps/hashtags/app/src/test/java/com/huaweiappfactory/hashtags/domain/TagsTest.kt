package com.huaweiappfactory.hashtags.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TagsTest {

    @Test
    fun `typed text becomes a canonical tag`() {
        assertEquals("#goldenhour", Tags.normalise("Golden Hour!"))
        assertEquals("#travel", Tags.normalise("  #Travel  "))
        assertEquals("#travel", Tags.normalise("travel"))
        assertEquals("#b2b", Tags.normalise("B2B"))
    }

    @Test
    fun `text with nothing usable in it is rejected`() {
        assertNull(Tags.normalise(""))
        assertNull(Tags.normalise("   "))
        assertNull(Tags.normalise("#"))
        assertNull(Tags.normalise("!!!"))
    }

    @Test
    fun `a duplicate is refused however it was typed`() {
        val existing = listOf("#travel", "#food")
        assertNull(Tags.addTo(existing, "travel"))
        assertNull(Tags.addTo(existing, "#TRAVEL"))
        assertNull(Tags.addTo(existing, " Travel "))
        assertEquals(listOf("#travel", "#food", "#coffee"), Tags.addTo(existing, "coffee"))
    }

    @Test
    fun `the clipboard string is what you would paste`() {
        assertEquals("#travel #food", Tags.toClipboard(listOf("#travel", "#food")))
        assertEquals("", Tags.toClipboard(emptyList()))
    }

    @Test
    fun `the limit flags at thirty one, not thirty`() {
        assertFalse(Tags.isOverLimit(29))
        assertFalse(Tags.isOverLimit(30))
        assertTrue(Tags.isOverLimit(31))
    }

    @Test
    fun `search ignores the hash on either side`() {
        assertTrue(Tags.matches("#goldenhour", "golden"))
        assertTrue(Tags.matches("#goldenhour", "#golden"))
        assertTrue(Tags.matches("goldenhour", "GOLDEN"))
        assertFalse(Tags.matches("#travel", "food"))
    }

    @Test
    fun `an empty query matches everything`() {
        assertTrue(Tags.matches("#travel", ""))
        assertTrue(Tags.matches("#travel", "   "))
    }

    @Test
    fun `tags survive a storage round trip`() {
        val tags = listOf("#travel", "#food", "#b2b")
        assertEquals(tags, Tags.deserialise(Tags.serialise(tags)))
        assertEquals(emptyList<String>(), Tags.deserialise(null))
        assertEquals(emptyList<String>(), Tags.deserialise("   "))
    }

    @Test
    fun `validity is exactly what normalise produces`() {
        assertTrue(Tags.isValid("#travel"))
        assertTrue(Tags.isValid("#b2b"))
        assertFalse(Tags.isValid("travel"))
        assertFalse(Tags.isValid("#Travel"))
        assertFalse(Tags.isValid("#two words"))
        assertFalse(Tags.isValid("#"))
    }
}
