package br.praxis.android.ui.reader

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.praxis.android.R
import br.praxis.android.data.Analytics
import br.praxis.android.data.HtmlSanitizer
import br.praxis.android.data.Language
import br.praxis.android.data.PageStore
import br.praxis.android.data.PraxisPreferences
import br.praxis.android.data.ReaderAppearance
import br.praxis.android.data.ReaderScripts
import br.praxis.android.data.ReadingProgress
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.GlassSurface
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private val progressSaveScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

@Composable
fun ReaderScreen(
    workPath: String,
    title: String,
    author: String,
    workId: String?,
    onBack: () -> Unit,
    onOpenArchiveLink: (String, String) -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val preferences = remember { PraxisPreferences(context.applicationContext) }
    val pageStore = remember { PageStore(context.applicationContext) }
    val readings by preferences.recentReadings.collectAsStateWithLifecycle<List<ReadingProgress>?>(initialValue = null)
    val appearance by preferences.readerAppearance.collectAsStateWithLifecycle(initialValue = ReaderAppearance())
    val savedPaths by preferences.savedWorkPaths.collectAsStateWithLifecycle(initialValue = emptyList())
    val baseUrl = Language.pt.base
    val sourceUrl = remember(workPath) { runCatching { java.net.URI(baseUrl).resolve(workPath).toString() }.getOrDefault(baseUrl + workPath) }
    val isPdf = sourceUrl.substringBefore('#').endsWith(".pdf", ignoreCase = true)

    var html by remember { mutableStateOf<String?>(null) }
    var pdfBytes by remember { mutableStateOf<ByteArray?>(null) }
    var failed by remember { mutableStateOf(false) }
    var showAppearance by remember { mutableStateOf(false) }
    var pendingProgress by remember { mutableStateOf<Double?>(null) }
    val initialProgress = remember(readings) {
        readings?.firstOrNull { it.path == workPath || (workId != null && it.workId == workId) }?.progress ?: 0.0
    }

    val isSaved = savedPaths.contains(workPath)

    LaunchedEffect(workPath, sourceUrl) {
        failed = false
        runCatching {
            if (isPdf) {
                pdfBytes = pageStore.loadPdf(sourceUrl)
            } else {
                val raw = pageStore.loadHtml(sourceUrl)
                html = HtmlSanitizer.sanitize(raw, sourceUrl)
            }
        }.onFailure { failed = true }
        Analytics.track(Analytics.Event.WorkOpened)
    }

    // Progress is written once the reader settles, like the 5 s debounce on iOS.
    LaunchedEffect(pendingProgress) {
        val value = pendingProgress ?: return@LaunchedEffect
        delay(5_000)
        preferences.recordReading(ReadingProgress(workPath, title, author, value, workId))
    }

    fun flush(progress: Double?) {
        if (progress == null) return
        progressSaveScope.launch { preferences.recordReading(ReadingProgress(workPath, title, author, progress, workId)) }
    }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_STOP) flush(pendingProgress)
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            flush(pendingProgress)
        }
    }

    Column(modifier = Modifier.fillMaxSize().background(Praxis.colors.background)) {
        ReaderToolbar(
            title = title,
            isSaved = isSaved,
            showAppearance = !isPdf,
            onBack = { flush(pendingProgress); onBack() },
            onToggleSaved = {
                scope.launch {
                    val saved = preferences.toggleSaved(workPath)
                    Analytics.track(Analytics.Event.BookmarkChanged(saved))
                }
            },
            onAppearance = {
                showAppearance = true
                Analytics.track(Analytics.Event.ReaderAppearanceOpened)
            },
            onOpenSource = {
                Analytics.track(Analytics.Event.ArchiveSourceOpened)
                runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(sourceUrl))) }
            },
        )

        Box(modifier = Modifier.fillMaxSize()) {
            when {
                failed -> ReaderMessage(stringResource(R.string.reader_error), stringResource(R.string.reader_error_body))
                readings == null -> Loading()
                isPdf -> {
                    val bytes = pdfBytes
                    if (bytes == null) Loading() else PdfPages(
                        bytes = bytes,
                        initialProgress = initialProgress,
                        onProgress = { progress -> pendingProgress = progress },
                        onFailure = { failed = true },
                    )
                }
                else -> {
                    val content = html
                    if (content == null) {
                        Loading()
                    } else {
                        ReaderWebView(
                            html = content,
                            sourceUrl = sourceUrl,
                            appearance = appearance,
                            initialProgress = initialProgress,
                            onProgress = { pendingProgress = it },
                            onLink = { url, linkTitle ->
                                val uri = Uri.parse(url)
                                if (uri.scheme in listOf("http", "https") &&
                                    uri.host?.lowercase() in listOf("marxists.org", "www.marxists.org")) {
                                    flush(pendingProgress)
                                    onOpenArchiveLink(url, linkTitle.ifBlank { uri.lastPathSegment.orEmpty() })
                                } else if (uri.scheme in listOf("http", "https")) {
                                    openLink(context, url)
                                }
                            },
                        )
                    }
                }
            }
        }
    }

    if (showAppearance) {
        ReaderAppearanceSheet(
            appearance = appearance,
            onChange = { updated -> scope.launch { preferences.setReaderAppearance(updated) } },
            onDismiss = { showAppearance = false },
        )
    }
}

private fun openLink(context: android.content.Context, url: String) {
    runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
}

@Composable
private fun ReaderToolbar(
    title: String,
    isSaved: Boolean,
    showAppearance: Boolean,
    onBack: () -> Unit,
    onToggleSaved: () -> Unit,
    onAppearance: () -> Unit,
    onOpenSource: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Praxis.colors.background)
            .statusBarsPadding()
            .padding(horizontal = Tokens.Spacing.s1, vertical = Tokens.Spacing.s1),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
    ) {
        IconButton(onClick = onBack) {
            Icon(
                imageVector = Icons.Filled.ArrowBack,
                contentDescription = stringResource(R.string.reader_back),
                tint = Praxis.colors.textPrimary,
            )
        }
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            color = Praxis.colors.textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        if (showAppearance) {
            IconButton(onClick = onAppearance) {
                Icon(
                    imageVector = Icons.Filled.TextFields,
                    contentDescription = stringResource(R.string.reader_appearance),
                    tint = Praxis.colors.accent,
                )
            }
        }
        IconButton(onClick = onToggleSaved) {
            Icon(
                imageVector = if (isSaved) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                contentDescription = stringResource(if (isSaved) R.string.reader_unsave else R.string.reader_save),
                tint = Praxis.colors.accent,
            )
        }
        IconButton(onClick = onOpenSource) {
            Icon(
                imageVector = Icons.Filled.OpenInBrowser,
                contentDescription = stringResource(R.string.reader_source),
                tint = Praxis.colors.accent,
            )
        }
    }
}

@SuppressLint("SetJavaScriptEnabled")
@Composable
private fun ReaderWebView(
    html: String,
    sourceUrl: String,
    appearance: ReaderAppearance,
    initialProgress: Double,
    onProgress: (Double) -> Unit,
    onLink: (String, String) -> Unit,
) {
    val context = LocalContext.current
    val latestProgress = remember { mutableStateOf(onProgress) }
    latestProgress.value = onProgress
    val latestLink = remember { mutableStateOf(onLink) }
    latestLink.value = onLink

    AndroidView(
        modifier = Modifier.fillMaxSize(),
        factory = { viewContext ->
            WebView(viewContext).apply {
                setBackgroundColor(android.graphics.Color.TRANSPARENT)
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = false
                settings.allowFileAccess = false
                settings.allowContentAccess = false
                settings.builtInZoomControls = false
                settings.displayZoomControls = false
                settings.setSupportZoom(false)
                settings.mediaPlaybackRequiresUserGesture = true
                webViewClient = object : WebViewClient() {
                    override fun onPageFinished(view: WebView, url: String?) {
                        val script = ReaderScripts.hostShim() + "\n" +
                            ReaderScripts.documentScript(
                                context = viewContext.applicationContext,
                                sourceUrl = sourceUrl,
                                appearance = appearance,
                                initialProgress = initialProgress,
                            )
                        view.evaluateJavascript(script, null)
                    }
                }
                addJavascriptInterface(
                    ReaderBridge(
                        onProgress = { value -> post { latestProgress.value(value) } },
                        onLink = { url, title -> post { latestLink.value(url, title) } },
                    ),
                    "PraxisBridge",
                )
                loadDataWithBaseURL(sourceUrl, html, "text/html", "utf-8", null)
            }
        },
        update = { view ->
            view.evaluateJavascript(ReaderScripts.appearanceCall(appearance), null)
        },
    )
}

@Composable
private fun PdfPages(
    bytes: ByteArray,
    initialProgress: Double,
    onProgress: (Double) -> Unit,
    onFailure: () -> Unit,
) {
    val context = LocalContext.current
    var pageCount by remember(bytes) { mutableStateOf<Int?>(null) }
    var loadFailed by remember(bytes) { mutableStateOf(false) }
    val file = remember(bytes) { java.io.File(context.cacheDir, "reader-${bytes.contentHashCode()}.pdf") }

    LaunchedEffect(bytes) {
        runCatching {
            withContext(Dispatchers.IO) {
                file.writeBytes(bytes)
                ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                    PdfRenderer(descriptor).use { renderer -> renderer.pageCount }
                }
            }
        }.onSuccess { count ->
            if (count > 0) pageCount = count else { loadFailed = true; onFailure() }
        }
            .onFailure { if (it is CancellationException) throw it; loadFailed = true; onFailure() }
    }

    val count = pageCount
    if (loadFailed) {
        ReaderMessage(stringResource(R.string.reader_error), stringResource(R.string.reader_error_body))
        return
    }
    if (count == null) {
        Loading()
        return
    }

    val initialPage = (initialProgress.coerceIn(0.0, 1.0) * (count - 1).coerceAtLeast(0)).toInt()
    val listState = androidx.compose.foundation.lazy.rememberLazyListState(initialFirstVisibleItemIndex = initialPage)
    LaunchedEffect(listState, count) {
        androidx.compose.runtime.snapshotFlow {
            if (count > 1) listState.firstVisibleItemIndex.toDouble() / (count - 1) else 1.0
        }.collect(onProgress)
    }

    LazyColumn(
        state = listState,
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = Tokens.Spacing.s8),
    ) {
        items(count) { index ->
            var bitmap by remember(bytes, index) { mutableStateOf<Bitmap?>(null) }
            var renderFailed by remember(bytes, index) { mutableStateOf(false) }
            LaunchedEffect(bytes, index) {
                runCatching {
                    withContext(Dispatchers.IO) {
                        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                            PdfRenderer(descriptor).use { renderer ->
                                renderer.openPage(index).use { page ->
                                    val width = 1080
                                    val height = (width.toFloat() / page.width * page.height).toInt().coerceAtLeast(1)
                                    Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { rendered ->
                                        rendered.eraseColor(android.graphics.Color.WHITE)
                                        page.render(rendered, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                    }
                                }
                            }
                        }
                    }
                }.onSuccess { bitmap = it }
                    .onFailure { if (it is CancellationException) throw it; renderFailed = true; onFailure() }
            }
            when {
                bitmap != null -> Image(
                    bitmap = bitmap!!.asImageBitmap(),
                    contentDescription = null,
                    modifier = Modifier.fillMaxWidth(),
                )
                renderFailed -> ReaderMessage(stringResource(R.string.reader_error), stringResource(R.string.reader_error_body))
                else -> Box(Modifier.fillMaxWidth().height(300.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Praxis.colors.accent)
                }
            }
        }
    }
}

@Composable
private fun Loading() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = Praxis.colors.accent)
    }
}

@Composable
private fun ReaderMessage(title: String, body: String) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier
                .padding(horizontal = Tokens.Spacing.s8)
                .navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(text = title, style = MaterialTheme.typography.titleSmall, color = Praxis.colors.textPrimary)
            Spacer(Modifier.height(Tokens.Spacing.s1))
            Text(text = body, style = MaterialTheme.typography.bodyMedium, color = Praxis.colors.textSecondary)
        }
    }
}

@Composable
private fun ReaderAppearanceSheet(
    appearance: ReaderAppearance,
    onChange: (ReaderAppearance) -> Unit,
    onDismiss: () -> Unit,
) {
    ReadingThemeSheet(appearance = appearance, onChange = onChange, onDismiss = onDismiss)
}

/**
 * The two channels the shared reader script talks to. Kept as a named class so ProGuard rules can
 * keep the annotated methods reachable from JavaScript after shrinking.
 */
internal class ReaderBridge(
    private val onProgress: (Double) -> Unit,
    private val onLink: (String, String) -> Unit,
) {
    @JavascriptInterface
    fun progress(value: Double) {
        onProgress(value)
    }

    @JavascriptInterface
    fun link(url: String, title: String) {
        onLink(url, title)
    }
}
