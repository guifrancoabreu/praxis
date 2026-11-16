package br.praxis.android.data

import br.praxis.android.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/** Sends feedback to the app's configured first-party endpoint. No credentials belong in the app. */
object FeedbackSender {
    private val client = OkHttpClient()

    suspend fun send(type: String, details: String, email: String) = withContext(Dispatchers.IO) {
        val endpoint = BuildConfig.FEEDBACK_URL
        require(endpoint.isNotBlank()) { "Feedback endpoint is not configured" }
        val endpointUri = android.net.Uri.parse(endpoint)
        require(endpointUri.scheme == "https" && !endpointUri.host.isNullOrBlank()) {
            "Feedback endpoint must use HTTPS"
        }
        val payload = JSONObject()
            .put("type", type)
            .put("details", details)
            .put("email", email)
            .toString()
            .toRequestBody("application/json; charset=utf-8".toMediaType())
        val request = Request.Builder().url(endpoint).post(payload).build()
        client.newCall(request).execute().use { response ->
            check(response.code == 200) { "Feedback request failed (${response.code})" }
        }
    }
}
