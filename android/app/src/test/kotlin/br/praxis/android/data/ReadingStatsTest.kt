package br.praxis.android.data

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.LocalDate

/** Pins the date math the stats screen depends on. Mirrors the iOS ReadingStatsTests. */
class ReadingStatsTest {

    private fun day(offset: Long): String = LocalDate.parse("2026-11-16").plusDays(offset).toString()

    @Test
    fun `mergeReadingDays dedupes and sorts newest first`() {
        val merged = ReadingStats.mergeReadingDays(listOf("2026-11-10", "2026-11-16"), "2026-11-15")
        assertEquals(listOf("2026-11-16", "2026-11-15", "2026-11-10"), merged)
    }

    @Test
    fun `mergeReadingDays retains more than 400 days`() {
        val many = (1L..401L).map { day(-it) }
        val merged = ReadingStats.mergeReadingDays(many, "2026-11-16")
        assertEquals(402, merged.size)
        assertEquals("2026-11-16", merged.first())
    }

    @Test
    fun `currentStreak counts consecutive days including today`() {
        val days = setOf("2026-11-16", "2026-11-15", "2026-11-14")
        assertEquals(3, ReadingStats.currentStreak(days, "2026-11-16"))
    }

    @Test
    fun `currentStreak survives a not yet read today`() {
        val days = setOf("2026-11-15", "2026-11-14")
        assertEquals(2, ReadingStats.currentStreak(days, "2026-11-16"))
    }

    @Test
    fun `currentStreak breaks on a gap`() {
        val days = setOf("2026-11-16", "2026-11-14")
        assertEquals(1, ReadingStats.currentStreak(days, "2026-11-16"))
    }

    @Test
    fun `currentStreak is zero with no days`() {
        assertEquals(0, ReadingStats.currentStreak(emptySet(), "2026-11-16"))
    }

    @Test
    fun `weekBucketCounts returns twelve buckets oldest first`() {
        val days = setOf("2026-11-16", "2026-11-12", "2026-08-26")
        val buckets = ReadingStats.weekBucketCounts(days, "2026-11-16")
        assertEquals(12, buckets.size)
        assertEquals(1, buckets.first()) // 2026-08-26 falls in the oldest rolling week
        assertEquals(2, buckets.last()) // both 2026-11-12 and 2026-11-16 in the newest week
    }

    @Test
    fun `weekBucketCounts never exceeds seven days`() {
        val newestWeek = (0L..6L).map { day(-it) }.toSet()
        val buckets = ReadingStats.weekBucketCounts(newestWeek, "2026-11-16")
        assertEquals(7, buckets.last())
    }
}
