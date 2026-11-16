package br.praxis.android.data

import android.content.Context
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.net.URI

/**
 * Composes the document script injected into every archive page.
 *
 * The assets come from shared/reader and are identical to the files the iOS app bundles; only the
 * host shim below is platform-specific.
 */
object ReaderScripts {
    private val cache = mutableMapOf<String, String>()

    private fun asset(context: Context, name: String): String = cache.getOrPut(name) {
        context.assets.open(name).bufferedReader(Charsets.UTF_8).use { it.readText() }
    }

    /** Bridges the shared script to this platform's JavaScript interface. */
    fun hostShim(): String = """
        window.__praxisHost = {
          progress: function (value) { PraxisBridge.progress(value); },
          link: function (url, title) { PraxisBridge.link(url, title); }
        };
    """.trimIndent()

    fun documentScript(
        context: Context,
        sourceUrl: String,
        appearance: ReaderAppearance,
        initialProgress: Double,
    ): String {
        val fragment = runCatching { URI(sourceUrl).fragment }.getOrNull()
        return asset(context, "reader.js")
            .replace("__READER_CSS__", quote(asset(context, "reader.css")))
            .replace("__READER_IMAGES__", asset(context, "reader-images.js"))
            .replace("__READER_LINK__", asset(context, "reader-link.js"))
            .replace("__READER_PROGRESS__", asset(context, "reader-progress.js"))
            .replace("__INITIAL_APPEARANCE__", appearance.encoded())
            .replace("__INITIAL_PROGRESS__", minOf(1.0, maxOf(0.0, initialProgress)).toString())
            .replace("__INITIAL_FRAGMENT__", fragment?.let(::quote) ?: "null")
            .replace("__SOURCE_URL__", quote(sourceUrl))
    }

    fun appearanceCall(appearance: ReaderAppearance): String =
        "window.setReaderAppearance && window.setReaderAppearance(${appearance.encoded()})"

    private fun quote(value: String): String = Json.encodeToString(String.serializer(), value)
}
