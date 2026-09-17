package com.huaweiappfactory.translate.domain

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LanguagesTest {

    @Test
    fun `names are shown in the reader's own language`() {
        assertEquals("Alemán", Languages.displayName("de", Locale("es")))
        assertEquals("German", Languages.displayName("de", Locale.ENGLISH))
    }

    @Test
    fun `an unknown code falls back to the code rather than dressing it up`() {
        // getDisplayLanguage echoes the input back when it has no name; showing
        // "QQQ" is honest, showing "qqq" as if it were a language name is not.
        assertEquals("QQQ", Languages.displayName("qqq", Locale.ENGLISH))
    }

    @Test
    fun `the list is sorted by the name the reader sees, not by code`() {
        val names = Languages.describe(listOf("de", "es", "fr"), Locale.ENGLISH).map { it.displayName }
        assertEquals(listOf("French", "German", "Spanish"), names)
    }

    @Test
    fun `sorting follows the reader's locale`() {
        // In Spanish the same three codes come out in a different order, which
        // is the whole point of sorting after translating.
        val names = Languages.describe(listOf("de", "es", "fr"), Locale("es")).map { it.displayName }
        assertEquals(listOf("Alemán", "Español", "Francés"), names)
    }

    @Test
    fun `a pair needs two different, non-empty languages`() {
        assertTrue(Languages.isTranslatable("en", "es"))
        assertFalse(Languages.isTranslatable("en", "en"))
        assertFalse(Languages.isTranslatable("", "es"))
        assertFalse(Languages.isTranslatable("en", ""))
    }
}
