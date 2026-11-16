package br.praxis.android.data

import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element

/**
 * Removes the archive's own chrome before the page reaches the web view.
 *
 * iOS strips these nodes with an injected script while page JavaScript stays disabled. Android has
 * to enable JavaScript for the reader script, so the same cleanup runs here first: nothing from the
 * archive can execute, and what the web view loads is already the reading surface.
 */
object HtmlSanitizer {
    private const val REMOVED_SELECTORS =
        "script,style,link,meta,iframe,form,input,button,select,noscript,object,embed,map," +
            ".toplink,.toplink-centro,img.logo,img.logodic,nav,p.title"

    private val removedAttributes = setOf(
        "style", "align", "bgcolor", "color", "face", "size", "background",
        "border", "cellpadding", "cellspacing", "valign", "width", "height",
    )

    fun sanitize(html: String, baseUrl: String): String {
        val document: Document = Jsoup.parse(html, baseUrl)

        // The archive's <nav> carries the table of contents. Its anchor ids and names are kept so
        // in-page links still resolve after the navigation itself is gone.
        document.select("nav").forEach { nav ->
            nav.select("[id],[name]").forEach { anchor ->
                val marker = Element("span")
                anchor.id().takeIf { it.isNotEmpty() }?.let { marker.id(it) }
                anchor.attr("name").takeIf { it.isNotEmpty() }?.let { marker.attr("name", it) }
                nav.before(marker)
            }
        }

        document.select(REMOVED_SELECTORS).remove()

        document.allElements.forEach { element ->
            val isImage = element.tagName() == "img"
            element.attributes().asList().forEach { attribute ->
                val name = attribute.key.lowercase()
                if ((name == "width" || name == "height") && isImage) return@forEach
                if (name.startsWith("on") || name in removedAttributes) element.removeAttr(attribute.key)
            }
        }

        // Lazy-load everything past the masthead; the reader script keeps doing this on iOS.
        document.select("img").forEachIndexed { index, image ->
            if (index >= 2) image.attr("loading", "lazy")
            image.attr("decoding", "async")
        }

        return document.outerHtml()
    }
}
