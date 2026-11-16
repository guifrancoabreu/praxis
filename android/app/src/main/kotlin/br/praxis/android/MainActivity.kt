package br.praxis.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.praxis.android.data.Analytics
import br.praxis.android.ui.privacy.PrivacyScreen
import br.praxis.android.ui.support.SupportScreen
import br.praxis.android.ui.feedback.FeedbackScreen
import kotlinx.coroutines.launch
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import br.praxis.android.design.PraxisTheme
import br.praxis.android.ui.author.AuthorScreen
import br.praxis.android.ui.collection.CollectionScreen
import br.praxis.android.ui.library.LibraryScreen
import br.praxis.android.ui.reader.ReaderScreen
import br.praxis.android.ui.stats.ReadingStatsScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            PraxisTheme { PraxisNavHost() }
        }
    }
}

@Composable
private fun PraxisNavHost() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = "library") {
        composable("library") {
            LibraryScreen(
                onOpenWork = { author, work ->
                    navController.navigate(
                        "reader?path=${android.net.Uri.encode(work.path)}" +
                            "&title=${android.net.Uri.encode(work.title)}" +
                            "&author=${android.net.Uri.encode(author.full)}" +
                            "&workId=${android.net.Uri.encode(work.id)}",
                    )
                },
                onOpenAuthor = { author -> navController.navigate("author/${android.net.Uri.encode(author.id)}") },
                onOpenCollection = { collection -> navController.navigate("collection/${android.net.Uri.encode(collection.id)}") },
                onOpenSupport = { navController.navigate("support") },
                onOpenFeedback = { navController.navigate("feedback") },
                onOpenPrivacy = { navController.navigate("privacy") },
                onOpenStats = { navController.navigate("stats") },
            )
        }

        composable(
            route = "author/{authorId}",
            arguments = listOf(navArgument("authorId") { type = NavType.StringType }),
        ) { entry ->
            AuthorScreen(
                authorId = entry.arguments?.getString("authorId").orEmpty(),
                onBack = { navController.popBackStack() },
                onOpenWork = { author, work ->
                    navController.navigate(
                        "reader?path=${android.net.Uri.encode(work.path)}" +
                            "&title=${android.net.Uri.encode(work.title)}" +
                            "&author=${android.net.Uri.encode(author.full)}" +
                            "&workId=${android.net.Uri.encode(work.id)}",
                    )
                },
                onOpenArchiveLink = { url, title ->
                    navController.navigate(
                        "reader?path=${android.net.Uri.encode(url)}" +
                            "&title=${android.net.Uri.encode(title)}" +
                            "&author=" +
                            "&workId=",
                    )
                },
            )
        }

        composable(
            route = "collection/{collectionId}",
            arguments = listOf(navArgument("collectionId") { type = NavType.StringType }),
        ) { entry ->
            CollectionScreen(
                collectionId = entry.arguments?.getString("collectionId").orEmpty(),
                onBack = { navController.popBackStack() },
                onOpenItem = { item ->
                    navController.navigate(
                        "reader?path=${android.net.Uri.encode(item.path)}" +
                            "&title=${android.net.Uri.encode(item.title)}" +
                            "&author=" +
                            "&workId=",
                    )
                },
            )
        }

        composable("support") {
            val context = LocalContext.current
            LaunchedEffect(Unit) { Analytics.track(Analytics.Event.SupportPageOpened) }
            SupportScreen(
                onBack = { navController.popBackStack() },
                onOpenUrl = { url -> context.openExternally(url) },
                onDestinationOpened = { destination ->
                    Analytics.track(Analytics.Event.SupportDestinationOpened(destination))
                },
            )
        }

        composable("stats") {
            ReadingStatsScreen(onBack = { navController.popBackStack() })
        }

        composable("feedback") {
            val scope = rememberCoroutineScope()
            FeedbackScreen(onBack = { navController.popBackStack() }, scope = scope)
        }

        composable("privacy") {
            val context = LocalContext.current
            val scope = rememberCoroutineScope()
            val preferences = AppGraph.preferences
            val consent by preferences.analyticsConsent.collectAsStateWithLifecycle(initialValue = false)
            PrivacyScreen(
                onBack = { navController.popBackStack() },
                analyticsAvailable = true,
                consent = consent,
                onConsentChange = { granted ->
                    scope.launch {
                        preferences.setAnalyticsConsent(granted)
                        Analytics.setConsent(context.applicationContext, preferences, granted)
                    }
                },
                onOpenUrl = { url -> context.openExternally(url) },
            )
        }

        composable(
            route = "reader?path={path}&title={title}&author={author}&workId={workId}",
            arguments = listOf(
                navArgument("path") { type = NavType.StringType },
                navArgument("title") { type = NavType.StringType; defaultValue = "" },
                navArgument("author") { type = NavType.StringType; defaultValue = "" },
                navArgument("workId") { type = NavType.StringType; defaultValue = "" },
            ),
        ) { entry ->
            val args = entry.arguments
            ReaderScreen(
                workPath = args?.getString("path").orEmpty(),
                title = args?.getString("title").orEmpty(),
                author = args?.getString("author").orEmpty(),
                workId = args?.getString("workId")?.takeIf { it.isNotBlank() },
                onBack = { navController.popBackStack() },
                onOpenArchiveLink = { url, title ->
                    navController.navigate(
                        "reader?path=${android.net.Uri.encode(url)}" +
                            "&title=${android.net.Uri.encode(title)}&author=&workId=",
                    )
                },
            )
        }
    }
}

private fun android.content.Context.openExternally(url: String) {
    runCatching { startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url))) }
}
