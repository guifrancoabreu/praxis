package br.praxis.android

import br.praxis.android.data.CatalogRepository
import br.praxis.android.data.PageStore
import br.praxis.android.data.PraxisPreferences

/** Minimal application graph: one catalog, one preference store, one page cache per process. */
object AppGraph {
    lateinit var repository: CatalogRepository
    lateinit var preferences: PraxisPreferences
    lateinit var pageStore: PageStore
}
