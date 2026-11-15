package br.praxis.android.data

import java.text.Collator
import java.util.Locale

/**
 * Search and sorting that match the iOS helpers.
 *
 * `localizedStandardContains`/`localizedStandardCompare` are case-, accent- and width-insensitive
 * and compare numbers by value, so a plain `contains` would change results for Portuguese titles.
 * [Collator] with PRIMARY strength covers case and accents; [compareNumeric] handles numbers.
 */
object TextSearch {
    private val collator: Collator = Collator.getInstance(Locale("pt", "BR")).apply {
        strength = Collator.PRIMARY
        decomposition = Collator.CANONICAL_DECOMPOSITION
    }

    fun contains(haystack: String, needle: String): Boolean {
        val query = needle.trim()
        if (query.isEmpty()) return true
        if (haystack.contains(query, ignoreCase = true)) return true
        return normalize(haystack).contains(normalize(query))
    }

    fun compare(left: String, right: String): Int {
        val primary = collator.compare(left, right)
        return if (primary != 0) primary else left.compareTo(right)
    }

    /** Compares the first 3-4 digit number in each text, the way CatalogSort.date does on iOS. */
    fun compareNumeric(left: String, right: String): Int = compareNumbers(left, right)

    private fun normalize(value: String): String = java.text.Normalizer
        .normalize(value, java.text.Normalizer.Form.NFD)
        .replace(Regex("\\p{Mn}+"), "")
        .lowercase(Locale.ROOT)
}

internal fun compareNumbers(left: String, right: String): Int {
    val lhs = firstYear(left) ?: Int.MIN_VALUE
    val rhs = firstYear(right) ?: Int.MIN_VALUE
    return lhs.compareTo(rhs)
}

fun firstYear(text: String): Int? = Regex("\\d{3,4}").find(text)?.value?.toIntOrNull()
