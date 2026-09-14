package com.huaweiappfactory.hashtags.domain

import org.json.JSONObject
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * The shipped tag sets are the product, so they are tested like code.
 *
 * These read the asset straight off disk rather than through Android, so a bad
 * set fails the build instead of reaching a user. The banned lists are the ones
 * the spec calls out: platform names (a legal risk and a look of being an
 * unofficial add-on) and engagement-farming families, which mark a post as spam
 * and can get it suppressed -- shipping those would make the app harmful to the
 * person using it.
 */
class HashtagAssetTest {

    private val asset = File("src/main/assets/hashtag_sets.json")

    private val bannedSubstrings = listOf(
        "insta", "gram", "tiktok", "twitter", "youtube", "facebook", "whatsapp",
        "pinterest", "followforfollow", "follow4follow", "followme", "likeforlike",
        "like4like", "sub4sub", "spam",
    )
    private val bannedExact = setOf("shorts", "reels", "snap", "fb", "ig", "yt", "f4f", "l4l", "c4c")

    private fun sets(): List<Pair<String, List<String>>> {
        assertTrue("asset missing at ${asset.absolutePath}", asset.exists())
        val root = JSONObject(asset.readText())
        val array = root.getJSONArray("sets")
        return (0 until array.length()).map { i ->
            val obj = array.getJSONObject(i)
            val tags = obj.getJSONArray("tags")
            obj.getString("id") to (0 until tags.length()).map { tags.getString(it) }
        }
    }

    @Test
    fun `there are at least twenty topics`() {
        assertTrue("only ${sets().size} topics", sets().size >= 20)
    }

    @Test
    fun `every topic carries between 25 and 40 tags`() {
        for ((id, tags) in sets()) {
            assertTrue("$id has ${tags.size} tags", tags.size in 25..40)
        }
    }

    @Test
    fun `every tag is lower-case, hash-prefixed and unbroken`() {
        for ((id, tags) in sets()) {
            for (tag in tags) {
                assertTrue("$id: $tag is not canonical", Tags.isValid(tag))
            }
        }
    }

    @Test
    fun `no tag repeats inside its set`() {
        for ((id, tags) in sets()) {
            assertTrue("$id repeats a tag", tags.size == tags.toSet().size)
        }
    }

    @Test
    fun `no tag names a platform or a company`() {
        for ((id, tags) in sets()) {
            for (tag in tags) {
                val body = tag.removePrefix("#")
                for (banned in bannedSubstrings) {
                    assertTrue("$id: $tag contains '$banned'", !body.contains(banned))
                }
                assertTrue("$id: $tag is a platform name", body !in bannedExact)
            }
        }
    }

    @Test
    fun `the topic itself is the first tag of its set`() {
        // The broad tag is the one people actually search; it must not be missing
        // because a set drifted while being edited.
        for ((id, tags) in sets()) {
            assertTrue("$id does not lead with #$id (leads with ${tags.first()})",
                tags.first() == "#$id")
        }
    }
}
