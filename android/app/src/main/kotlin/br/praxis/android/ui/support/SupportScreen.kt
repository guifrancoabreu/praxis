package br.praxis.android.ui.support

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.LocalCafe
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.praxis.android.R
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import br.praxis.android.design.title3
import br.praxis.android.design.components.RoundIconTile

private const val KO_FI_URL = "https://ko-fi.com/guifranco"
private const val ARCHIVE_DONATION_URL = "https://www.marxists.org/admin/donate/index.htm"

/** Destination keys reported to analytics, matching the iOS SupportDestination cases. */
private const val DESTINATION_KOFI = "kofi"
private const val DESTINATION_ARCHIVE = "archive"

/** The two ways to support the project, mirroring SupportView on iOS. */
@Composable
fun SupportScreen(onBack: () -> Unit, onOpenUrl: (String) -> Unit, onDestinationOpened: (String) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Praxis.colors.background),
    ) {
        TopBar(title = stringResource(R.string.support_title), onBack = onBack)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(Tokens.Spacing.s5)
                .navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s6),
        ) {
            Lead()
            SupportSection(
                title = stringResource(R.string.support_app_section),
                body = stringResource(R.string.support_app_body),
            ) {
                SupportCard(
                    title = stringResource(R.string.support_kofi_title),
                    action = stringResource(R.string.support_kofi_action),
                    icon = Icons.Outlined.LocalCafe,
                    onClick = {
                        onDestinationOpened(DESTINATION_KOFI)
                        onOpenUrl(KO_FI_URL)
                    },
                )
            }
            SupportSection(
                title = stringResource(R.string.support_archive_section),
                body = stringResource(R.string.support_archive_body),
            ) {
                SupportCard(
                    title = stringResource(R.string.support_archive_title),
                    action = stringResource(R.string.support_archive_action),
                    icon = Icons.AutoMirrored.Outlined.MenuBook,
                    onClick = {
                        onDestinationOpened(DESTINATION_ARCHIVE)
                        onOpenUrl(ARCHIVE_DONATION_URL)
                    },
                )
            }
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
private fun Lead() {
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2)) {
        Icon(
            imageVector = Icons.Outlined.FavoriteBorder,
            contentDescription = null,
            tint = Praxis.colors.accent,
            modifier = Modifier.size(38.dp),
        )
        Text(
            text = stringResource(R.string.support_title),
            style = MaterialTheme.typography.displayLarge.copy(
                fontWeight = FontWeight.Medium,
                letterSpacing = 0.sp,
            ),
            color = Praxis.colors.textPrimary,
        )
        Text(
            text = stringResource(R.string.support_lead),
            style = MaterialTheme.typography.bodyLarge,
            color = Praxis.colors.textSecondary,
        )
    }
}

@Composable
private fun SupportSection(title: String, body: String, card: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3)) {
        Text(
            text = title,
            style = MaterialTheme.typography.title3,
            color = Praxis.colors.textPrimary,
        )
        Text(
            text = body,
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
        card()
    }
}

/** Surface card with a round icon tile, a serif title, an accent action and an external arrow. */
@Composable
private fun SupportCard(title: String, action: String, icon: ImageVector, onClick: () -> Unit) {
    val shape = RoundedCornerShape(Tokens.Radius.lg)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Praxis.colors.surface)
            .border(1.dp, Praxis.colors.separator, shape)
            .clickable(onClick = onClick)
            .padding(Tokens.Spacing.s4),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        RoundIconTile(diameter = 42.dp) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = Praxis.colors.accent,
                modifier = Modifier.size(20.dp),
            )
        }
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                color = Praxis.colors.textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = action,
                style = MaterialTheme.typography.labelLarge,
                color = Praxis.colors.accent,
            )
        }
        Icon(
            imageVector = Icons.AutoMirrored.Outlined.OpenInNew,
            contentDescription = null,
            tint = Praxis.colors.textSecondary,
            modifier = Modifier.size(14.dp),
        )
    }
}
