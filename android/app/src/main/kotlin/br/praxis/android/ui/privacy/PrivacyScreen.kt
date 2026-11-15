package br.praxis.android.ui.privacy

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import br.praxis.android.R
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.components.SectionHeader

private const val TELEMETRY_DECK_PRIVACY_URL = "https://telemetrydeck.com/privacy/"

/**
 * The privacy policy, mirroring PrivacyPolicyView on iOS: the same Portuguese copy, laid out as
 * stacked sections with an optional analytics consent switch.
 */
@Composable
fun PrivacyScreen(
    onBack: () -> Unit,
    analyticsAvailable: Boolean,
    consent: Boolean,
    onConsentChange: (Boolean) -> Unit,
    onOpenUrl: (String) -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Praxis.colors.background),
    ) {
        TopBar(title = stringResource(R.string.privacy_title), onBack = onBack)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(Tokens.Spacing.s5)
                .navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s5),
        ) {
            Text(
                text = stringResource(R.string.privacy_intro),
                style = MaterialTheme.typography.bodyLarge,
                color = Praxis.colors.textPrimary,
            )

            PolicySection(
                title = stringResource(R.string.privacy_on_device_title),
                body = stringResource(R.string.privacy_on_device_body),
            )
            PolicySection(
                title = stringResource(R.string.privacy_archive_title),
                body = stringResource(R.string.privacy_archive_body),
            )

            AnalyticsSection(
                analyticsAvailable = analyticsAvailable,
                consent = consent,
                onConsentChange = onConsentChange,
                onOpenUrl = onOpenUrl,
            )

            PolicySection(
                title = stringResource(R.string.privacy_third_party_title),
                body = stringResource(R.string.privacy_third_party_body),
            )
            PolicySection(
                title = stringResource(R.string.privacy_retention_title),
                body = stringResource(R.string.privacy_retention_body),
            )

            ContactSection(onOpenUrl = onOpenUrl)
        }
    }
}

/** Back control and inline title, the counterpart of the iOS navigation bar. */
@Composable
private fun TopBar(title: String, onBack: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(horizontal = Tokens.Spacing.s1, vertical = Tokens.Spacing.s1),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onBack) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = stringResource(R.string.action_back),
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
    }
}

@Composable
private fun PolicySection(title: String, body: String) {
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2)) {
        SectionHeader(title = title)
        Text(
            text = body,
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textPrimary,
        )
    }
}

@Composable
private fun AnalyticsSection(
    analyticsAvailable: Boolean,
    consent: Boolean,
    onConsentChange: (Boolean) -> Unit,
    onOpenUrl: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2)) {
        SectionHeader(title = stringResource(R.string.privacy_analytics_title))
        Text(
            text = stringResource(R.string.privacy_analytics_body),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textPrimary,
        )

        if (analyticsAvailable) {
            val label = stringResource(R.string.privacy_analytics_consent_title)
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
                ) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelLarge,
                        color = Praxis.colors.textPrimary,
                    )
                    Text(
                        text = stringResource(R.string.privacy_analytics_consent_detail),
                        style = MaterialTheme.typography.labelMedium,
                        color = Praxis.colors.textSecondary,
                    )
                }
                Switch(
                    checked = consent,
                    onCheckedChange = onConsentChange,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = Praxis.colors.accent,
                    ),
                    modifier = Modifier.semantics { contentDescription = label },
                )
            }
        } else {
            Text(
                text = stringResource(R.string.privacy_analytics_unavailable),
                style = MaterialTheme.typography.labelMedium,
                color = Praxis.colors.textSecondary,
            )
        }

        Link(
            text = stringResource(R.string.privacy_analytics_policy_link),
            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium),
            onClick = { onOpenUrl(TELEMETRY_DECK_PRIVACY_URL) },
        )
    }
}

@Composable
private fun ContactSection(onOpenUrl: (String) -> Unit) {
    val email = stringResource(R.string.privacy_contact_email)
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2)) {
        SectionHeader(title = stringResource(R.string.privacy_contact_title))
        Text(
            text = stringResource(R.string.privacy_contact_body),
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textPrimary,
        )
        Link(
            text = email,
            style = MaterialTheme.typography.labelLarge,
            onClick = { onOpenUrl("mailto:$email") },
        )
    }
}

/** Accent text that opens a URL, with the touch target the inline links on iOS get from the row. */
@Composable
private fun Link(
    text: String,
    style: androidx.compose.ui.text.TextStyle,
    onClick: () -> Unit,
) {
    Text(
        text = text,
        style = style,
        color = Praxis.colors.accent,
        modifier = Modifier
            .clip(RoundedCornerShape(Tokens.Radius.sm))
            .clickable(onClick = onClick)
            .padding(vertical = Tokens.Spacing.s1),
    )
}
