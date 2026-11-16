package br.praxis.android.data

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Reader appearance, sharing the JSON shape the iOS app stores. The six built-in themes carry the
 * same palettes, so a reader moving between platforms sees the same page.
 */
@Serializable
data class ReaderAppearance(
    val font: String = "serif",
    val size: Int = 19,
    val lineSpacing: Double = 1.6,
    val margin: Int = 18,
    val alignment: String = "left",
    val theme: String = "light",
    val background: String = "#fbfaf7",
    val foreground: String = "#1d1b19",
    val link: String = "#b3121d",
) {
    fun encoded(): String = json.encodeToString(serializer(), this)

    fun withTheme(name: String): ReaderAppearance {
        val palette = themes[name] ?: return copy(theme = name)
        return copy(theme = name, background = palette[0], foreground = palette[1], link = palette[2])
    }

    fun withColors(background: String? = null, foreground: String? = null, link: String? = null): ReaderAppearance =
        copy(
            theme = "custom",
            background = background ?: this.background,
            foreground = foreground ?: this.foreground,
            link = link ?: this.link,
        )

    companion object {
        val builtInThemes = listOf("light", "sepia", "gray", "dark", "black", "red")
        val fonts = listOf("serif", "sans", "book", "condensed", "mono", "casual")

        /** background / foreground / link, matching ReaderAppearance.setTheme on iOS. */
        val themes: Map<String, List<String>> = mapOf(
            "light" to listOf("#fbfaf7", "#1d1b19", "#b3121d"),
            "sepia" to listOf("#f4ecd8", "#3b2f22", "#9c2a12"),
            "gray" to listOf("#d9d9d6", "#202020", "#8e0d16"),
            "dark" to listOf("#1c1c1e", "#dedede", "#ff8a80"),
            "black" to listOf("#000000", "#c9c9c9", "#ff6e6e"),
            "red" to listOf("#4a0808", "#fbe9d0", "#ffcc00"),
        )

        private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

        fun decode(raw: String): ReaderAppearance =
            if (raw.isBlank()) ReaderAppearance() else runCatching {
                json.decodeFromString(serializer(), raw)
            }.getOrDefault(ReaderAppearance())

        /** WCAG contrast ratio, shown next to custom colours as on iOS. */
        fun contrastRatio(foreground: String, background: String): Double? {
            fun luminance(hex: String): Double? {
                if (hex.length != 7 || !hex.startsWith("#")) return null
                val value = hex.drop(1).toIntOrNull(16) ?: return null
                fun channel(shift: Int): Double {
                    val c = ((value shr shift) and 255) / 255.0
                    return if (c <= 0.04045) c / 12.92 else Math.pow((c + 0.055) / 1.055, 2.4)
                }
                return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
            }
            val a = luminance(foreground) ?: return null
            val b = luminance(background) ?: return null
            return (maxOf(a, b) + 0.05) / (minOf(a, b) + 0.05)
        }
    }
}
