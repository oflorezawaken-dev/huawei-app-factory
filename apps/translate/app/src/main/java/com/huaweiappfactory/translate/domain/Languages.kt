package com.huaweiappfactory.translate.domain

import java.util.Locale

/**
 * A language the on-device engine knows about.
 *
 * The list is never hard-coded: it comes from the SDK at runtime, which
 * reported 55 codes on the test device. Writing that number into the app or the
 * store listing would make it a lie the first time Huawei ships a model.
 */
data class Language(val code: String, val displayName: String) {
    override fun toString(): String = displayName
}

object Languages {

    /**
     * Turns the SDK's codes into something a person recognises, in their own
     * language: a Spanish user sees "alemán", not "de" and not "German".
     */
    fun describe(codes: Collection<String>, inLocale: Locale = Locale.getDefault()): List<Language> {
        val named = codes.map { code -> code to displayName(code, inLocale) }
        // Several codes share a name: the engine offers zh and zh-Hant, and both
        // are "Chinese". Two identical rows look like a bug and give the user no
        // way to choose, so a colliding name carries its code.
        val collisions = named.groupingBy { it.second }.eachCount().filterValues { it > 1 }.keys
        return named
            .map { (code, name) ->
                Language(code, if (name in collisions) "$name ($code)" else name)
            }
            .sortedBy { it.displayName.lowercase(inLocale) }
    }

    fun displayName(code: String, inLocale: Locale = Locale.getDefault()): String {
        val name = Locale.forLanguageTag(code).getDisplayLanguage(inLocale)
        // getDisplayLanguage echoes the code back when it has no name for it;
        // showing "zu" is still better than showing nothing, but it must not be
        // dressed up as a translated name.
        return if (name.isBlank() || name.equals(code, ignoreCase = true)) {
            code.uppercase(inLocale)
        } else {
            name.replaceFirstChar { it.titlecase(inLocale) }
        }
    }

    /** A pair is only usable when both sides are downloaded and they differ. */
    fun isTranslatable(source: String, target: String): Boolean =
        source.isNotBlank() && target.isNotBlank() && source != target
}
