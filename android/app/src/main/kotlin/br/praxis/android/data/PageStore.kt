package br.praxis.android.data

import android.content.Context
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.security.MessageDigest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/**
 * Archive pages and PDFs kept for offline reading, mirroring PageStore/PageCache on iOS.
 *
 * Files are named by the SHA-256 of their URL, live under filesDir/OfflinePages, and the cache is
 * trimmed to 100 MB by removing the least recently used files first.
 */
class PageStore(
    private val context: Context,
    private val client: OkHttpClient = OkHttpClient(),
) {
    private val directory = File(context.filesDir, "OfflinePages")
    private val limitBytes = 100L * 1024 * 1024
    private val mutex = Mutex()

    suspend fun loadHtml(url: String): String {
        cachedFile(url)?.takeIf { it.isFile }?.let { file ->
            runCatching { file.readText(Charsets.UTF_8) }.getOrNull()?.let {
                file.setLastModified(System.currentTimeMillis())
                return it
            }
        }
        val (bytes, charset) = fetch(url)
        val text = decode(bytes, charset)
        save(url, text.toByteArray(Charsets.UTF_8), null)
        return text
    }

    suspend fun loadPdf(url: String): ByteArray {
        cachedFile(url, "pdf")?.takeIf { it.isFile }?.let { file ->
            val bytes = runCatching { file.readBytes() }.getOrNull()
            if (bytes != null && isPdf(bytes)) {
                file.setLastModified(System.currentTimeMillis())
                return bytes
            }
        }
        val (bytes, _) = fetch(url)
        require(isPdf(bytes)) { "Not a PDF" }
        save(url, bytes, "pdf")
        return bytes
    }

    private fun decode(bytes: ByteArray, charset: String?): String {
        // Archive pages are mostly UTF-8, but old ones predate it and are latin-1.
        val declared = charset?.let { runCatching { charset(it) }.getOrNull() }
        if (declared != null) {
            runCatching { bytes.toString(declared) }.getOrNull()?.let { if (it.isNotBlank()) return it }
        }
        val utf8 = bytes.toString(Charsets.UTF_8)
        if (!utf8.contains('\uFFFD')) return utf8
        return bytes.toString(charset("windows-1252"))
    }

    private suspend fun fetch(url: String): Pair<ByteArray, String?> = withContext(Dispatchers.IO) {
        val request = Request.Builder().url(url).header("User-Agent", "Praxis/1.0").build()
        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) error("HTTP ${response.code}")
            val host = response.request.url.host
            if (host != "www.marxists.org" && host != "marxists.org") error("Unexpected host: $host")
            val contentType = response.header("Content-Type").orEmpty()
            val charset = Regex("charset=([\\w-]+)", RegexOption.IGNORE_CASE)
                .find(contentType)?.groupValues?.getOrNull(1)
            response.body.bytes() to charset
        }
    }

    private suspend fun save(url: String, bytes: ByteArray, extension: String?) = withContext(Dispatchers.IO) {
        mutex.withLock {
            directory.mkdirs()
            val file = cachedFile(url, extension) ?: return@withLock
            file.writeBytes(bytes)
            trim()
        }
    }

    private fun cachedFile(url: String, extension: String? = null): File? {
        val digest = MessageDigest.getInstance("SHA-256").digest(url.toByteArray())
        val name = digest.joinToString("") { "%02x".format(it) } + (extension?.let { ".$it" } ?: "")
        return File(directory, name)
    }

    private fun trim() {
        val files = directory.listFiles()?.filter { it.isFile }.orEmpty()
            .sortedByDescending { it.lastModified() }
        var total = 0L
        files.forEach { file ->
            total += file.length()
            if (total > limitBytes) file.delete()
        }
    }

    private fun isPdf(bytes: ByteArray): Boolean =
        bytes.size > 5 && String(bytes.copyOfRange(0, 5), Charsets.US_ASCII) == "%PDF-"
}
