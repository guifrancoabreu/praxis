package br.praxis.android.ui.collection

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
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
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import br.praxis.android.AppGraph
import br.praxis.android.R
import br.praxis.android.data.CatalogCollection
import br.praxis.android.data.CatalogItem
import br.praxis.android.data.Language
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.Chevron
import br.praxis.android.design.components.InsetDivider

/** A themed collection of texts, mirroring CollectionDetailView. */
@Composable
fun CollectionScreen(
    collectionId: String,
    onBack: () -> Unit,
    onOpenItem: (CatalogItem) -> Unit,
) {
    var collection by remember { mutableStateOf<CatalogCollection?>(null) }
    LaunchedEffect(collectionId) {
        val catalog = runCatching { AppGraph.repository.load(Language.pt) }.getOrNull()
        collection = (catalog?.themes.orEmpty() + catalog?.history.orEmpty()).firstOrNull { it.id == collectionId || it.title == collectionId }
    }
    val loaded = collection
    if (loaded == null) {
        Box(Modifier.fillMaxSize().background(Praxis.colors.background), contentAlignment = Alignment.Center) {
            androidx.compose.material3.CircularProgressIndicator(color = Praxis.colors.accent)
        }
        return
    }
    CollectionContent(loaded, onBack, onOpenItem)
}

@Composable
private fun CollectionContent(
    collection: CatalogCollection,
    onBack: () -> Unit,
    onOpenItem: (CatalogItem) -> Unit,
) {
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
                text = collection.title,
                style = MaterialTheme.typography.titleSmall,
                color = Praxis.colors.textPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
        }

        val groups = collection.groups.filter { it.items.isNotEmpty() }
        if (groups.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(
                    text = stringResource(R.string.collection_open_in_archive),
                    style = MaterialTheme.typography.bodyLarge,
                    color = Praxis.colors.accent,
                    modifier = Modifier
                        .clickable { onOpenItem(CatalogItem(collection.title, collection.id)) }
                        .padding(Tokens.Spacing.s4),
                )
            }
            return
        }

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            groups.forEach { group ->
                item(key = "group-${group.name}-${group.items.first().path}") {
                    Text(
                        text = group.name.ifEmpty { collection.title },
                        style = MaterialTheme.typography.titleSmall,
                        color = Praxis.colors.textPrimary,
                        modifier = Modifier.padding(
                            start = Tokens.Spacing.s5,
                            end = Tokens.Spacing.s5,
                            top = Tokens.Spacing.s4,
                            bottom = Tokens.Spacing.s1,
                        ),
                    )
                }
                items(group.items, key = { it.path }) { item ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onOpenItem(item) }
                            .heightIn(min = 44.dp)
                            .padding(horizontal = Tokens.Spacing.s5, vertical = Tokens.Spacing.s2),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2),
                    ) {
                        Text(
                            text = item.title,
                            style = MaterialTheme.typography.bodyLarge,
                            fontFamily = FontFamily.Serif,
                            color = Praxis.colors.textPrimary,
                            modifier = Modifier.weight(1f),
                        )
                        Chevron()
                    }
                    InsetDivider(startPadding = Tokens.Spacing.s5)
                }
            }
        }
    }
}

