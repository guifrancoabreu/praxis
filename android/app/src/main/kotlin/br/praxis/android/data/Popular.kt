package br.praxis.android.data

/**
 * Editorial ranking, ported from PraxisApp.swift. Recognition-based, not a measurement of activity
 * in the app; the lists are curated per archive language.
 */
object Popular {
    val rankedAuthorIds: Map<Language, List<String>> = mapOf(
        Language.pt to listOf("marx", "lenin", "engels", "gramsci", "luxemburgo", "trotsky", "guevara", "mao", "castro", "bukharin"),
        Language.en to listOf(
            "archive/marx", "archive/lenin", "archive/luxemburg", "archive/trotsky",
            "archive/gramsci", "archive/guevara", "reference/archive/mao", "history/cuba/archive/castro",
        ),
        Language.es to listOf(
            "m-e/index.htm", "lenin/index.htm", "luxem/index.htm", "trotsky/index.htm",
            "gramsci/index.htm", "guevara/index.htm", "bujarin/index.htm",
        ),
    )

    private val portugueseTitles = listOf(
        "Manifesto do Partido Comunista", "O Capital - Crítica", "O Estado e a Revolução", "O Imperialismo, Fase Superior",
        "Reforma ou Revolução", "Do Socialismo Utópico", "A Origem da Família", "Crítica do Programa de Gotha", "Que Fazer?",
        "Trabalho Assalariado e Capital", "A Doença Infantil", "O 18 de Brumário", "Guerra Civil na França", "A Ideologia Alemã",
        "Valor, Preço e Lucro", "Miséria da Filosofia", "Manuscritos Econômico-Filosóficos", "Anti-Dühring", "Greve de massas",
        "A Acumulação do Capital", "A Revolução Traída", "A Revolução Permanente", "Dez Dias que Abalaram o Mundo",
        "Teses sobre Feuerbach", "ABC do Comunismo", "Citações do Presidente Mao", "Sobre a Prática", "Sobre a Contradição",
        "O Desenvolvimento do Capitalismo na Rússia", "A Situação da Classe Trabalhadora", "A Guerra de Guerrilhas",
        "Três Fontes", "A Questão Judaica", "A Sagrada Família", "O Programa de Gotha", "O Direito à Preguiça",
        "A Revolução Russa", "O Materialismo Dialético", "O Imperialismo e a Economia Mundial", "A Guerra Civil",
        "O Desenvolvimento do Capitalismo", "O Socialismo e as Igrejas", "O Estado", "O Que Fazer",
        "A Mulher e o Socialismo", "O Trabalho Assalariado", "A Revolução Proletária",
    )

    private val portugueseWorkAuthors = mapOf(
        "Manifesto do Partido Comunista" to "marx", "O Capital - Crítica" to "marx",
        "O Estado e a Revolução" to "lenin", "O Imperialismo, Fase Superior" to "lenin",
        "Reforma ou Revolução" to "luxemburgo", "Do Socialismo Utópico" to "engels",
        "A Origem da Família" to "engels", "Crítica do Programa de Gotha" to "marx",
        "Que Fazer?" to "lenin", "Trabalho Assalariado e Capital" to "marx",
        "A Doença Infantil" to "lenin", "O 18 de Brumário" to "marx",
        "Guerra Civil na França" to "marx", "A Ideologia Alemã" to "marx",
        "Valor, Preço e Lucro" to "marx", "Miséria da Filosofia" to "marx",
        "Manuscritos Econômico-Filosóficos" to "marx", "Anti-Dühring" to "engels",
        "Greve de massas" to "luxemburgo", "A Acumulação do Capital" to "luxemburgo",
        "A Revolução Traída" to "trotsky", "A Revolução Permanente" to "trotsky",
        "Dez Dias que Abalaram o Mundo" to "reed", "Teses sobre Feuerbach" to "marx",
        "ABC do Comunismo" to "bukharin", "Citações do Presidente Mao" to "mao",
        "Sobre a Prática" to "mao", "Sobre a Contradição" to "mao",
        "O Desenvolvimento do Capitalismo na Rússia" to "lenin", "A Situação da Classe Trabalhadora" to "engels",
        "A Guerra de Guerrilhas" to "lenin", "Três Fontes" to "lenin", "A Questão Judaica" to "marx",
        "A Sagrada Família" to "marx", "O Programa de Gotha" to "marx", "O Direito à Preguiça" to "lafargue",
        "A Revolução Russa" to "luxemburgo", "O Materialismo Dialético" to "stalin",
        "O Imperialismo e a Economia Mundial" to "bukharin", "A Guerra Civil" to "marx",
        "O Desenvolvimento do Capitalismo" to "lenin", "O Socialismo e as Igrejas" to "luxemburgo",
        "O Estado" to "lenin", "O Que Fazer" to "lenin", "A Mulher e o Socialismo" to "bebel",
        "O Trabalho Assalariado" to "marx", "A Revolução Proletária" to "lenin",
    )

    private val fallbackAuthorIds = mapOf(
        Language.pt to listOf("marx", "engels", "lenin", "luxemburgo", "trotsky", "mao", "gramsci", "bukharin", "reed"),
        Language.en to listOf(
            "archive/marx", "archive/lenin", "archive/luxemburg", "archive/trotsky",
            "archive/gramsci", "reference/archive/mao", "archive/bukharin", "archive/reed",
        ),
        Language.es to listOf("m-e/index.htm", "lenin/index.htm", "luxem/index.htm", "trotsky/index.htm", "gramsci/index.htm", "bujarin/index.htm"),
    )

    fun authors(catalog: Catalog, language: Language): List<Author> {
        val ranked = rankedAuthorIds[language].orEmpty()
        return ranked.mapNotNull { id -> catalog.authors.firstOrNull { it.id == id } }
    }

    fun works(catalog: Catalog, language: Language): List<Pair<Author, Work>> {
        val titles = if (language == Language.pt) portugueseTitles else emptyList()
        val expectedAuthors = if (language == Language.pt) portugueseWorkAuthors else emptyMap()
        val sources = catalog.authors.flatMap { author -> author.works.map { author to it } }
        val chosen = mutableListOf<Pair<Author, Work>>()
        val chosenPaths = mutableSetOf<String>()

        for (signature in titles) {
            val authorId = expectedAuthors[signature] ?: continue
            val match = sources.firstOrNull {
                it.first.id == authorId && it.second.title.equals(signature, ignoreCase = true)
            } ?: sources.firstOrNull {
                it.first.id == authorId && it.second.title.lowercase().startsWith(signature.lowercase())
            } ?: continue
            if (chosenPaths.add(match.second.path)) chosen += match
        }

        val fallback = fallbackAuthorIds[language].orEmpty()
            .mapNotNull { id -> catalog.authors.firstOrNull { it.id == id } }
            .map { author -> sources.filter { it.first.id == author.id } }

        var offset = 0
        while (offset < 500 && chosen.size < 50) {
            for (authorWorks in fallback) {
                if (chosen.size >= 50) break
                val candidate = authorWorks.getOrNull(offset) ?: continue
                if (chosenPaths.add(candidate.second.path)) chosen += candidate
            }
            offset++
        }
        return chosen.take(50)
    }

    /** Rotates daily, matching featuredPopularWork on iOS. */
    fun featured(works: List<Pair<Author, Work>>, epochDay: Long): Pair<Author, Work>? {
        if (works.isEmpty()) return null
        val index = ((epochDay - 1) % works.size).toInt().let { if (it < 0) it + works.size else it }
        return works[index]
    }
}
