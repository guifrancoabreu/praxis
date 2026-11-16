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
    accent = Tokens.Colors.accentLight,
    background = Tokens.Colors.backgroundLight,
    surface = Tokens.Colors.surfaceLight,
    secondarySurface = Tokens.Colors.secondarySurfaceLight,
    textPrimary = Color(0xFF000000),
    textSecondary = Color(0xFF524D47),
    separator = Color(0x21000000),
    coverOchre = Tokens.Colors.coverOchre,
    coverRust = Tokens.Colors.coverRust,
    coverOlive = Tokens.Colors.coverOlive,
    coverBlue = Tokens.Colors.coverBlue,
    coverStone = Tokens.Colors.coverStoneLight,
    chipSelectedBackground = Color(0xFF000000),
    chipSelectedContent = Tokens.Colors.backgroundLight,
    chipBackground = Color(0xFFE9E4DA),
    chipContent = Color(0xFF000000),
)

private val darkColors = PraxisColors(
    accent = Tokens.Colors.accentDark,
    background = Tokens.Colors.backgroundDark,
    surface = Tokens.Colors.surfaceDark,
    secondarySurface = Tokens.Colors.secondarySurfaceDark,
    textPrimary = Color(0xFFFFFFFF),
    textSecondary = Color(0xFFA9A39D),
    separator = Color(0x2BFFFFFF),
    coverOchre = Tokens.Colors.coverOchre,
    coverRust = Tokens.Colors.coverRust,
    coverOlive = Tokens.Colors.coverOlive,
    coverBlue = Tokens.Colors.coverBlue,
    coverStone = Tokens.Colors.coverStoneDark,
    chipSelectedBackground = Color(0xFFFFFFFF),
    chipSelectedContent = Tokens.Colors.backgroundDark,
    chipBackground = Color(0xFF33302B),
    chipContent = Color(0xFFFFFFFF),
)

/** iOS text styles the app actually uses, sized in sp so the system font scale still applies. */
val PraxisTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.Bold,
        fontSize = 34.sp,
        lineHeight = 41.sp,
        letterSpacing = (-0.4).sp,
    ),
    titleLarge = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.SemiBold,
        fontSize = 22.sp,
        lineHeight = 28.sp,
    ),
    titleMedium = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.Medium,
        fontSize = 17.sp,
        lineHeight = 22.sp,
    ),
    titleSmall = TextStyle(
        fontFamily = PraxisFonts.Heading,
        fontWeight = FontWeight.SemiBold,
        fontSize = 17.sp,
        lineHeight = 22.sp,
    ),
    bodyLarge = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 17.sp,
        lineHeight = 22.sp,
    ),
    bodyMedium = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 15.sp,
        lineHeight = 20.sp,
    ),
    bodySmall = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 15.sp,
        lineHeight = 20.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 15.sp,
        lineHeight = 20.sp,
        fontWeight = FontWeight.Medium,
    ),
    labelMedium = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 13.sp,
        lineHeight = 18.sp,
    ),
    labelSmall = TextStyle(
        fontFamily = PraxisFonts.Body,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        letterSpacing = 0.6.sp,
        fontWeight = FontWeight.SemiBold,
    ),
)

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
            background = colors.background,
            surface = colors.surface,
            onBackground = colors.textPrimary,
            onSurface = colors.textPrimary,
        )
    } else {
        androidx.compose.material3.lightColorScheme(
            primary = colors.accent,
            background = colors.background,
            surface = colors.surface,
            onBackground = colors.textPrimary,
            onSurface = colors.textPrimary,
        )
    }
    CompositionLocalProvider(LocalColors provides colors) {
        MaterialTheme(colorScheme = material, typography = PraxisTypography, content = content)
    }
}
