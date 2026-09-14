package com.huaweiappfactory.hashtags.domain

/**
 * Tag rules, kept away from Android so every one of them is unit-testable.
 *
 * A "tag" is always stored and compared with its leading `#`, lower-case, with no
 * whitespace. Everything a user types goes through [normalise] first, so the rest
 * of the app never has to wonder whether it is looking at `Travel`, `#travel` or
 * ` #Travel `.
 */
object Tags {

    /** The ceiling most platforms put on one post. Shown as guidance, never enforced. */
    const val RECOMMENDED_MAX = 30

    private val ALLOWED = Regex("[a-z0-9]+")

    /**
     * Turns what someone typed into a tag, or null when nothing usable is left.
     * Strips `#` and whitespace, lower-cases, and drops anything that is not a
     * letter or digit -- so "Golden Hour!" becomes "#goldenhour".
     */
    fun normalise(raw: String): String? {
        val cleaned = raw.trim().removePrefix("#").lowercase()
            .filter { it.isLetterOrDigit() }
        if (cleaned.isEmpty()) return null
        return "#$cleaned"
    }

    /** True for a tag already in canonical form. */
    fun isValid(tag: String): Boolean =
        tag.startsWith("#") && ALLOWED.matches(tag.removePrefix("#"))

    /**
     * Adds [raw] to [existing] if it is usable and not already there.
     * Returns the new list, or null when nothing changed, so a caller can tell
     * "added" from "duplicate" without comparing lists.
     */
    fun addTo(existing: List<String>, raw: String): List<String>? {
        val tag = normalise(raw) ?: return null
        if (existing.any { it.equals(tag, ignoreCase = true) }) return null
        return existing + tag
    }

    /** What goes on the clipboard: selection order, space separated, ready to paste. */
    fun toClipboard(tags: List<String>): String = tags.joinToString(" ")

    /** True once the selection is past the point most platforms stop accepting tags. */
    fun isOverLimit(count: Int): Boolean = count > RECOMMENDED_MAX

    /**
     * Matches a tag or a set name against a search query. The `#` is optional on
     * both sides, because nobody types it when searching.
     */
    fun matches(haystack: String, query: String): Boolean {
        val needle = query.trim().removePrefix("#").lowercase()
        if (needle.isEmpty()) return true
        return haystack.removePrefix("#").lowercase().contains(needle)
    }

    /** Storage format for a set's tags: one string, space separated. */
    fun serialise(tags: List<String>): String = tags.joinToString(" ")

    fun deserialise(text: String?): List<String> =
        text?.split(" ")?.filter { it.isNotBlank() } ?: emptyList()
}
