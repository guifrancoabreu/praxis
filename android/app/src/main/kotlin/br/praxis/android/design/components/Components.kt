package br.praxis.android.design.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import br.praxis.android.design.Praxis
import br.praxis.android.design.PraxisFonts
import br.praxis.android.design.Tokens

/** Full-width primary action, matching the iOS treatment. */
@Composable
fun PrimaryButton(text: String, onClick: () -> Unit, enabled: Boolean, modifier: Modifier = Modifier) {
    val content = if (isSystemInDarkTheme()) Color.Black else Color.White
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.fillMaxWidth().heightIn(min = Tokens.Sizing.touchTarget),
        shape = RoundedCornerShape(Tokens.Radius.md),
        colors = ButtonDefaults.buttonColors(
            containerColor = Praxis.colors.accent,
            contentColor = content,
            disabledContainerColor = Praxis.colors.accent.copy(alpha = 0.5f),
            disabledContentColor = content.copy(alpha = 0.5f),
        ),
    ) {
        Text(text, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
    }
}

/**
 * A reusable typographic cover for a text or publication, matching BookCover on iOS: the tone is a
 * hash of the title, so the same work always gets the same spine.
 */
@Composable
fun BookCover(title: String, modifier: Modifier = Modifier, compact: Boolean = true, imprint: String = "MIA") {
    val tones = listOf(
        Praxis.colors.coverOchre,
        Praxis.colors.coverRust,
        Praxis.colors.coverOlive,
        Praxis.colors.coverBlue,
    )
    var seed = 0
    for (character in title) seed = (seed * 31 + character.code) and 0x7fffffff
    val tone = tones[seed % tones.size]
    val shape = RoundedCornerShape(Tokens.Radius.sm)
    BoxWithConstraints(modifier = modifier) {
        val ruleWidth = maxWidth * 0.28f
        val boxHeight = maxHeight
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(boxHeight)
                .shadow(
                    elevation = Tokens.Shadow.coverRadius,
                    shape = shape,
                    clip = false,
                    ambientColor = Color.Black.copy(alpha = Tokens.Opacity.coverShadow),
                    spotColor = Color.Black.copy(alpha = Tokens.Opacity.coverShadow),
                )
                .clip(shape)
                .background(tone)
                .border(1.dp, Color.Black.copy(alpha = Tokens.Opacity.coverOutline), shape),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(if (compact) 7.dp else 9.dp),
            ) {
                Box(
                    modifier = Modifier
                        .width(ruleWidth)
                        .height(2.dp)
                        .background(Color.White.copy(alpha = 0.72f)),
                )
                Spacer(Modifier.weight(1f))
                BasicText(
                    text = title,
                    style = TextStyle(
                        color = Color.White,
                        fontFamily = PraxisFonts.Heading,
                        fontWeight = FontWeight.SemiBold,
                    ),
                    autoSize = TextAutoSize.StepBased(
                        minFontSize = if (compact) 6.75.sp else 7.5.sp,
                        maxFontSize = if (compact) Tokens.Typography.bookCoverTitleCompact else Tokens.Typography.bookCoverTitle,
                        stepSize = 0.25.sp,
                    ),
                    maxLines = if (compact) 4 else 5,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.weight(1f))
                Text(
                    text = imprint,
                    color = Color.White.copy(alpha = 0.8f),
                    fontWeight = FontWeight.Bold,
                    fontSize = Tokens.Typography.bookCoverBrand,
                    letterSpacing = 1.2.sp,
                )
            }
        }
    }
}

/** Generic list label; the caller supplies interaction semantics. */
@Composable
fun ListRow(title: String, subtitle: String? = null, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 44.dp)
            .padding(vertical = Tokens.Spacing.s1),
        verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1),
    ) {
        Text(text = title, style = MaterialTheme.typography.titleMedium, color = Praxis.colors.textPrimary)
        if (!subtitle.isNullOrEmpty()) {
            Text(text = subtitle, style = MaterialTheme.typography.bodyMedium, color = Praxis.colors.textSecondary)
        }
    }
}

/** Uppercase section heading with an optional accent action, as used across the library. */
@Composable
fun SectionHeader(title: String, action: String? = null, onAction: (() -> Unit)? = null, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.fillMaxWidth().heightIn(min = Tokens.Sizing.touchTarget),
        verticalAlignment = Alignment.Bottom,
    ) {
        Text(
            text = title.uppercase(),
            style = MaterialTheme.typography.bodyMedium.copy(
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.8.sp,
            ),
            color = Praxis.colors.textSecondary,
            modifier = Modifier.weight(1f).padding(bottom = Tokens.Spacing.s1),
        )
        if (action != null && onAction != null) {
            Box(
                modifier = Modifier
                    .heightIn(min = Tokens.Sizing.touchTarget)
                    .clip(RoundedCornerShape(Tokens.Radius.sm))
                    .clickable(onClick = onAction)
                    .padding(horizontal = Tokens.Spacing.s1),
                contentAlignment = Alignment.BottomCenter,
            ) {
                Text(
                    text = action,
                    style = MaterialTheme.typography.labelLarge,
                    color = Praxis.colors.accent,
                    modifier = Modifier.padding(bottom = Tokens.Spacing.s1),
                )
            }
        }
    }
}

/** Filter pill. Selected chips invert, matching the library filter bar on iOS. */
@Composable
fun PraxisChip(text: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val background = if (selected) Praxis.colors.chipSelectedBackground else Praxis.colors.chipBackground
    val content = if (selected) Praxis.colors.chipSelectedContent else Praxis.colors.chipContent
    Box(
        modifier = modifier
            .heightIn(min = 44.dp)
            .clip(CircleShape)
            .background(background)
            .clickable(onClick = onClick)
            .padding(horizontal = 15.dp, vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            color = content,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
        )
    }
}

/** Square artwork tile: the portrait covers the monogram once it loads, as on iOS. */
@Composable
fun AuthorArtwork(
    name: String,
    modifier: Modifier = Modifier,
    corner: Dp = Tokens.Radius.md,
    imageUrl: String? = null,
    focalAlignment: Alignment = Alignment.Center,
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(corner))
            .background(Praxis.colors.coverStone),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = name.trim().split(" ").firstOrNull()?.take(1) ?: "M",
            style = MaterialTheme.typography.titleLarge,
            color = Praxis.colors.accent,
        )
        if (imageUrl != null) {
            AsyncImage(
                model = imageUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                alignment = focalAlignment,
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}

/** Floating surface used by the search field and reader controls. */
@Composable
fun GlassSurface(modifier: Modifier = Modifier, corner: Dp = Tokens.Radius.full, content: @Composable () -> Unit) {
    val shape = RoundedCornerShape(corner)
    Box(
        modifier = modifier
            .shadow(
                elevation = 2.dp,
                shape = shape,
                clip = false,
                ambientColor = Color.Black.copy(alpha = Tokens.Opacity.coverShadow),
                spotColor = Color.Black.copy(alpha = Tokens.Opacity.coverShadow),
            )
            .clip(shape)
            .background(Praxis.colors.surface.copy(alpha = 0.96f))
            .border(BorderStroke(1.dp, Praxis.colors.separator), shape),
    ) { content() }
}

/** Inset divider matching the iOS list separators. */
@Composable
fun InsetDivider(modifier: Modifier = Modifier, startPadding: Dp = Tokens.Spacing.s4) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(start = startPadding)
            .height(1.dp)
            .background(Praxis.colors.separator),
    )
}

@Composable
fun Chevron(modifier: Modifier = Modifier) {
    Icon(
        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
        contentDescription = null,
        tint = Praxis.colors.textSecondary,
        modifier = modifier.size(18.dp),
    )
}

@Composable
fun RoundIconTile(diameter: Dp, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(
        modifier = modifier
            .size(diameter)
            .clip(CircleShape)
            .background(Praxis.colors.secondarySurface),
        contentAlignment = Alignment.Center,
    ) { content() }
}
