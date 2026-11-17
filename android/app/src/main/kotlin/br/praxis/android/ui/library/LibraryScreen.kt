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
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.praxis.android.AppGraph
import br.praxis.android.BuildConfig
import br.praxis.android.R
import br.praxis.android.data.Analytics
import br.praxis.android.data.Author
import br.praxis.android.data.Catalog
import br.praxis.android.data.CatalogCollection
import br.praxis.android.data.Language
import br.praxis.android.data.LibraryFilter
import br.praxis.android.data.Popular
import br.praxis.android.data.Portraits
import br.praxis.android.data.ReadingHistory
import br.praxis.android.data.ReadingProgress
import br.praxis.android.data.TextSearch
import br.praxis.android.data.Work
import br.praxis.android.design.Praxis
import br.praxis.android.design.PraxisFonts
import br.praxis.android.design.Tokens
import br.praxis.android.design.caption
import br.praxis.android.design.title3
import br.praxis.android.design.components.AuthorArtwork
import br.praxis.android.design.components.BookCover
import br.praxis.android.design.components.Chevron
import br.praxis.android.design.components.GlassSurface
import br.praxis.android.design.components.InsetDivider
import br.praxis.android.design.components.PraxisChip
import br.praxis.android.design.components.RoundIconTile
import br.praxis.android.design.components.SectionHeader
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private val horizontal = Tokens.Spacing.s5
private object LibrarySpacing {
    val sections = Tokens.Spacing.s4
    val filtersToFirstSection = Tokens.Spacing.s0
    val headingToContent = Tokens.Spacing.s3
}

@Composable
fun LibraryScreen(
    onOpenWork: (Author, Work) -> Unit,
    onOpenAuthor: (Author) -> Unit,
    onOpenCollection: (CatalogCollection) -> Unit,
    onOpenSupport: () -> Unit,
    onOpenFeedback: () -> Unit,
    onOpenPrivacy: () -> Unit,
    onOpenStats: () -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val preferences = AppGraph.preferences
    var catalog by remember { mutableStateOf<Catalog?>(null) }
    var failed by remember { mutableStateOf(false) }
    var query by rememberSaveable { mutableStateOf("") }
    var filter by rememberSaveable { mutableStateOf(LibraryFilter.all) }
    var promptVisible by remember { mutableStateOf(false) }

    val savedPaths by preferences.savedWorkPaths.collectAsStateWithLifecycle(initialValue = emptyList())
    val readings by preferences.recentReadings.collectAsStateWithLifecycle(initialValue = emptyList())
    val consent by preferences.analyticsConsent.collectAsStateWithLifecycle(initialValue = false)
    val promptAnswered by preferences.analyticsPromptAnswered.collectAsStateWithLifecycle(initialValue = false)

    LaunchedEffect(Unit) {
        failed = runCatching { AppGraph.repository.load(Language.pt) }
            .onSuccess { catalog = it }
            .isFailure
    }

    LaunchedEffect(catalog, promptAnswered) {
        promptVisible = catalog != null && !promptAnswered && !consent
    }

    Box(modifier = Modifier.fillMaxSize().background(Praxis.colors.background)) {
        val loaded = catalog
        when {
            failed -> CenteredMessage(stringResource(R.string.library_catalog_unavailable))
            loaded == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Praxis.colors.accent)
            }
            else -> LibraryContent(
                catalog = loaded,
                query = query,
                filter = filter,
                savedPaths = savedPaths,
                readings = readings,
                onFilter = { filter = it; Analytics.track(Analytics.Event.FilterSelected(it.name)) },
                onOpenWork = onOpenWork,
                onOpenAuthor = onOpenAuthor,
                onOpenCollection = onOpenCollection,
                onOpenSupport = onOpenSupport,
                onOpenFeedback = onOpenFeedback,
                onOpenPrivacy = onOpenPrivacy,
                onOpenStats = onOpenStats,
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

    if (promptVisible) {
        AlertDialog(
            onDismissRequest = { promptVisible = false },
            title = { Text(stringResource(R.string.analytics_prompt_title)) },
            text = { Text(stringResource(R.string.analytics_prompt_body)) },
            confirmButton = {
                TextButton(onClick = {
                    scope.launch {
                        preferences.setAnalyticsConsent(true)
                        Analytics.setConsent(context.applicationContext, preferences, true)
                    }
                    promptVisible = false
                }) { Text(stringResource(R.string.analytics_prompt_share), color = Praxis.colors.accent) }
            },
            dismissButton = {
                TextButton(onClick = {
                    scope.launch {
                        preferences.setAnalyticsConsent(false)
                        Analytics.setConsent(context.applicationContext, preferences, false)
                    }
                    promptVisible = false
                }) { Text(stringResource(R.string.analytics_prompt_decline), color = Praxis.colors.textSecondary) }
            },
            containerColor = Praxis.colors.surface,
        )
    }
}

@Composable
private fun LibraryContent(
    catalog: Catalog,
    query: String,
    filter: LibraryFilter,
    savedPaths: List<String>,
    readings: List<ReadingProgress>,
    onFilter: (LibraryFilter) -> Unit,
    onOpenWork: (Author, Work) -> Unit,
    onOpenAuthor: (Author) -> Unit,
    onOpenCollection: (CatalogCollection) -> Unit,
    onOpenSupport: () -> Unit,
    onOpenFeedback: () -> Unit,
    onOpenPrivacy: () -> Unit,
    onOpenStats: () -> Unit,
) {
    val searching = query.isNotBlank()
    val popularWriters = remember(catalog) { Popular.authors(catalog, Language.pt) }
    val popularWorks = remember(catalog) { Popular.works(catalog, Language.pt) }
    val featured = remember(catalog) { Popular.featured(popularWorks, LocalDate.now().toEpochDay()) }
    val grouped = remember(readings, catalog) { ReadingHistory.grouped(readings, catalog.workKeys) }
    val savedWorks = remember(savedPaths, catalog) {
        val byPath = catalog.authors.flatMap { author -> author.works.map { author to it } }
            .associateBy { it.second.path }
        savedPaths.mapNotNull { byPath[it] }
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 96.dp),
        verticalArrangement = Arrangement.spacedBy(LibrarySpacing.sections),
    ) {
        item { Header() }
        if (searching) {
            searchResults(catalog = catalog, query = query, filter = filter, onFilter = onFilter, onOpenWork = onOpenWork, onOpenAuthor = onOpenAuthor, onOpenCollection = onOpenCollection)
        } else {
            when (filter) {
                LibraryFilter.all -> {
                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.filtersToFirstSection)) {
                            FilterBar(catalog = catalog, selected = filter, onSelect = onFilter)
                            if (grouped.isNotEmpty()) {
                                Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                                    SectionHeader(
                                        title = stringResource(R.string.section_continue_reading),
                                        action = stringResource(R.string.action_see_all),
                                        onAction = { onFilter(LibraryFilter.readingHistory) },
                                        modifier = Modifier.padding(horizontal = horizontal),
                                    )
                                    ContinueReadingShelf(grouped.take(10), catalog, onOpenWork = { progress ->
                                        val author = catalog.authors.firstOrNull { it.full == progress.author }
                                        onOpenWork(author ?: catalog.authors.first(), Work(progress.title, progress.path, readingID = progress.workId))
                                    })
                                }
                            } else if (featured != null) {
                                Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                                    SectionHeader(
                                        title = stringResource(R.string.section_start_here),
                                        modifier = Modifier.padding(horizontal = horizontal),
                                    )
                                    FeaturedCard(
                                        title = featured.second.title,
                                        credit = featured.first.full,
                                        onClick = { onOpenWork(featured.first, featured.second) },
                                        modifier = Modifier.padding(horizontal = horizontal),
                                    )
                                }
                            }
                        }
                    }

                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                            SectionHeader(
                                title = stringResource(R.string.section_popular_writers),
                                action = stringResource(R.string.action_see_all),
                                onAction = { onFilter(LibraryFilter.writers) },
                                modifier = Modifier.padding(horizontal = horizontal),
                            )
                            LazyRow(
                                contentPadding = PaddingValues(horizontal = horizontal),
                                horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
                            ) {
                                items(popularWriters, key = { it.id }) { author ->
                                    WriterCard(author, onClick = { onOpenAuthor(author) })
                                }
                            }
                        }
                    }

                    if (savedWorks.isNotEmpty()) {
                        item {
                            Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                                SectionHeader(
                                    title = stringResource(R.string.section_saved),
                                    action = stringResource(R.string.action_see_all),
                                    onAction = { onFilter(LibraryFilter.saved) },
                                    modifier = Modifier.padding(horizontal = horizontal),
                                )
                                WorkList(savedWorks.take(4), onOpenWork = onOpenWork)
                            }
                        }
                    }

                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                            SectionHeader(
                                title = stringResource(R.string.section_library),
                                action = stringResource(R.string.action_see_all),
                                onAction = { onFilter(LibraryFilter.works) },
                                modifier = Modifier.padding(horizontal = horizontal),
                            )
                            WorkList(popularWorks.take(8), onOpenWork = onOpenWork)
                        }
                    }
                }

                LibraryFilter.writers -> item { FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_writers)) { WriterList(catalog.authors, onOpenAuthor) } }
                LibraryFilter.works -> item {
                    FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_works)) {
                    WorkList(
                        catalog.authors.flatMap { author -> author.works.map { author to it } },
                        onOpenWork = onOpenWork,
                    )
                    }
                }
                LibraryFilter.topics -> item { FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_topics)) { CollectionList(catalog.themes, onOpenCollection) } }
                LibraryFilter.history -> item { FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_history)) { CollectionList(catalog.history, onOpenCollection) } }
                LibraryFilter.saved -> item {
                    FilteredSection(catalog, filter, onFilter, if (savedWorks.isEmpty()) null else stringResource(R.string.filter_saved)) {
                    if (savedWorks.isEmpty()) {
                        EmptyContent(stringResource(R.string.empty_saved), stringResource(R.string.empty_saved_body))
                    } else {
                        WorkList(savedWorks, onOpenWork = onOpenWork)
                    }
                    }
                }
                LibraryFilter.readingHistory -> item {
                    FilteredSection(catalog, filter, onFilter, if (grouped.isEmpty()) null else stringResource(R.string.filter_reading_history)) {
                    if (grouped.isEmpty()) {
                        EmptyContent(stringResource(R.string.empty_history), stringResource(R.string.empty_history_body))
                    } else {
                        ReadingList(grouped, onOpenWork = { progress ->
                            val author = catalog.authors.firstOrNull { it.full == progress.author }
                            onOpenWork(author ?: catalog.authors.first(), Work(progress.title, progress.path, readingID = progress.workId))
                        })
                    }
                    }
                }
            }

            if (filter == LibraryFilter.all) {
                if (grouped.isNotEmpty()) {
                    item { StatsCard(onClick = onOpenStats) }
                }
                item { Footer(onOpenSupport = onOpenSupport, onOpenFeedback = onOpenFeedback, onOpenPrivacy = onOpenPrivacy) }
            }
            item { CatalogFooter(catalog.generated) }
        }
    }
}

@Composable
private fun FilteredSection(catalog: Catalog, filter: LibraryFilter, onFilter: (LibraryFilter) -> Unit, title: String?, content: @Composable () -> Unit) {
    Column {
        FilterBar(catalog = catalog, selected = filter, onSelect = onFilter)
        if (title != null) {
            Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                SectionHeader(title = title, modifier = Modifier.padding(horizontal = horizontal))
                content()
            }
        } else {
            content()
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
            .padding(top = Tokens.Spacing.s3),
    ) {
        Text(
            text = stringResource(R.string.library_title),
            style = MaterialTheme.typography.headlineLarge.copy(
                fontFamily = PraxisFonts.Heading,
                fontSize = 34.sp,
                lineHeight = 50.sp,
                fontWeight = FontWeight.Medium,
                letterSpacing = (-0.5).sp,
            ),
            color = Praxis.colors.textPrimary,
        )
        Spacer(Modifier.height(Tokens.Spacing.s1))
        Text(
            text = stringResource(R.string.library_subtitle),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun FilterBar(catalog: Catalog, selected: LibraryFilter, onSelect: (LibraryFilter) -> Unit) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = horizontal),
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
private fun FeaturedCard(title: String, credit: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Praxis.colors.surface)
            .border(1.dp, Praxis.colors.separator, shape)
            .clickable(onClick = onClick)
            .padding(Tokens.Spacing.s4),
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
    ) {
        BookCover(
            title = title,
            modifier = Modifier.width(76.dp).height(104.dp),
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.title3,
                color = Praxis.colors.textPrimary,
                maxLines = 2,
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
                fontWeight = FontWeight.SemiBold,
                color = Praxis.colors.accent,
            )
        }
    }
}

@Composable
private fun ContinueReadingShelf(readings: List<ReadingProgress>, catalog: Catalog, onOpenWork: (ReadingProgress) -> Unit) {
    if (readings.size == 1) {
        ContinueReadingCard(
            progress = readings.first(),
            catalog = catalog,
            onOpenWork = onOpenWork,
            modifier = Modifier.padding(horizontal = horizontal).fillMaxWidth(),
            barModifier = Modifier.width(160.dp).height(3.dp),
        )
    } else {
        LazyRow(
            contentPadding = PaddingValues(horizontal = horizontal),
            horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
        ) {
            items(readings, key = { it.id }) { progress ->
                ContinueReadingCard(
                    progress = progress,
                    catalog = catalog,
                    onOpenWork = onOpenWork,
                    modifier = Modifier.width(264.dp),
                    barModifier = Modifier.fillMaxWidth().height(3.dp),
                )
            }
        }
    }
}

@Composable
private fun ContinueReadingCard(
    progress: ReadingProgress,
    catalog: Catalog,
    onOpenWork: (ReadingProgress) -> Unit,
    modifier: Modifier = Modifier,
    barModifier: Modifier = Modifier,
) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Row(
        modifier = modifier
            .clip(shape)
            .background(Praxis.colors.surface)
            .border(1.dp, Praxis.colors.separator, shape)
            .clickable { onOpenWork(progress) }
            .padding(Tokens.Spacing.s3),
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
    ) {
        BookCover(title = progress.title, modifier = Modifier.width(64.dp).height(86.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = progress.title,
                style = MaterialTheme.typography.titleSmall,
                color = Praxis.colors.textPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            val credit = progress.author.ifEmpty {
                catalog.authors.firstOrNull { author -> author.works.any { it.path == progress.path } }?.full.orEmpty()
            }
            if (credit.isNotEmpty()) {
                Spacer(Modifier.height(Tokens.Spacing.s1))
                Text(
                    text = credit,
                    style = MaterialTheme.typography.caption,
                    color = Praxis.colors.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Spacer(Modifier.height(Tokens.Spacing.s2))
            ProgressBar(
                fraction = progress.progress.toFloat().coerceIn(0f, 1f),
                modifier = barModifier,
            )
            Spacer(Modifier.height(Tokens.Spacing.s1))
            Text(
                text = stringResource(R.string.progress_in_section, (progress.progress * 100).toInt()),
                style = MaterialTheme.typography.caption,
                color = Praxis.colors.textSecondary,
            )
        }
    }
}

@Composable
private fun ProgressBar(fraction: Float, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(Tokens.Radius.full)
    Box(
        modifier = modifier
            .clip(shape)
            .background(Praxis.colors.separator),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(fraction.coerceIn(0f, 1f))
                .height(3.dp)
                .clip(shape)
                .background(Praxis.colors.accent),
        )
    }
}

@Composable
private fun WriterCard(author: Author, onClick: () -> Unit) {
    Column(modifier = Modifier.width(126.dp).clickable(onClick = onClick)) {
        AuthorArtwork(
            name = author.full,
            modifier = Modifier.fillMaxWidth().height(116.dp),
            imageUrl = Portraits.url(author, Language.pt),
            focalAlignment = if (author.id == "engels") Alignment.TopCenter else Alignment.Center,
        )
        Spacer(Modifier.height(Tokens.Spacing.s2))
        Text(
            text = author.full,
            style = MaterialTheme.typography.bodyLarge.copy(fontFamily = PraxisFonts.Heading),
            fontWeight = FontWeight.SemiBold,
            color = Praxis.colors.textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Spacer(Modifier.height(Tokens.Spacing.s1))
        Text(
            text = workCountLabel(author.works.size),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun WriterList(authors: List<Author>, onOpenAuthor: (Author) -> Unit) {
    Column(modifier = Modifier.padding(horizontal = horizontal)) {
        authors.forEachIndexed { index, author ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onOpenAuthor(author) }
                    .padding(top = if (index == 0) 0.dp else Tokens.Spacing.s2, bottom = Tokens.Spacing.s2),
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
                        style = MaterialTheme.typography.titleSmall.copy(fontFamily = PraxisFonts.Heading),
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
private fun WorkList(works: List<Pair<Author, Work>>, onOpenWork: (Author, Work) -> Unit) {
    Column(modifier = Modifier.padding(horizontal = horizontal)) {
        works.forEachIndexed { index, (author, work) ->
            WorkRow(
                work = work,
                author = author.full,
                onClick = { onOpenWork(author, work) },
                topPadding = if (index == 0) 0.dp else Tokens.Spacing.s3,
            )
            if (index < works.lastIndex) InsetDivider(startPadding = 68.dp)
        }
    }
}

@Composable
private fun ReadingList(readings: List<ReadingProgress>, onOpenWork: (ReadingProgress) -> Unit) {
    Column(modifier = Modifier.padding(horizontal = horizontal)) {
        readings.forEachIndexed { index, progress ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onOpenWork(progress) }
                    .padding(top = if (index == 0) 0.dp else Tokens.Spacing.s3, bottom = Tokens.Spacing.s3),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
            ) {
                BookCover(title = progress.title, modifier = Modifier.width(50.dp).height(68.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = progress.title,
                        style = MaterialTheme.typography.titleSmall,
                        color = Praxis.colors.textPrimary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    if (progress.author.isNotEmpty()) {
                        Text(
                            text = progress.author,
                            style = MaterialTheme.typography.bodyMedium,
                            color = Praxis.colors.textSecondary,
                        )
                    }
                    Text(
                        text = stringResource(R.string.progress_in_section, (progress.progress * 100).toInt()),
                        style = MaterialTheme.typography.caption,
                        color = Praxis.colors.textSecondary,
                    )
                }
                Chevron()
            }
            if (index < readings.lastIndex) InsetDivider(startPadding = 68.dp)
        }
    }
}

@Composable
private fun WorkRow(work: Work, author: String, onClick: () -> Unit, topPadding: Dp = Tokens.Spacing.s3) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(top = topPadding, bottom = Tokens.Spacing.s3),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
    ) {
        BookCover(title = work.title, modifier = Modifier.width(50.dp).height(68.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = work.title,
                style = MaterialTheme.typography.titleSmall.copy(fontFamily = PraxisFonts.Heading),
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
                    style = MaterialTheme.typography.caption,
                    color = Praxis.colors.textSecondary,
                )
            }
        }
        Chevron()
    }
}

@Composable
private fun CollectionList(collections: List<CatalogCollection>, onOpen: (CatalogCollection) -> Unit) {
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
                    .clickable { onOpen(collection) }
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
private fun StatsCard(onClick: () -> Unit) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Row(
        modifier = Modifier
            .padding(horizontal = horizontal)
            .fillMaxWidth()
            .clip(shape)
            .background(Praxis.colors.surface)
            .border(1.dp, Praxis.colors.separator, shape)
            .clickable(onClick = onClick)
            .padding(Tokens.Spacing.s4),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(13.dp),
    ) {
        Icon(
            imageVector = Icons.Filled.BarChart,
            contentDescription = null,
            tint = Praxis.colors.accent,
            modifier = Modifier.size(22.dp),
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
        ) {
            Text(
                text = stringResource(R.string.stats_card_title),
                style = MaterialTheme.typography.titleSmall,
                color = Praxis.colors.textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = stringResource(R.string.stats_card_subtitle),
                style = MaterialTheme.typography.bodyMedium,
                color = Praxis.colors.textSecondary,
            )
        }
        Chevron()
    }
}

@Composable
private fun Footer(onOpenSupport: () -> Unit, onOpenFeedback: () -> Unit, onOpenPrivacy: () -> Unit) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Column(
        modifier = Modifier.padding(horizontal = horizontal),
        verticalArrangement = Arrangement.spacedBy(LibrarySpacing.sections),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(shape)
                .background(Praxis.colors.surface)
                .border(1.dp, Praxis.colors.separator, shape)
                .clickable(onClick = onOpenSupport)
                .padding(Tokens.Spacing.s4),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
        ) {
            Icon(
                imageVector = Icons.Filled.Favorite,
                contentDescription = null,
                tint = Praxis.colors.accent,
                modifier = Modifier.size(22.dp),
            )
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = stringResource(R.string.footer_support),
                    style = MaterialTheme.typography.titleSmall,
                    color = Praxis.colors.textPrimary,
                )
                Text(
                    text = stringResource(R.string.footer_support_body),
                    style = MaterialTheme.typography.bodyMedium,
                    color = Praxis.colors.textSecondary,
                )
            }
            Chevron()
        }
        if (runCatching { java.net.URI(BuildConfig.FEEDBACK_URL) }.getOrNull()?.let { it.scheme == "https" && !it.host.isNullOrBlank() } == true) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(shape)
                .background(Praxis.colors.surface)
                .border(1.dp, Praxis.colors.separator, shape)
                .clickable(onClick = onOpenFeedback)
                .padding(Tokens.Spacing.s4),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
        ) {
            Icon(
                imageVector = Icons.Outlined.ChatBubbleOutline,
                contentDescription = null,
                tint = Praxis.colors.accent,
                modifier = Modifier.size(22.dp),
            )
            Column(modifier = Modifier.weight(1f)) {
                Text(text = stringResource(R.string.feedback_title), style = MaterialTheme.typography.titleSmall, color = Praxis.colors.textPrimary)
                Text(text = stringResource(R.string.feedback_card_body), style = MaterialTheme.typography.bodyMedium, color = Praxis.colors.textSecondary)
            }
            Chevron()
        }
        }
        Text(
            text = stringResource(R.string.footer_privacy),
            style = MaterialTheme.typography.labelMedium,
            color = Praxis.colors.textSecondary,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .clickable(onClick = onOpenPrivacy)
                .padding(vertical = Tokens.Spacing.s3),
        )
    }
}

@Composable
private fun EmptyContent(title: String, body: String?) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = horizontal, vertical = Tokens.Spacing.s8),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = title, style = MaterialTheme.typography.title3, color = Praxis.colors.textPrimary)
        if (body != null) {
            Spacer(Modifier.height(Tokens.Spacing.s1))
            Text(text = body, style = MaterialTheme.typography.bodyMedium, color = Praxis.colors.textSecondary)
        }
    }
}

@Composable
private fun CenteredMessage(text: String) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text = text, style = MaterialTheme.typography.titleSmall, color = Praxis.colors.textSecondary)
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
        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = horizontal, vertical = Tokens.Spacing.s3),
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

private fun LazyListScope.searchResults(
    catalog: Catalog,
    query: String,
    filter: LibraryFilter,
    onFilter: (LibraryFilter) -> Unit,
    onOpenWork: (Author, Work) -> Unit,
    onOpenAuthor: (Author) -> Unit,
    onOpenCollection: (CatalogCollection) -> Unit,
) {
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
            FilteredSection(catalog, filter, onFilter, null) {
                EmptyContent(stringResource(R.string.empty_results), stringResource(R.string.empty_results_body))
            }
        }
        return
    }
    if (authors.isNotEmpty()) {
        item {
            FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_writers)) { WriterList(authors, onOpenAuthor) }
        }
    }
    if (works.isNotEmpty()) {
        item {
            if (authors.isEmpty()) {
                FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_works)) { WorkList(works, onOpenWork) }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                    SectionHeader(title = stringResource(R.string.filter_works), modifier = Modifier.padding(horizontal = horizontal))
                    WorkList(works, onOpenWork)
                }
            }
        }
    }
    if (themes.isNotEmpty()) {
        item {
            if (authors.isEmpty() && works.isEmpty()) {
                FilteredSection(catalog, filter, onFilter, stringResource(R.string.filter_topics)) { CollectionList(themes, onOpenCollection) }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(LibrarySpacing.headingToContent)) {
                    SectionHeader(title = stringResource(R.string.filter_topics), modifier = Modifier.padding(horizontal = horizontal))
                    CollectionList(themes, onOpenCollection)
                }
            }
        }
    }
}

@Composable
private fun workCountLabel(count: Int): String = if (count == 1) {
    stringResource(R.string.work_count_one, count)
} else {
    stringResource(R.string.work_count, count)
}
