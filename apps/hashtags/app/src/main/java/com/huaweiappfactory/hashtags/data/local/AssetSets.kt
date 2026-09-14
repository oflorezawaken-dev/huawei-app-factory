package com.huaweiappfactory.hashtags.data.local

import android.content.Context
import android.util.Log
import com.huaweiappfactory.hashtags.domain.BuiltInSets
import com.huaweiappfactory.hashtags.domain.HashtagSet
import org.json.JSONObject

/**
 * Reads the shipped tag sets once and keeps them in memory.
 *
 * The asset is small enough that this is not a loading state, and its shape is
 * guarded by unit tests, so a failure here means the APK itself is broken. Even
 * then the app degrades to an empty topic list rather than crashing on launch:
 * a hashtag tool with no tags is useless, but a crash loop is worse.
 */
class AssetSets(private val context: Context) : BuiltInSets {

    private val loaded: List<HashtagSet> by lazy { read() }

    override fun all(): List<HashtagSet> = loaded

    private fun read(): List<HashtagSet> = try {
        val text = context.assets.open(FILE).bufferedReader().use { it.readText() }
        val array = JSONObject(text).getJSONArray("sets")
        (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            val tags = obj.getJSONArray("tags")
            HashtagSet(
                id = obj.getString("id"),
                tags = (0 until tags.length()).map { tags.getString(it) },
                kind = HashtagSet.Kind.BUILT_IN
            )
        }
    } catch (t: Throwable) {
        Log.e(TAG, "the shipped tag asset could not be read; the topic list will be empty", t)
        emptyList()
    }

    private companion object {
        const val TAG = "AssetSets"
        const val FILE = "hashtag_sets.json"
    }
}
