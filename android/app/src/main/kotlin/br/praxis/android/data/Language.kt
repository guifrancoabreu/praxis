package br.praxis.android.data

/** Archive section the app reads from. Mirrors Language in Catalog.swift. */
enum class Language(val code: String, val base: String, val label: String) {
    pt("pt", "https://www.marxists.org/portugues/", "Português"),
    en("en", "https://www.marxists.org/", "English"),
    es("es", "https://www.marxists.org/espanol/", "Español");

    companion object {
        fun fromCode(code: String?): Language = entries.firstOrNull { it.code == code } ?: pt
    }
}

/**
 * The shipping app is Portuguese-only, the same policy the iOS build applies: the catalog is
 * pinned to Portuguese and the language switch stays hidden until the other catalogs are released.
 */
object ReleasePolicy {
    const val isPortugueseOnly: Boolean = true

    val releaseLanguages: List<Language>
        get() = if (isPortugueseOnly) listOf(Language.pt) else Language.entries.toList()

    fun releaseLanguage(requested: Language): Language = if (isPortugueseOnly) Language.pt else requested
}
