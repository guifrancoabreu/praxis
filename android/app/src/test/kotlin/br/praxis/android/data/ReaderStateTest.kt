package br.praxis.android.data

import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The stored shapes are shared with the iOS app, so they are pinned here. */
class ReaderStateTest {
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    @Test
    fun `reading progress keeps the iOS JSON keys`() {
        val progress = ReadingProgress(
            path = "https://www.marxists.org/portugues/marx/1845/tesfeuer.htm",
            title = "Teses sobre Feuerbach",
            author = "Karl Marx",
            progress = 0.42,
            workId = "https://www.marxists.org/portugues/marx/1845/index.htm",
        )
        val encoded = json.encodeToString(ListSerializer, listOf(progress))
        assertTrue("workID must keep its iOS spelling", encoded.contains("\"workID\""))

        val decoded = json.decodeFromString(ListSerializer, encoded).single()
        assertEquals(progress, decoded)
    }

    @Test
    fun `reading progress tolerates entries from an older build`() {
        val legacy = """[{"path":"https://www.marxists.org/portugues/x.htm"}]"""
        val decoded = json.decodeFromString(ListSerializer, legacy).single()
        assertEquals("", decoded.title)
        assertEquals(0.0, decoded.progress, 0.0)
        assertNull(decoded.workId)
    }

    @Test
    fun `appearance round trips and carries the six themes`() {
        val appearance = ReaderAppearance().withTheme("sepia")
        assertEquals("#f4ecd8", appearance.background)
        assertEquals("#3b2f22", appearance.foreground)
        assertEquals("#9c2a12", appearance.link)

        val decoded = ReaderAppearance.decode(appearance.encoded())
        assertEquals(appearance, decoded)
        assertEquals(6, ReaderAppearance.themes.size)
        ReaderAppearance.themes.forEach { (name, palette) ->
            assertEquals(3, palette.size)
            palette.forEach { assertTrue("$name colour must be a hex value", it.matches(Regex("#[0-9a-f]{6}"))) }
        }
    }

    @Test
    fun `a broken appearance falls back to the defaults`() {
        assertEquals(ReaderAppearance(), ReaderAppearance.decode("{not json"))
        assertEquals(ReaderAppearance(), ReaderAppearance.decode(""))
    }

    @Test
    fun `custom colours keep the palette off the built-in list`() {
        val custom = ReaderAppearance().withColors(background = "#101010", foreground = "#f0f0f0", link = "#ff0000")
        assertEquals("custom", custom.theme)
        assertEquals("#101010", custom.background)
        val ratio = ReaderAppearance.contrastRatio(custom.foreground, custom.background)!!
        assertTrue("custom colours must report a usable ratio", ratio > 10)
    }

    @Test
    fun `works of the same directory group into one reading entry`() {
        val chapter = ReadingProgress(
            path = "https://www.marxists.org/portugues/marx/1848/manifesto/cap1.htm",
            title = "Manifesto do Partido Comunista",
            author = "Karl Marx",
            progress = 0.8,
            workId = "https://www.marxists.org/portugues/marx/1848/manifesto/index.htm",
        )
        val anotherChapter = chapter.copy(path = "https://www.marxists.org/portugues/marx/1848/manifesto/cap2.htm", progress = 0.3)
        val otherWork = chapter.copy(
            path = "https://www.marxists.org/portugues/marx/1867/capital/index.htm",
            title = "O Capital",
            progress = 0.1,
            workId = "https://www.marxists.org/portugues/marx/1867/capital/index.htm",
        )

        val grouped = ReadingHistory.grouped(listOf(chapter, anotherChapter, otherWork), emptySet())
        assertEquals(2, grouped.size)
        assertEquals(0.8, grouped.first().progress, 0.0)
    }

    @Test
    fun `canonical keys normalise the archive host and drop fragments`() {
        val base = "https://www.marxists.org/portugues/"
        assertEquals(
            "https://www.marxists.org/portugues/marx/1845/tesfeuer.htm",
            ReadingHistory.canonicalKey("http://marxists.org/portugues/marx/1845/tesfeuer.htm#nota", base),
        )
    }

    private companion object {
        val ListSerializer = kotlinx.serialization.builtins.ListSerializer(ReadingProgress.serializer())
    }
}
