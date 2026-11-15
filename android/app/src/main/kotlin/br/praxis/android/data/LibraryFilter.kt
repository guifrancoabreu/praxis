package br.praxis.android.data

import androidx.annotation.StringRes
import br.praxis.android.R

/** Library filters, in the order the chip bar shows them. */
enum class LibraryFilter(@StringRes val title: Int) {
    all(R.string.filter_all),
    saved(R.string.filter_saved),
    writers(R.string.filter_writers),
    works(R.string.filter_works),
    readingHistory(R.string.filter_reading_history),
    topics(R.string.filter_topics),
    history(R.string.filter_history);

    companion object {
        /** Only these chips are reachable in the shipping build, as on iOS. */
        fun chips(hasHistory: Boolean): List<LibraryFilter> =
            listOf(all, saved, readingHistory, writers, works, topics) + listOfNotNull(history.takeIf { hasHistory })
    }
}

enum class CatalogSort { popularity, az, za, date }
