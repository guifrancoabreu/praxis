package br.praxis.android.design

import androidx.annotation.FontRes
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import br.praxis.android.R

/**
 * The two bundled typefaces, both shipped as single variable TTFs in `res/font/`.
 *
 * Each family registers the same file once per weight, so Compose picks the right instance for
 * `FontWeight` instead of synthesising a fake bold. The explicit `wght` axis setting makes the
 * variable font actually render that weight on API 26+, where weight alone would be ignored.
 */
object PraxisFonts {
    /** Literata — display and heading text. */
    val Heading: FontFamily = variableFamily(R.font.literata)

    /** Inter — body, label and UI text. */
    val Body: FontFamily = variableFamily(R.font.inter)
}

private fun variableFamily(@FontRes resId: Int): FontFamily = FontFamily(
    variableFont(resId, FontWeight.Normal, 400),
    variableFont(resId, FontWeight.Medium, 500),
    variableFont(resId, FontWeight.SemiBold, 600),
    variableFont(resId, FontWeight.Bold, 700),
)

@OptIn(ExperimentalTextApi::class)
private fun variableFont(
    @FontRes resId: Int,
    weight: FontWeight,
    axisWeight: Int,
): Font = Font(
    resId = resId,
    weight = weight,
    variationSettings = FontVariation.Settings(FontVariation.weight(axisWeight)),
)
