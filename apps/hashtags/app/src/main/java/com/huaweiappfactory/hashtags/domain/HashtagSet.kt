package com.huaweiappfactory.hashtags.domain

/**
 * A group of tags the user can open, trim and copy.
 *
 * Built-in sets come from the shipped asset and are read-only; custom sets are
 * the user's own. [Favourites] and [Recent] are built on the fly from other
 * tables but behave like any other set on screen, which is why they are the same
 * type rather than a special case in the UI.
 */
data class HashtagSet(
    val id: String,
    val tags: List<String>,
    val kind: Kind,
    /** Only custom sets carry a user-written name; built-ins are named by translation. */
    val customName: String? = null,
    val rowId: Long = 0
) {
    enum class Kind { BUILT_IN, CUSTOM, FAVOURITES, RECENT }

    val size: Int get() = tags.size
    val isEditable: Boolean get() = kind == Kind.CUSTOM
}

/** One entry in the copy history, restorable back into a selection. */
data class CopyRecord(
    val id: Long,
    val tags: List<String>,
    val sourceName: String,
    val copiedAt: Long
)

/**
 * Reads the shipped asset. Kept as an interface so tests can supply sets without
 * an Android context, and so a bad asset fails in one identifiable place.
 */
interface BuiltInSets {
    fun all(): List<HashtagSet>
}

object SetSearch {

    /**
     * Sets whose name or any tag matches [query]. [displayName] resolves a set's
     * shown name, which for built-ins is a translated string the domain cannot see.
     */
    fun filterSets(
        sets: List<HashtagSet>,
        query: String,
        displayName: (HashtagSet) -> String
    ): List<HashtagSet> {
        if (query.isBlank()) return sets
        return sets.filter { set ->
            Tags.matches(displayName(set), query) || set.tags.any { Tags.matches(it, query) }
        }
    }

    /** Every distinct tag across [sets] that matches [query], in first-seen order. */
    fun filterTags(sets: List<HashtagSet>, query: String): List<String> {
        if (query.isBlank()) return emptyList()
        val seen = LinkedHashSet<String>()
        for (set in sets) {
            for (tag in set.tags) {
                if (Tags.matches(tag, query)) seen += tag
            }
        }
        return seen.toList()
    }
}
