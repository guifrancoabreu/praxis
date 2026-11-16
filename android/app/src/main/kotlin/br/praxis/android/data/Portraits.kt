package br.praxis.android.data

/** Resolves archive-relative portrait paths, mirroring AuthorArtwork on iOS. */
object Portraits {
    fun url(author: Author, language: Language): String? {
        val base = language.base
        author.photo?.let { return resolve(it, base) }
        author.avatar?.let { return resolve(it, base) }
        // The English archive keeps Marx and Engels in photo galleries instead of the writer index.
        if (language == Language.en && author.id == "archive/marx") {
            return resolve("archive/marx/photo/marx/images/67km1.jpg", base)
        }
        return null
    }

    private fun resolve(path: String, base: String): String? = runCatching {
        java.net.URI(base).resolve(path).toString()
    }.getOrNull()
}
