package br.praxis.android.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.net.URI

/** One reader position. Progress is the share of the page scrolled, not of the whole work. */
@Serializable
data class ReadingProgress(
    val path: String,
    val title: String = "",
    val author: String = "",
    val progress: Double = 0.0,
    @SerialName("workID") val workId: String? = null,
) {
    val id: String get() = workId ?: path
}

/**
 * Work identity for the reading log, ported from ReadingHistory on iOS.
 *
 * A work can span several archive pages, so entries are grouped by their canonical URL and by the
 * nearest catalogue directory. Pages that belong to a different catalogued work never merge.
 */
object ReadingHistory {
    private val indexNames = setOf("", "index.htm", "index.html", "default.htm", "default.html")

    private val genericDirectories = setOf(
        "ano", "anos", "mes", "meses", "month", "months", "year", "years",
        "works", "work", "archive", "arquivo", "texts", "textos", "text", "documents",
        "documentos", "docs", "images", "imagens", "photo", "photos", "foto", "fotos",
        "download", "downloads", "letters", "cartas", "cw", "sw", "index",
    )

    /** Absolute identity for a catalogue path or an archive URL; fragments are ignored. */
    fun canonicalKey(path: String, base: String): String {
        val trimmed = path.trim()
        if (trimmed.isEmpty()) return trimmed
        val url = runCatching { URI(base).resolve(trimmed) }.getOrNull() ?: return trimmed
        val host = url.host?.lowercase()
        val scheme = if (host == "marxists.org" || host == "www.marxists.org") "https" else url.scheme?.lowercase()
        val normalizedHost = if (host == "marxists.org" || host == "www.marxists.org") "www.marxists.org" else host
        return runCatching {
            URI(scheme, null, normalizedHost, url.port, url.path, url.query, null).toString()
        }.getOrDefault(trimmed)
    }

    fun directory(path: String): String? {
        val url = runCatching { URI(path) }.getOrNull() ?: return null
        val parent = url.path?.substringBeforeLast('/', "") ?: return null
        return if (parent.isEmpty()) null else java.net.URI(url.scheme, url.authority, parent, null, null).toString()
    }

    private fun isIndex(path: String): Boolean {
        val last = path.trimEnd('/').substringAfterLast('/')
        return last.lowercase() in indexNames
    }

    private fun isDedicatedDirectory(path: String): Boolean {
        val segments = URI(path).path?.split('/')?.filter { it.isNotEmpty() }.orEmpty()
        if (segments.size < 3) return false
        val name = segments.last().lowercase()
        return name !in genericDirectories && !name.all { it.isDigit() }
    }

    /** True when both paths are the same work, even if they are different pages of it. */
    fun isSameWork(left: String, right: String, knownWorkPaths: Set<String>): Boolean {
        if (left == right) return true
        if (knownWorkPaths.contains(right) || knownWorkPaths.contains(left)) return false
        val leftUrl = runCatching { URI(left) }.getOrNull() ?: return false
        val rightUrl = runCatching { URI(right) }.getOrNull() ?: return false
        if (leftUrl.host != rightUrl.host) return false
        val leftDirectory = directory(left)
        val rightDirectory = directory(right)
        if (leftDirectory == null || rightDirectory == null) return false
        val nested = rightDirectory.startsWith(leftDirectory) || leftDirectory.startsWith(rightDirectory)
        if (!nested) return false
        return isDedicatedDirectory(leftDirectory) || isDedicatedDirectory(rightDirectory)
    }

    /** Collapses page entries into one row per work, newest position first. */
    fun grouped(readings: List<ReadingProgress>, knownWorkPaths: Set<String>): List<ReadingProgress> {
        val groups = mutableListOf<MutableList<ReadingProgress>>()
        for (entry in readings) {
            val group = groups.firstOrNull { entries ->
                isSameWork(entries.first().canonicalOrPath(), entry.canonicalOrPath(), knownWorkPaths)
            }
            if (group != null) group.add(entry) else groups.add(mutableListOf(entry))
        }
        return groups.map { entries ->
            val newest = entries.first()
            val canonical = entries.firstOrNull { it.path == it.workId } ?: newest
            newest.copy(
                path = newest.path,
                title = canonical.title.ifEmpty { newest.title },
                author = canonical.author.ifEmpty { newest.author },
            )
        }
    }

    private fun ReadingProgress.canonicalOrPath(): String = workId ?: path
}
