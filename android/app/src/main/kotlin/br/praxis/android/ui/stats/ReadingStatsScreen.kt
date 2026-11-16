package br.praxis.android.ui.stats

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.praxis.android.AppGraph
import br.praxis.android.R
import br.praxis.android.data.Catalog
import br.praxis.android.data.Language
import br.praxis.android.data.ReadingHistory
import br.praxis.android.data.ReadingProgress
import br.praxis.android.data.ReadingStats
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.InsetDivider

@Composable
fun ReadingStatsScreen(onBack: () -> Unit) {
    val preferences = AppGraph.preferences
    val readings by preferences.recentReadings.collectAsStateWithLifecycle(initialValue = emptyList())
    val savedPaths by preferences.savedWorkPaths.collectAsStateWithLifecycle(initialValue = emptyList())
    val readingDays by preferences.readingDays.collectAsStateWithLifecycle(initialValue = emptyList())
    val finishedIds by preferences.finishedWorkIDs.collectAsStateWithLifecycle(initialValue = emptyList())

    var catalog by remember { mutableStateOf<Catalog?>(null) }
    LaunchedEffect(Unit) {
        catalog = runCatching { AppGraph.repository.load(Language.pt) }.getOrNull()
    }

    Column(modifier = Modifier.fillMaxSize().background(Praxis.colors.background)) {
        TopBar(title = stringResource(R.string.stats_title), onBack = onBack)
        val loaded = catalog
        if (loaded == null) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Praxis.colors.accent)
            }
        } else {
            StatsBody(
                catalog = loaded,
                readings = readings,
                savedPaths = savedPaths,
                readingDays = readingDays,
                finishedIds = finishedIds,
            )
        }
    }
}

@Composable
private fun TopBar(title: String, onBack: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxWidth().statusBarsPadding().height(56.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.SemiBold),
            color = Praxis.colors.textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 64.dp),
        )
        IconButton(onClick = onBack, modifier = Modifier.align(Alignment.CenterStart).padding(start = Tokens.Spacing.s1)) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = stringResource(R.string.action_back),
                tint = Praxis.colors.textPrimary,
            )
        }
    }
}

@Composable
private fun StatsBody(
    catalog: Catalog,
    readings: List<ReadingProgress>,
    savedPaths: List<String>,
    readingDays: List<String>,
    finishedIds: List<String>,
) {
    val grouped = remember(readings, catalog) { ReadingHistory.grouped(readings, catalog.workKeys) }
    val days = remember(readingDays) { readingDays.toSet() }
    val streak = remember(days) { ReadingStats.currentStreak(days, ReadingStats.today()) }
    val buckets = remember(days) { ReadingStats.weekBucketCounts(days, ReadingStats.today()) }

    val authorsByPath = remember(catalog) {
        catalog.authors.flatMap { author -> author.works.map { it.path to author.full } }.toMap()
    }
    val mostRead = remember(grouped, authorsByPath) {
        grouped
            .mapNotNull { entry -> (authorsByPath[entry.path] ?: entry.author).trim().takeIf { it.isNotEmpty() } }
            .groupingBy { it }
            .eachCount()
            .entries
            .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
            .take(5)
    }

    if (grouped.isEmpty()) {
        EmptyStats()
        return
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize().navigationBarsPadding(),
        contentPadding = PaddingValues(horizontal = Tokens.Spacing.s5, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s6),
    ) {
        item { Hero(streak = streak) }
        item {
            StatGrid(
                finished = finishedIds.size,
                read = grouped.size,
                days = days.size,
                saved = savedPaths.size,
            )
        }
        item { ActivitySection(counts = buckets) }
        if (mostRead.isNotEmpty()) {
            item { AuthorsSection(entries = mostRead) }
        }
    }
}

@Composable
private fun Hero(streak: Int) {
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1)) {
        Text(
            text = streak.toString(),
            style = MaterialTheme.typography.displayLarge.copy(
                fontSize = 64.sp,
                lineHeight = 72.sp,
                fontWeight = FontWeight.Medium,
            ),
            color = Praxis.colors.textPrimary,
        )
        Text(
            text = pluralStringResource(R.plurals.stats_streak_label, streak),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
        Text(
            text = stringResource(R.string.stats_streak_caption),
            style = MaterialTheme.typography.labelMedium,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun StatGrid(finished: Int, read: Int, days: Int, saved: Int) {
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3)) {
        Row(horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3)) {
            StatTile(stringResource(R.string.stats_tile_finished), finished.toString(), Modifier.weight(1f))
            StatTile(stringResource(R.string.stats_tile_read), read.toString(), Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3)) {
            StatTile(stringResource(R.string.stats_tile_days), days.toString(), Modifier.weight(1f))
            StatTile(stringResource(R.string.stats_tile_saved), saved.toString(), Modifier.weight(1f))
        }
    }
}

@Composable
private fun StatTile(label: String, value: String, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Column(
        modifier = modifier
            .clip(shape)
            .background(Praxis.colors.surface)
            .border(1.dp, Praxis.colors.separator, shape)
            .padding(Tokens.Spacing.s4),
        verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge.copy(fontSize = 28.sp, lineHeight = 42.sp),
            color = Praxis.colors.textPrimary,
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Normal, letterSpacing = 0.sp),
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun ActivitySection(counts: List<Int>) {
    val description = stringResource(R.string.stats_activity_accessibility, counts.joinToString(", "))
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2)) {
        SectionHeading(stringResource(R.string.stats_section_activity))
        Row(
            modifier = Modifier.fillMaxWidth().height(72.dp).semantics(mergeDescendants = true) { contentDescription = description },
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            counts.forEach { count ->
                Box(
                    modifier = Modifier
                        .width(14.dp)
                        .height((if (count == 0) 2 else count * 9).dp)
                        .background(if (count == 0) Praxis.colors.separator else Praxis.colors.accent),
                )
            }
        }
        Text(
            text = stringResource(R.string.stats_activity_caption),
            style = MaterialTheme.typography.labelMedium,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun AuthorsSection(entries: List<Map.Entry<String, Int>>) {
    Column {
        SectionHeading(stringResource(R.string.stats_section_authors))
        entries.forEachIndexed { index, (name, count) ->
            Row(
                modifier = Modifier.fillMaxWidth().padding(vertical = Tokens.Spacing.s2),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = name,
                    style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Medium),
                    color = Praxis.colors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = if (count == 1) "1 texto" else stringResource(R.string.work_count, count),
                    style = MaterialTheme.typography.bodyMedium,
                    color = Praxis.colors.textSecondary,
                )
            }
            if (index < entries.lastIndex) InsetDivider()
        }
    }
}

@Composable
private fun SectionHeading(title: String) {
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.bodyMedium.copy(
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.8.sp,
        ),
        color = Praxis.colors.textSecondary,
    )
}

@Composable
private fun EmptyStats() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Tokens.Spacing.s5, vertical = 18.dp)
            .clip(RoundedCornerShape(Tokens.Radius.xl))
            .background(Praxis.colors.surface)
            .padding(Tokens.Spacing.s5),
        verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2),
    ) {
        Icon(
            imageVector = Icons.Filled.BarChart,
            contentDescription = null,
            tint = Praxis.colors.accent,
            modifier = Modifier.size(28.dp),
        )
        Text(
            text = stringResource(R.string.stats_empty_title),
            style = MaterialTheme.typography.titleLarge.copy(fontSize = 20.sp, lineHeight = 30.sp),
            color = Praxis.colors.textPrimary,
        )
        Text(
            text = stringResource(R.string.stats_empty_body),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
    }
}
