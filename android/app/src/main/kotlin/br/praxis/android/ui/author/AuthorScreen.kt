package br.praxis.android.ui.author

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Public
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.praxis.android.AppGraph
import br.praxis.android.R
import br.praxis.android.data.Author
import br.praxis.android.data.Catalog
import br.praxis.android.data.Language
import br.praxis.android.data.Portraits
import br.praxis.android.data.Work
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.AuthorArtwork
import br.praxis.android.design.components.Chevron
import br.praxis.android.design.components.InsetDivider

/** Author profile, mirroring AuthorView: portrait card, biography and the works by section. */
@Composable
fun AuthorScreen(
    authorId: String,
    onBack: () -> Unit,
    onOpenWork: (Author, Work) -> Unit,
    onOpenArchiveLink: (String, String) -> Unit,
) {
    var catalog by remember { mutableStateOf<Catalog?>(null) }
    var expanded by remember { mutableStateOf(false) }

    LaunchedEffect(authorId) {
        catalog = runCatching { AppGraph.repository.load(Language.pt) }.getOrNull()
    }

    val author = catalog?.authors?.firstOrNull { it.id == authorId }

    Column(modifier = Modifier.fillMaxSize().background(Praxis.colors.background)) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = Tokens.Spacing.s1, vertical = Tokens.Spacing.s1),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.reader_back),
                    tint = Praxis.colors.textPrimary,
                )
            }
            Text(
                text = author?.name ?: "",
                style = MaterialTheme.typography.titleSmall,
                color = Praxis.colors.textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
        }

        when {
            catalog == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Praxis.colors.accent)
            }
            author == null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = stringResource(R.string.empty_results),
                    style = MaterialTheme.typography.bodyLarge,
                    color = Praxis.colors.textSecondary,
                )
            }
            else -> AuthorContent(
                author,
                expanded,
                onToggleExpanded = { expanded = !expanded },
                onOpenWork = onOpenWork,
                onOpenArchiveLink = onOpenArchiveLink,
            )
        }
    }
}

@Composable
private fun AuthorContent(
    author: Author,
    expanded: Boolean,
    onToggleExpanded: () -> Unit,
    onOpenWork: (Author, Work) -> Unit,
    onOpenArchiveLink: (String, String) -> Unit,
) {
    val biographyTitle = stringResource(R.string.author_biography)
    LazyColumn(modifier = Modifier.fillMaxSize()) {
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Tokens.Spacing.s5)
                    .padding(top = Tokens.Spacing.s3),
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.Top) {
                    AuthorArtwork(
                        name = author.full,
                        modifier = Modifier.size(92.dp, 112.dp),
                        imageUrl = Portraits.url(author, Language.pt),
                        focalAlignment = if (author.id == "engels") Alignment.TopCenter else Alignment.Center,
                    )
                    Column {
                        Text(
                            text = author.full,
                            style = MaterialTheme.typography.titleLarge,
                            color = Praxis.colors.textPrimary,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis,
                        )
                        if (author.displayDates.isNotEmpty()) {
                            Text(
                                text = author.displayDates,
                                style = MaterialTheme.typography.bodyMedium,
                                color = Praxis.colors.textSecondary,
                            )
                        }
                        if (author.country.isNotEmpty()) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Public,
                                    contentDescription = null,
                                    tint = Praxis.colors.textSecondary,
                                    modifier = Modifier.size(16.dp),
                                )
                                Text(
                                    text = author.country,
                                    style = MaterialTheme.typography.labelMedium,
                                    color = Praxis.colors.textSecondary,
                                )
                            }
                        }
                        author.groups.forEach { group ->
                            Text(
                                text = group,
                                style = MaterialTheme.typography.labelMedium,
                                color = Praxis.colors.accent,
                            )
                        }
                    }
                }
                if (author.bio.isNotEmpty()) {
                    Spacer(Modifier.height(Tokens.Spacing.s4))
                    InsetDivider(startPadding = 0.dp)
                    Spacer(Modifier.height(Tokens.Spacing.s3))
                    Text(
                        text = author.bio,
                        style = MaterialTheme.typography.bodyLarge,
                        color = Praxis.colors.textPrimary,
                        maxLines = if (expanded) Int.MAX_VALUE else 5,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        text = stringResource(if (expanded) R.string.author_read_less else R.string.author_read_more),
                        style = MaterialTheme.typography.bodyLarge,
                        color = Praxis.colors.accent,
                        modifier = Modifier
                            .padding(top = Tokens.Spacing.s1)
                            .clickable(onClick = onToggleExpanded),
                    )
                }
                author.bioPath?.takeIf { it.isNotEmpty() }?.let { bioPath ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onOpenArchiveLink(bioPath, biographyTitle) }
                            .padding(top = Tokens.Spacing.s3),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = stringResource(R.string.author_biography),
                            style = MaterialTheme.typography.bodyLarge,
                            color = Praxis.colors.accent,
                            modifier = Modifier.weight(1f),
                        )
                        Chevron()
                    }
                }
            }
        }

        val sections = author.sections.ifEmpty { listOf("") }
        sections.forEachIndexed { index, section ->
            val works = author.works.filter { it.section == index }
            if (works.isEmpty()) return@forEachIndexed
            item(key = "header-$index") {
                Text(
                    text = section.ifEmpty { stringResource(R.string.author_works) }.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = Praxis.colors.textSecondary,
                    modifier = Modifier.padding(
                        start = Tokens.Spacing.s5,
                        end = Tokens.Spacing.s5,
                        top = Tokens.Spacing.s6,
                        bottom = Tokens.Spacing.s2,
                    ),
                )
            }
            items(works, key = { it.path }) { work ->
                WorkEntry(work = work, onClick = { onOpenWork(author, work) })
                InsetDivider(startPadding = Tokens.Spacing.s5)
            }
        }
    }
}

@Composable
private fun WorkEntry(work: Work, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Tokens.Spacing.s5, vertical = Tokens.Spacing.s3),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = work.title,
                style = MaterialTheme.typography.bodyLarge,
                color = Praxis.colors.textPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            if (work.date.isNotEmpty()) {
                Text(
                    text = work.date,
                    style = MaterialTheme.typography.labelMedium,
                    color = Praxis.colors.textSecondary,
                    fontSize = 13.sp,
                )
            }
        }
        Chevron()
    }
}
