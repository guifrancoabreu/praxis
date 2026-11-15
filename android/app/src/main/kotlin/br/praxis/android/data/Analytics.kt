package br.praxis.android.data

import android.content.Context
import com.telemetrydeck.sdk.TelemetryDeck
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * Explicit event allowlist, mirroring Analytics.swift. Never send work titles, author names, search
 * text, archive paths or reading positions.
 *
 * The SDK only starts after the reader consents, and runs in memory-only mode: no persistent user
 * identifier, no install or retention tracking. Revoking consent stops further signals.
 */
object Analytics {
    sealed class Event(val eventName: String, val parameters: Map<String, String> = emptyMap()) {
        data object SearchUsed : Event("Library.Search.Used")
        data object AuthorProfileOpened : Event("Library.AuthorProfile.Opened")
        data object WorkOpened : Event("Reader.Work.Opened")
        data object ReaderAppearanceOpened : Event("Reader.Appearance.Opened")
        data object ArchiveSourceOpened : Event("Reader.ArchiveSource.Opened")
        data object SupportPageOpened : Event("Support.Page.Opened")
        class FilterSelected(filter: String) : Event("Library.Filter.Selected", mapOf("filter" to filter))
        class BookmarkChanged(saved: Boolean) :
            Event("Reader.Bookmark.Changed", mapOf("saved" to if (saved) "true" else "false"))
        class SupportDestinationOpened(destination: String) :
            Event("Support.Destination.Opened", mapOf("destination" to destination))
    }

    // Shared with the iOS project so both platforms land in one dashboard.
    private const val APP_ID = "27BA9D21-5BD6-445D-81B7-F082D2A861A6"

    private var enabled = false
    private var started = false

    fun configure(context: Context, preferences: PraxisPreferences) {
        val consent = runBlocking { preferences.analyticsConsent.first() }
        if (consent) start(context)
    }

    private fun start(context: Context) {
        if (started) return
        started = true
        enabled = true
        runCatching {
            val builder = TelemetryDeck.Builder()
                .appID(APP_ID)
                .inMemoryOnly(true)
            TelemetryDeck.start(context.applicationContext, builder)
        }.onFailure { enabled = false }
    }

    fun setConsent(context: Context, preferences: PraxisPreferences, granted: Boolean) {
        if (granted) start(context) else enabled = false
    }

    fun track(event: Event) {
        if (!enabled) return
        runCatching {
            if (event.parameters.isEmpty()) TelemetryDeck.signal(event.eventName)
            else TelemetryDeck.signal(event.eventName, event.parameters)
        }
    }
}
