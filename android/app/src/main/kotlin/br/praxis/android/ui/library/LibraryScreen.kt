package br.praxis.android.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.praxis.android.R
import br.praxis.android.data.Author
import br.praxis.android.data.Catalog
import br.praxis.android.data.CatalogCollection
import br.praxis.android.data.CatalogRepository
import br.praxis.android.data.Language
import br.praxis.android.data.LibraryFilter
import br.praxis.android.data.Popular
import br.praxis.android.data.Portraits
import br.praxis.android.data.TextSearch
import br.praxis.android.data.Work
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.AuthorArtwork
import br.praxis.android.design.components.BookCover
import br.praxis.android.design.components.Chevron
import br.praxis.android.design.components.GlassSurface
import br.praxis.android.design.components.InsetDivider
import br.praxis.android.design.components.PraxisChip
import br.praxis.android.design.components.SectionHeader
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private val horizontal = Tokens.Spacing.s5

@Composable
fun LibraryScreen() {
    val context = LocalContext.current
    val repository = remember { CatalogRepository(context.applicationContext) }
    var catalog by remember { mutableStateOf<Catalog?>(null) }
    var failed by remember { mutableStateOf(false) }
    var query by rememberSaveable { mutableStateOf("") }
    var filter by rememberSaveable { mutableStateOf(LibraryFilter.all) }

    LaunchedEffect(Unit) {
        failed = runCatching { repository.load(Language.pt) }
            .onSuccess { catalog = it }
            .isFailure
    }

    Box(modifier = Modifier.fillMaxSize().background(Praxis.colors.background)) {
        when {
            failed -> EmptyContent(
                title = stringResource(R.string.library_catalog_unavailable),
                body = null,
                modifier = Modifier.align(Alignment.Center),
            )
            catalog == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Praxis.colors.accent)
            }
            else -> LibraryContent(
                catalog = catalog!!,
                query = query,
                filter = filter,
                onFilter = { filter = it },
            )
        }

        if (catalog != null) {
            SearchField(
                query = query,
                onQueryChange = { query = it },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(horizontal = horizontal, vertical = Tokens.Spacing.s3),
            )
        }
    }
}

@Composable
private fun LibraryContent(
    catalog: Catalog,
    query: String,
    filter: LibraryFilter,
    onFilter: (LibraryFilter) -> Unit,
) {
    val searching = query.isNotBlank()
    val popularWriters = remember(catalog) { Popular.authors(catalog, Language.pt) }
    val popularWorks = remember(catalog) { Popular.works(catalog, Language.pt) }
    val featured = remember(catalog) { Popular.featured(popularWorks, LocalDate.now().toEpochDay()) }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 96.dp),
    ) {
        item { Header() }
        item { FilterBar(catalog = catalog, selected = filter, onSelect = onFilter) }

        if (searching) {
            searchResults(catalog = catalog, query = query)
        } else {
            when (filter) {
                LibraryFilter.all -> {
                    item {
                        if (featured != null) {
                            FeaturedCard(
                                title = featured.second.title,
                                credit = featured.first.full,
                                modifier = Modifier.padding(horizontal = horizontal, vertical = Tokens.Spacing.s3),
                            )
                        }
                    }
                    item {
                        SectionHeader(
                            title = stringResource(R.string.section_popular_writers),
                            action = stringResource(R.string.action_see_all),
                            onAction = { onFilter(LibraryFilter.writers) },
                            modifier = Modifier.padding(horizontal = horizontal, vertical = Tokens.Spacing.s2),
                        )
                    }
                    item {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = horizontal),
                            horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s4),
                        ) {
                            items(popularWriters, key = { it.id }) { author ->
                                WriterCard(author)
                            }
                        }
                    }
                    item {
                        SectionHeader(
                            title = stringResource(R.string.section_library),
                            action = stringResource(R.string.action_see_all),
                            onAction = { onFilter(LibraryFilter.works) },
                            modifier = Modifier.padding(horizontal = horizontal, vertical = Tokens.Spacing.s2),
                        )
                    }
                    item { WorkList(popularWorks) }
                }

                LibraryFilter.writers -> item { WriterList(catalog.authors) }
                LibraryFilter.works -> item { WorkList(catalog.authors.flatMap { author -> author.works.map { author to it } }) }
                LibraryFilter.topics -> item { CollectionList(catalog.themes) }
                LibraryFilter.history -> item { CollectionList(catalog.history) }

                LibraryFilter.saved -> item {
                    EmptyContent(
                        title = stringResource(R.string.empty_saved),
                        body = stringResource(R.string.empty_saved_body),
                    )
                }

                LibraryFilter.readingHistory -> item {
                    EmptyContent(
                        title = stringResource(R.string.empty_history),
                        body = stringResource(R.string.empty_history_body),
                    )
                }
            }

            item { CatalogFooter(catalog.generated) }
        }
    }
}

@Composable
private fun Header() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(horizontal = horizontal)
            .padding(top = Tokens.Spacing.s6, bottom = Tokens.Spacing.s3),
    ) {
        Text(
            text = stringResource(R.string.library_title),
            style = MaterialTheme.typography.displayLarge,
            color = Praxis.colors.textPrimary,
        )
        Spacer(Modifier.height(Tokens.Spacing.s1))
        Text(
            text = stringResource(R.string.library_subtitle),
            style = MaterialTheme.typography.bodyLarge,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun FilterBar(catalog: Catalog, selected: LibraryFilter, onSelect: (LibraryFilter) -> Unit) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = horizontal, vertical = Tokens.Spacing.s2),
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2),
    ) {
        items(LibraryFilter.chips(catalog.history.isNotEmpty()), key = { it.name }) { filter ->
            PraxisChip(
                text = stringResource(filter.title),
                selected = filter == selected,
                onClick = { onSelect(filter) },
            )
        }
    }
}

@Composable
private fun FeaturedCard(title: String, credit: String, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Praxis.colors.surface)
            .border(1.dp, Praxis.colors.separator, shape)
            .padding(Tokens.Spacing.s4),
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s4),
    ) {
        BookCover(
            title = title,
            modifier = Modifier
                .width(76.dp)
                .height(104.dp),
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                color = Praxis.colors.textPrimary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(Tokens.Spacing.s1))
            Text(
                text = credit,
                style = MaterialTheme.typography.bodyMedium,
                color = Praxis.colors.textSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(Tokens.Spacing.s3))
            Text(
                text = stringResource(R.string.action_start_reading),
                style = MaterialTheme.typography.bodyLarge,
                color = Praxis.colors.accent,
            )
        }
    }
}

@Composable
private fun WriterCard(author: Author) {
    Column(modifier = Modifier.width(126.dp)) {
        AuthorArtwork(
            name = author.full,
            modifier = Modifier.fillMaxWidth().height(116.dp),
            imageUrl = Portraits.url(author, Language.pt),
            focalAlignment = if (author.id == "engels") Alignment.TopCenter else Alignment.Center,
        )
        Spacer(Modifier.height(Tokens.Spacing.s2))
        Text(
            text = author.full,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.SemiBold,
            color = Praxis.colors.textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = workCountLabel(author.works.size),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun WriterList(authors: List<Author>) {
    Column(modifier = Modifier.padding(horizontal = horizontal)) {
        authors.forEachIndexed { index, author ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { }
                    .padding(vertical = Tokens.Spacing.s2),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
            ) {
                AuthorArtwork(
                    name = author.full,
                    modifier = Modifier.size(48.dp, 54.dp),
                    imageUrl = Portraits.url(author, Language.pt),
                )
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = author.full,
                        style = MaterialTheme.typography.titleSmall,
                        color = Praxis.colors.textPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        text = author.displayDates.ifEmpty { workCountLabel(author.works.size) },
                        style = MaterialTheme.typography.bodyMedium,
                        color = Praxis.colors.textSecondary,
                    )
                }
                Chevron()
            }
            if (index < authors.lastIndex) InsetDivider(startPadding = Tokens.Spacing.s16)
        }
    }
}

@Composable
private fun WorkList(works: List<Pair<Author, Work>>) {
    Column(modifier = Modifier.padding(horizontal = horizontal)) {
        works.forEachIndexed { index, (author, work) ->
            WorkRow(work = work, author = author.full)
            if (index < works.lastIndex) InsetDivider(startPadding = 68.dp)
        }
    }
}

@Composable
private fun WorkRow(work: Work, author: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { }
            .padding(vertical = Tokens.Spacing.s3),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
    ) {
        BookCover(
            title = work.title,
            modifier = Modifier
                .width(50.dp)
                .height(68.dp),
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = work.title,
                style = MaterialTheme.typography.titleSmall,
                color = Praxis.colors.textPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (author.isNotEmpty()) {
                Text(
                    text = author,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Praxis.colors.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (work.date.isNotEmpty()) {
                Text(
                    text = work.date,
                    style = MaterialTheme.typography.labelMedium,
                    color = Praxis.colors.textSecondary,
                )
            }
        }
        Chevron()
    }
}

@Composable
private fun CollectionList(collections: List<CatalogCollection>) {
    Column(modifier = Modifier.padding(horizontal = horizontal)) {
        var lastGroup: String? = null
        collections.forEach { collection ->
            if (collection.group.isNotEmpty() && collection.group != lastGroup) {
                lastGroup = collection.group
                Text(
                    text = collection.group,
                    style = MaterialTheme.typography.titleSmall,
                    color = Praxis.colors.textPrimary,
                    modifier = Modifier.padding(top = Tokens.Spacing.s4, bottom = Tokens.Spacing.s1),
                )
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { }
                    .heightIn(min = 44.dp)
                    .padding(vertical = Tokens.Spacing.s2),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = collection.title,
                    style = MaterialTheme.typography.titleSmall,
                    color = Praxis.colors.textPrimary,
                    modifier = Modifier.weight(1f),
                )
                Chevron()
            }
            InsetDivider()
        }
    }
}

@Composable
private fun EmptyContent(title: String, body: String?, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = horizontal, vertical = Tokens.Spacing.s8),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = title, style = MaterialTheme.typography.titleSmall, color = Praxis.colors.textPrimary)
        if (body != null) {
            Spacer(Modifier.height(Tokens.Spacing.s1))
            Text(
                text = body,
                style = MaterialTheme.typography.bodyMedium,
                color = Praxis.colors.textSecondary,
            )
        }
    }
}

@Composable
private fun CatalogFooter(generated: String) {
    val formatted = remember(generated) {
        runCatching { LocalDate.parse(generated).format(DateTimeFormatter.ofPattern("d 'de' MMMM 'de' yyyy")) }
            .getOrDefault(generated)
    }
    Text(
        text = stringResource(R.string.catalog_updated, formatted),
        style = MaterialTheme.typography.labelMedium,
        color = Praxis.colors.textSecondary,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = horizontal, vertical = Tokens.Spacing.s6),
    )
}

@Composable
private fun SearchField(query: String, onQueryChange: (String) -> Unit, modifier: Modifier = Modifier) {
    GlassSurface(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 52.dp)
                .padding(horizontal = Tokens.Spacing.s4),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2),
        ) {
            Icon(
                imageVector = Icons.Filled.Search,
                contentDescription = null,
                tint = Praxis.colors.textSecondary,
                modifier = Modifier.size(20.dp),
            )
            Box(modifier = Modifier.weight(1f)) {
                if (query.isEmpty()) {
                    Text(
                        text = stringResource(R.string.library_search_hint),
                        style = MaterialTheme.typography.bodyLarge,
                        color = Praxis.colors.textSecondary,
                    )
                }
                BasicTextField(
                    value = query,
                    onValueChange = onQueryChange,
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodyLarge.copy(color = Praxis.colors.textPrimary),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (query.isNotEmpty()) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = stringResource(R.string.library_search_clear),
                    tint = Praxis.colors.textSecondary,
                    modifier = Modifier
                        .size(20.dp)
                        .clickable { onQueryChange("") },
                )
            }
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.searchResults(catalog: Catalog, query: String) {
    val authors = catalog.authors.filter { author ->
        TextSearch.contains(author.name, query) ||
            TextSearch.contains(author.full, query) ||
            TextSearch.contains(author.country, query) ||
            author.groups.any { TextSearch.contains(it, query) }
    }.take(20)
    val works = catalog.authors
        .flatMap { author -> author.works.map { author to it } }
        .filter { TextSearch.contains(it.second.title, query) }
        .take(100)
    val themes = catalog.themes.filter { TextSearch.contains(it.title, query) || TextSearch.contains(it.group, query) }

    if (authors.isEmpty() && works.isEmpty() && themes.isEmpty()) {
        item {
            EmptyContent(
                title = stringResource(R.string.empty_results),
                body = stringResource(R.string.empty_results_body),
            )
        }
        return
    }
    if (authors.isNotEmpty()) {
        item {
            SectionHeader(
                title = stringResource(R.string.filter_writers),
                modifier = Modifier.padding(horizontal = horizontal, vertical = Tokens.Spacing.s2),
            )
        }
        item { WriterList(authors) }
    }
    if (works.isNotEmpty()) {
        item {
            SectionHeader(
                title = stringResource(R.string.filter_works),
                modifier = Modifier.padding(horizontal = horizontal, vertical = Tokens.Spacing.s2),
            )
        }
        item { WorkList(works) }
    }
    if (themes.isNotEmpty()) {
        item {
            SectionHeader(
                title = stringResource(R.string.filter_topics),
                modifier = Modifier.padding(horizontal = horizontal, vertical = Tokens.Spacing.s2),
            )
        }
        item { CollectionList(themes) }
    }
}

@Composable
private fun workCountLabel(count: Int): String = if (count == 1) {
    stringResource(R.string.work_count_one, count)
} else {
    stringResource(R.string.work_count, count)
}
