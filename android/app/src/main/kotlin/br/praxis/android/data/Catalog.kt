package br.praxis.android.data

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

data class Work(
    val title: String,
    val path: String,
    val date: String = "",
    val section: Int = 0,
    val credit: String? = null,
    val readingID: String? = null,
) {
    val id: String get() = path
}

data class CatalogItem(
    val title: String,
    val path: String,
    val person: Boolean = false,
)

data class CatalogGroup(val name: String, val items: List<CatalogItem>)

data class CatalogCollection(
    val id: String,
    val title: String,
    val group: String,
    val groups: List<CatalogGroup>,
) {
    val itemCount: Int get() = groups.sumOf { it.items.size }
}

data class Author(
    val id: String,
    val name: String,
    val years: String = "",
    val avatar: String? = null,
    val bioPath: String? = null,
    val full: String,
    val dates: String = "",
    val photo: String? = null,
    val country: String = "",
    val bio: String = "",
    val sections: List<String> = emptyList(),
    val works: List<Work> = emptyList(),
    val groups: List<String> = emptyList(),
) {
    val displayDates: String get() = dates.ifBlank { years }
}

data class Catalog(
    val authors: List<Author>,
    val generated: String,
    val themes: List<CatalogCollection>,
    val history: List<CatalogCollection>,
    val figures: List<CatalogItem>,
) {
    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        /**
         * Reads the catalog the same tolerant way Catalog.swift does: a missing field or a malformed
         * row is skipped instead of failing the whole snapshot.
         */
        fun parse(text: String, language: Language = Language.pt): Catalog {
            val root = json.parseToJsonElement(text).jsonObject
            val authors = root["authors"].array().mapNotNull(::author)
            return Catalog(
                authors = if (language == Language.pt) separateMarxAndEngels(authors) else authors,
                generated = root["generated"].string().orEmpty(),
                themes = collections(root["themes"]),
                history = collections(root["history"]),
                figures = root["figures"].array().mapNotNull(::figure),
            )
        }

        private fun author(row: JsonElement): Author? {
            val object0 = row as? JsonObject ?: return null
            val id = object0["id"].rawString() ?: return null
            val name = object0["name"].rawString() ?: ""
            val works = object0["works"].array().mapNotNull { work ->
                val values = work as? JsonArray ?: return@mapNotNull null
                val title = values.getOrNull(0)?.rawString() ?: return@mapNotNull null
                val path = values.getOrNull(1)?.rawString() ?: return@mapNotNull null
                Work(
                    title = title,
                    path = path,
                    date = values.getOrNull(2)?.string().orEmpty(),
                    section = values.getOrNull(3)?.let { (it as? JsonPrimitive)?.intOrNull } ?: 0,
                    credit = values.getOrNull(4)?.string()?.takeIf { it.isNotBlank() },
                )
            }
            return Author(
                id = id,
                name = name,
                years = object0["years"].string().orEmpty(),
                avatar = object0["avatar"].string(),
                bioPath = object0["bioPath"].string(),
                full = object0["full"].rawString() ?: name,
                dates = object0["dates"].string().orEmpty(),
                photo = object0["photo"].string(),
                country = object0["country"].string().orEmpty(),
                bio = object0["bio"].string().orEmpty(),
                sections = object0["sections"].array().mapNotNull { it.string() ?: (it as? JsonPrimitive)?.contentOrNull },
                works = works,
                groups = object0["groups"].array().mapNotNull { it.string() ?: (it as? JsonPrimitive)?.contentOrNull },
            )
        }

        private fun figure(row: JsonElement): CatalogItem? {
            val object0 = row as? JsonObject ?: return null
            val name = object0["name"].rawString() ?: return null
            val path = object0["path"].rawString() ?: return null
            return CatalogItem(
                title = name,
                path = path,
                person = (object0["person"] as? JsonPrimitive)?.booleanOrNull ?: false,
            )
        }

        private fun collections(element: JsonElement?): List<CatalogCollection> =
            element.array().mapNotNull { row ->
                val object0 = row as? JsonObject ?: return@mapNotNull null
                val title = object0["title"].rawString().orEmpty()
                val groups = object0["groups"].array().map { group ->
                    val groupObject = group as? JsonObject
                    CatalogGroup(
                        name = groupObject?.get("name").rawString().orEmpty(),
                        items = groupObject?.get("works").array().mapNotNull { item ->
                            val values = item as? JsonArray ?: return@mapNotNull null
                            val itemTitle = values.getOrNull(0)?.rawString() ?: return@mapNotNull null
                            val path = values.getOrNull(1)?.rawString() ?: return@mapNotNull null
                            CatalogItem(itemTitle, path)
                        }.orEmpty(),
                    )
                }
                CatalogCollection(
                    id = object0["id"].rawString() ?: title,
                    title = title,
                    group = object0["group"].string().orEmpty(),
                    groups = groups,
                )
            }

        /**
         * The Portuguese archive groups Marx and Engels under a single index. The app separates them
         * using the credit carried by each row; uncredited rows stay with Marx and are never guessed.
         */
        private fun separateMarxAndEngels(authors: List<Author>): List<Author> {
            val index = authors.indexOfFirst { it.id == "marx" }
            if (index < 0) return authors
            val source = authors[index]
            if (!source.full.contains("Friedrich Engels", ignoreCase = true)) return authors

            val marxWorks = source.works.filter { it.credit != "Friedrich Engels" }
            val engelsWorks = source.works.filter {
                it.credit == "Friedrich Engels" || it.credit == "Karl Marx e Friedrich Engels"
            }
            val marx = source.copy(
                name = "Marx, Karl",
                full = "Karl Marx",
                dates = "1818–1883",
                bio = "Filósofo, economista e revolucionário alemão, Karl Marx desenvolveu uma crítica da economia política e do capitalismo.",
                works = marxWorks,
                photo = source.photo,
                bioPath = "dicionario/verbetes/m/marx.htm",
            )
            val engels = source.copy(
                id = "engels",
                name = "Engels, Friedrich",
                full = "Friedrich Engels",
                dates = "1820–1895",
                avatar = source.avatar,
                works = engelsWorks,
                photo = "https://www.marxists.org/archive/marx/photo/engels/images/88fe1.jpg",
                bioPath = "dicionario/verbetes/e/engels.htm",
            )
            return authors.toMutableList().apply {
                set(index, marx)
                add(index + 1, engels)
            }
        }
    }

    val workKeys: Set<String> by lazy {
        authors.flatMap { author -> author.works.map { it.path } }.toSet()
    }

    fun author(id: String): Author? = authors.firstOrNull { it.id == id }
}

internal fun JsonElement?.array(): List<JsonElement> = when (this) {
    is JsonArray -> this
    is JsonObject -> listOf(this)
    else -> emptyList()
}

internal fun JsonElement?.string(): String? = when (this) {
    is JsonPrimitive -> contentOrNull?.takeIf { it.isNotEmpty() }
    else -> null
}

/** Identity fields keep empty values, because the snapshot can carry a row with no name. */
internal fun JsonElement?.rawString(): String? = (this as? JsonPrimitive)?.contentOrNull
