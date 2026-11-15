package br.praxis.android.data

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json

private val Context.dataStore by preferencesDataStore(name = "praxis")

/**
 * Preferences with the same keys and JSON shapes the iOS app stores in UserDefaults, so a shared
 * spec describes both platforms and the reading history stays portable.
 */
class PraxisPreferences(private val context: Context) {
    object Keys {
        val language = stringPreferencesKey("language")
        val savedWorkPaths = stringPreferencesKey("savedWorkPaths")
        val recentReadings = stringPreferencesKey("recentReadings")
        val readerAppearance = stringPreferencesKey("readerAppearance")
        val catalogSortOrder = stringPreferencesKey("catalogSortOrder")
        val groupWritersByMovement = booleanPreferencesKey("groupWritersByMovement")
        val glossaryPeopleOnly = booleanPreferencesKey("glossaryPeopleOnly")
        val analyticsConsent = booleanPreferencesKey("analyticsConsent")
        val analyticsPromptAnswered = booleanPreferencesKey("analyticsPromptAnswered")
    }

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    val language: Flow<Language> = context.dataStore.data.map { prefs ->
        Language.fromCode(prefs[Keys.language])
    }

    val savedWorkPaths: Flow<List<String>> = context.dataStore.data.map { prefs ->
        decodePaths(prefs[Keys.savedWorkPaths])
    }

    val recentReadings: Flow<List<ReadingProgress>> = context.dataStore.data.map { prefs ->
        decodeReadings(prefs[Keys.recentReadings])
    }

    val readerAppearance: Flow<ReaderAppearance> = context.dataStore.data.map { prefs ->
        ReaderAppearance.decode(prefs[Keys.readerAppearance] ?: "")
    }

    val analyticsConsent: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.analyticsConsent] ?: false
    }

    val analyticsPromptAnswered: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.analyticsPromptAnswered] ?: false
    }

    val groupWritersByMovement: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.groupWritersByMovement] ?: true
    }

    val glossaryPeopleOnly: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.glossaryPeopleOnly] ?: true
    }

    val catalogSortOrder: Flow<CatalogSort> = context.dataStore.data.map { prefs ->
        CatalogSort.entries.firstOrNull { it.name == prefs[Keys.catalogSortOrder] } ?: CatalogSort.popularity
    }

    suspend fun setLanguage(language: Language) = edit(Keys.language, language.code)

    suspend fun setReaderAppearance(appearance: ReaderAppearance) =
        edit(Keys.readerAppearance, appearance.encoded())

    suspend fun setAnalyticsConsent(enabled: Boolean) = context.dataStore.edit { prefs ->
        prefs[Keys.analyticsConsent] = enabled
        prefs[Keys.analyticsPromptAnswered] = true
    }

    suspend fun setGroupWritersByMovement(grouped: Boolean) = context.dataStore.edit { prefs ->
        prefs[Keys.groupWritersByMovement] = grouped
    }

    suspend fun setGlossaryPeopleOnly(peopleOnly: Boolean) = context.dataStore.edit { prefs ->
        prefs[Keys.glossaryPeopleOnly] = peopleOnly
    }

    suspend fun setCatalogSortOrder(sort: CatalogSort) = edit(Keys.catalogSortOrder, sort.name)

    /** Toggles a work path, newest first, exactly like the iOS bookmark button. */
    suspend fun toggleSaved(path: String): Boolean {
        var saved = false
        context.dataStore.edit { prefs ->
            val paths = decodePaths(prefs[Keys.savedWorkPaths]).toMutableList()
            saved = if (paths.remove(path)) {
                false
            } else {
                paths.add(0, path)
                true
            }
            prefs[Keys.savedWorkPaths] = json.encodeToString(paths)
        }
        return saved
    }

    /** Records reading progress, keeping one entry per work, newest first. */
    suspend fun recordReading(progress: ReadingProgress) {
        context.dataStore.edit { prefs ->
            val readings = decodeReadings(prefs[Keys.recentReadings])
                .filterNot { it.path == progress.path || (progress.workId != null && it.workId == progress.workId) }
                .toMutableList()
            readings.add(0, progress)
            prefs[Keys.recentReadings] = json.encodeToString(readings.take(100))
        }
    }

    private suspend fun edit(key: Preferences.Key<String>, value: String) {
        context.dataStore.edit { it[key] = value }
    }

    private fun decodePaths(raw: String?): List<String> =
        if (raw.isNullOrBlank()) emptyList() else runCatching { json.decodeFromString<List<String>>(raw) }.getOrDefault(emptyList())

    private fun decodeReadings(raw: String?): List<ReadingProgress> =
        if (raw.isNullOrBlank()) emptyList() else runCatching { json.decodeFromString<List<ReadingProgress>>(raw) }.getOrDefault(emptyList())
}
