package br.praxis.android.data

import java.time.LocalDate
import java.time.temporal.ChronoUnit

/**
 * Reading statistics derived from the days the reader opened a text, ported from ReadingStats on
 * iOS. Pure Kotlin, so the streak and the weekly activity can be tested without Android.
 */
object ReadingStats {
    /** Local ISO day, the shape stored in `readingDays`. */
    fun today(): String = LocalDate.now().toString()

    /** Union of the stored days and today, newest first, bounded to 400 entries. */
    fun mergeReadingDays(existing: List<String>, today: String): List<String> =
        (existing + today).distinct().sortedDescending().take(400)

    /**
     * Consecutive days ending today. A day not read yet counts as still alive, so the walk starts
     * yesterday when today is missing; two missed days end the streak.
     */
    fun currentStreak(days: Set<String>, today: String): Int {
        val parsed = runCatching { LocalDate.parse(today) }.getOrNull() ?: return 0
        var cursor = if (today in days) parsed else parsed.minusDays(1)
        var streak = 0
        while (cursor.toString() in days) {
            streak++
            cursor = cursor.minusDays(1)
        }
        return streak
    }

    /**
     * Distinct reading days in each of the last [weeks] rolling weeks, oldest first. Bucket `i`
     * ends at `today - (weeks - 1 - i) * 7` and covers the six days before it, so every count is
     * between 0 and 7.
     */
    fun weekBucketCounts(days: Set<String>, today: String, weeks: Int = 12): List<Int> {
        val parsed = runCatching { LocalDate.parse(today) }.getOrNull() ?: return List(weeks) { 0 }
        val dated = days.mapNotNull { day -> runCatching { LocalDate.parse(day) }.getOrNull() }
        return (0 until weeks).map { index ->
            val end = parsed.minusDays(((weeks - 1 - index) * 7).toLong())
            val start = end.minusDays(6)
            dated.count { day ->
                val offset = ChronoUnit.DAYS.between(start, day)
                offset in 0..6
            }
        }
    }
}
