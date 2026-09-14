package com.huaweiappfactory.hashtags.ui

import androidx.annotation.StringRes
import com.huaweiappfactory.hashtags.R
import com.huaweiappfactory.hashtags.data.repository.HashtagRepository
import com.huaweiappfactory.hashtags.domain.HashtagSet

/**
 * The one place a set turns into a shown name.
 *
 * Built-in topics are translated; custom sets carry the user's own words and must
 * never be translated. An unknown built-in id falls back to its raw id rather than
 * showing nothing, so adding a topic to the asset without a string resource is
 * visible in testing instead of silent.
 */
@StringRes
private fun topicLabel(id: String): Int? = when (id) {
    "travel" -> R.string.topic_travel
    "food" -> R.string.topic_food
    "fitness" -> R.string.topic_fitness
    "photography" -> R.string.topic_photography
    "art" -> R.string.topic_art
    "business" -> R.string.topic_business
    "music" -> R.string.topic_music
    "nature" -> R.string.topic_nature
    "fashion" -> R.string.topic_fashion
    "pets" -> R.string.topic_pets
    "home" -> R.string.topic_home
    "cars" -> R.string.topic_cars
    "books" -> R.string.topic_books
    "gaming" -> R.string.topic_gaming
    "beauty" -> R.string.topic_beauty
    "wedding" -> R.string.topic_wedding
    "sport" -> R.string.topic_sport
    "coffee" -> R.string.topic_coffee
    "sunset" -> R.string.topic_sunset
    "motivation" -> R.string.topic_motivation
    else -> null
}

@StringRes
fun setLabelRes(set: HashtagSet): Int? = when (set.kind) {
    HashtagSet.Kind.FAVOURITES -> R.string.topics_favourites
    HashtagSet.Kind.RECENT -> R.string.topics_recent
    HashtagSet.Kind.BUILT_IN -> topicLabel(set.id)
    HashtagSet.Kind.CUSTOM -> null
}

/** The literal name when there is no string resource: a custom set, or a topic with no translation. */
fun setLiteralName(set: HashtagSet): String = set.customName ?: set.id

fun isFavourites(set: HashtagSet): Boolean = set.id == HashtagRepository.FAVOURITES_ID
