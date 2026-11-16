package br.praxis.android

import android.app.Application
import br.praxis.android.data.Analytics
import br.praxis.android.data.CatalogRepository
import br.praxis.android.data.PageStore
import br.praxis.android.data.PraxisPreferences
import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.network.okhttp.OkHttpNetworkFetcherFactory

class PraxisApplication : Application(), SingletonImageLoader.Factory {
    override fun onCreate() {
        super.onCreate()
        AppGraph.repository = CatalogRepository(this)
        AppGraph.preferences = PraxisPreferences(this)
        AppGraph.pageStore = PageStore(this)
        Analytics.configure(this, AppGraph.preferences)
    }

    override fun newImageLoader(context: PlatformContext): ImageLoader =
        ImageLoader.Builder(context)
            .components { add(OkHttpNetworkFetcherFactory()) }
            .build()
}
