package br.praxis.android.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Loads the bundled catalog snapshot. No network, no catalog API. */
class CatalogRepository(private val context: Context) {
    private val cache = mutableMapOf<Language, Catalog>()

    suspend fun load(language: Language): Catalog = withContext(Dispatchers.IO) {
        cache.getOrPut(language) {
            val text = context.assets.open("catalog-${language.code}.json")
                .bufferedReader(Charsets.UTF_8)
                .use { it.readText() }
            Catalog.parse(text, language)
        }
    }
}
