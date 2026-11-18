package br.praxis.android.design

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * Semantic roles composed from the tokens, mirroring SystemTokens on iOS.
 *
 * Platform-adaptive roles on iOS (label, separator) are approximated here with the closest fixed
 * values, because the iOS reading palette is deliberately warm instead of the Android system gray.
 */
data class PraxisColors(
    val accent: Color,
    val primaryContent: Color,
    val background: Color,
    val surface: Color,
    val secondarySurface: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val separator: Color,
    val coverOchre: Color,
    val coverRust: Color,
    val coverOlive: Color,
    val coverBlue: Color,
    val coverStone: Color,
    val chipSelectedBackground: Color,
    val chipSelectedContent: Color,
    val chipBackground: Color,
    val chipContent: Color,
)

private val lightColors = PraxisColors(
    accent = Tokens.Semantic.primaryLight,
    primaryContent = Tokens.Semantic.primaryForegroundLight,
    background = Tokens.Semantic.backgroundLight,
    surface = Tokens.Semantic.cardLight,
    secondarySurface = Tokens.Semantic.mutedLight,
    textPrimary = Tokens.Semantic.foregroundLight,
    textSecondary = Tokens.Semantic.mutedForegroundLight,
    separator = Tokens.Semantic.separatorLight,
    coverOchre = Tokens.Colors.coverOchre,
    coverRust = Tokens.Colors.coverRust,
    coverOlive = Tokens.Colors.coverOlive,
    coverBlue = Tokens.Colors.coverBlue,
    coverStone = Tokens.Colors.coverStoneLight,
    chipSelectedBackground = Tokens.Semantic.foregroundLight,
    chipSelectedContent = Tokens.Semantic.backgroundLight,
    chipBackground = Tokens.Semantic.mutedLight,
    chipContent = Tokens.Semantic.foregroundLight,
)

private val darkColors = PraxisColors(
    accent = Tokens.Semantic.primaryDark,
    primaryContent = Tokens.Semantic.primaryForegroundDark,
    background = Tokens.Semantic.backgroundDark,
    surface = Tokens.Semantic.cardDark,
    secondarySurface = Tokens.Semantic.mutedDark,
    textPrimary = Tokens.Semantic.foregroundDark,
    textSecondary = Tokens.Semantic.mutedForegroundDark,
    separator = Tokens.Semantic.separatorDark,
    coverOchre = Tokens.Colors.coverOchre,
    coverRust = Tokens.Colors.coverRust,
    coverOlive = Tokens.Colors.coverOlive,
    coverBlue = Tokens.Colors.coverBlue,
    coverStone = Tokens.Colors.coverStoneDark,
    chipSelectedBackground = Tokens.Semantic.foregroundDark,
    chipSelectedContent = Tokens.Semantic.backgroundDark,
    chipBackground = Tokens.Semantic.mutedDark,
    chipContent = Tokens.Semantic.foregroundDark,
)

/**
 * iOS text styles the app actually uses, sized in sp so the system font scale still applies.
 * Heading styles use Literata's natural 1.485 leading and body/label styles Inter's 1.210,
 * taken from the hhea metrics of app/src/main/res/font/literata.ttf and inter.ttf. This matches
 * iOS, which never sets an explicit line height.
 */
val PraxisTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.Bold,
        fontSize = 34.sp,
        lineHeight = 50.sp,
        letterSpacing = (-0.4).sp,
    ),
    titleLarge = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.SemiBold,
        fontSize = 22.sp,
        lineHeight = 33.sp,
    ),
    titleMedium = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.Medium,
        fontSize = 17.sp,
        lineHeight = 25.sp,
    ),
    titleSmall = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.SemiBold,
        fontSize = 17.sp,
        lineHeight = 25.sp,
    ),
    bodyLarge = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 17.sp,
        lineHeight = 21.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 15.sp,
        lineHeight = 18.sp,
    ),
    bodySmall = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 15.sp,
        lineHeight = 18.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 15.sp,
        lineHeight = 18.sp,
        fontWeight = FontWeight.Medium,
    ),
    labelMedium = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 13.sp,
        lineHeight = 16.sp,
    ),
    labelSmall = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 12.sp,
        lineHeight = 15.sp,
        letterSpacing = 0.6.sp,
        fontWeight = FontWeight.SemiBold,
    ),
)

/**
 * The two steps the Material scale has no slot for, named after `Tokens.TypeScale` so call sites
 * read `MaterialTheme.typography.title3` / `.caption` and still land on the shared scale.
 */
private val title3Style = TextStyle(
    fontFamily = PraxisFonts.Heading,
    fontWeight = FontWeight.SemiBold,
    fontSize = Tokens.TypeScale.title3Size,
    lineHeight = Tokens.TypeScale.title3Leading,
)

private val captionStyle = TextStyle(
    fontFamily = PraxisFonts.Body,
    fontWeight = FontWeight.Normal,
    fontSize = Tokens.TypeScale.captionSize,
    lineHeight = Tokens.TypeScale.captionLeading,
)

val Typography.title3: TextStyle get() = title3Style
val Typography.caption: TextStyle get() = captionStyle

private val LocalColors = staticCompositionLocalOf { lightColors }

object Praxis {
    val colors: PraxisColors
        @Composable
        @ReadOnlyComposable
        get() = LocalColors.current
}

@Composable
fun PraxisTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colors = if (darkTheme) darkColors else lightColors
    val material = if (darkTheme) {
        androidx.compose.material3.darkColorScheme(
            primary = colors.accent,
            onPrimary = colors.primaryContent,
            primaryContainer = colors.secondarySurface,
            onPrimaryContainer = colors.textPrimary,
            secondary = colors.secondarySurface,
            onSecondary = colors.textPrimary,
            secondaryContainer = colors.secondarySurface,
            onSecondaryContainer = colors.textPrimary,
            background = colors.background,
            onBackground = colors.textPrimary,
            surface = colors.surface,
            onSurface = colors.textPrimary,
            surfaceVariant = colors.secondarySurface,
            onSurfaceVariant = colors.textSecondary,
            outline = colors.separator,
            outlineVariant = colors.separator,
        )
    } else {
        androidx.compose.material3.lightColorScheme(
            primary = colors.accent,
            onPrimary = colors.primaryContent,
            primaryContainer = colors.secondarySurface,
            onPrimaryContainer = colors.textPrimary,
            secondary = colors.secondarySurface,
            onSecondary = colors.textPrimary,
            secondaryContainer = colors.secondarySurface,
            onSecondaryContainer = colors.textPrimary,
            background = colors.background,
            onBackground = colors.textPrimary,
            surface = colors.surface,
            onSurface = colors.textPrimary,
            surfaceVariant = colors.secondarySurface,
            onSurfaceVariant = colors.textSecondary,
            outline = colors.separator,
            outlineVariant = colors.separator,
        )
    }
    CompositionLocalProvider(LocalColors provides colors) {
        MaterialTheme(colorScheme = material, typography = PraxisTypography, content = content)
    }
}
