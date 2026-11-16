package br.praxis.android.ui.reader

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogProperties
import br.praxis.android.R
import br.praxis.android.data.ReaderAppearance
import br.praxis.android.design.Praxis
import br.praxis.android.design.Tokens
import java.util.Locale
import kotlin.math.roundToInt

private fun hexColor(hex: String): Color {
    val value = hex.removePrefix("#").toLongOrNull(16) ?: 0xFFFBFAF7
    return Color(0xFF000000 or value)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReadingThemeSheet(
    appearance: ReaderAppearance,
    onChange: (ReaderAppearance) -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Praxis.colors.surface,
    ) {
        Column(
            modifier = Modifier
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Tokens.Spacing.s5)
                .padding(bottom = Tokens.Spacing.s8),
        ) {
            Text(
                text = stringResource(R.string.appearance_title),
                style = MaterialTheme.typography.titleLarge,
                color = Praxis.colors.textPrimary,
            )

            GroupLabel(stringResource(R.string.appearance_section_text))

            Text(
                text = stringResource(R.string.appearance_font),
                style = MaterialTheme.typography.labelMedium,
                color = Praxis.colors.textSecondary,
            )
            Spacer(Modifier.height(Tokens.Spacing.s2))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s2),
            ) {
                ReaderAppearance.fonts.forEach { font ->
                    FontChip(
                        label = font,
                        selected = appearance.font == font,
                        onClick = { onChange(appearance.copy(font = font)) },
                    )
                }
            }

            SliderRow(
                label = stringResource(R.string.appearance_size),
                value = stringResource(R.string.appearance_size_value, appearance.size),
            ) {
                Slider(
                    value = appearance.size.toFloat(),
                    onValueChange = { onChange(appearance.copy(size = it.roundToInt())) },
                    valueRange = 13f..34f,
                    steps = 20,
                )
            }

            SliderRow(
                label = stringResource(R.string.appearance_line_spacing),
                value = stringResource(
                    R.string.appearance_line_spacing_value,
                    String.format(Locale("pt", "BR"), "%.1f", appearance.lineSpacing),
                ),
            ) {
                Slider(
                    value = appearance.lineSpacing.toFloat(),
                    onValueChange = { onChange(appearance.copy(lineSpacing = (it * 10f).roundToInt() / 10.0)) },
                    valueRange = 1.2f..2.4f,
                    steps = 11,
                )
            }

            SliderRow(
                label = stringResource(R.string.appearance_margins),
                value = stringResource(R.string.appearance_margins_value, appearance.margin),
            ) {
                Slider(
                    value = appearance.margin.toFloat(),
                    onValueChange = { onChange(appearance.copy(margin = (it / 2f).roundToInt() * 2)) },
                    valueRange = 8f..48f,
                    steps = 19,
                )
            }

            Text(
                text = stringResource(R.string.appearance_alignment),
                style = MaterialTheme.typography.labelMedium,
                color = Praxis.colors.textSecondary,
                modifier = Modifier.padding(top = Tokens.Spacing.s3),
            )
            Spacer(Modifier.height(Tokens.Spacing.s2))
            val justified = appearance.alignment == "justified"
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = !justified,
                    onClick = { onChange(appearance.copy(alignment = "left")) },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2),
                ) { Text(stringResource(R.string.appearance_left)) }
                SegmentedButton(
                    selected = justified,
                    onClick = { onChange(appearance.copy(alignment = "justified")) },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2),
                ) { Text(stringResource(R.string.appearance_justified)) }
            }

            GroupLabel(stringResource(R.string.appearance_section_colors))

            Row(horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3)) {
                ReaderAppearance.builtInThemes.forEach { name ->
                    ThemeSwatch(
                        name = name,
                        selected = appearance.theme == name,
                        onClick = { onChange(appearance.withTheme(name)) },
                    )
                }
            }

            Spacer(Modifier.height(Tokens.Spacing.s3))
            TextButton(onClick = { onChange(appearance.withColors()) }) {
                Text(stringResource(R.string.appearance_custom_colors), color = Praxis.colors.accent)
            }

            if (appearance.theme == "custom") {
                ColorEditorRow(stringResource(R.string.appearance_background), appearance.background) { onChange(appearance.withColors(background = it)) }
                ColorEditorRow(stringResource(R.string.appearance_foreground), appearance.foreground) { onChange(appearance.withColors(foreground = it)) }
                ColorEditorRow(stringResource(R.string.appearance_links), appearance.link) { onChange(appearance.withColors(link = it)) }
                val textRatio = ReaderAppearance.contrastRatio(appearance.foreground, appearance.background)
                val linkRatio = ReaderAppearance.contrastRatio(appearance.link, appearance.background)
                Text(
                    text = stringResource(
                        R.string.appearance_contrast,
                        ratioLabel(textRatio),
                    ),
                    style = MaterialTheme.typography.labelMedium,
                    color = Praxis.colors.textSecondary,
                )
                Text(
                    text = stringResource(
                        R.string.appearance_contrast_links,
                        ratioLabel(linkRatio),
                    ),
                    style = MaterialTheme.typography.labelMedium,
                    color = Praxis.colors.textSecondary,
                )
            }

            Spacer(Modifier.height(Tokens.Spacing.s3))
            TextButton(onClick = { onChange(ReaderAppearance()) }) {
                Text(stringResource(R.string.appearance_restore), color = Praxis.colors.accent)
            }
        }
    }
}

@Composable
private fun ColorEditorRow(label: String, hex: String, onChange: (String) -> Unit) {
    val open = remember { mutableStateOf(false) }
    Row(
        modifier = Modifier.fillMaxWidth().padding(top = Tokens.Spacing.s2),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Tokens.Spacing.s3),
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = Praxis.colors.textPrimary, modifier = Modifier.weight(1f))
        Box(Modifier.size(28.dp).background(hexColor(hex), CircleShape).border(1.dp, Praxis.colors.separator, CircleShape))
        TextButton(onClick = { open.value = true }) { Text(hex.uppercase(), color = Praxis.colors.accent) }
    }
    if (open.value) ColorEditorDialog(label, hex, onChange) { open.value = false }
}

@Composable
private fun ColorEditorDialog(label: String, hex: String, onChange: (String) -> Unit, onDismiss: () -> Unit) {
    val raw = (hex.removePrefix("#").toLongOrNull(16) ?: 0xFBFAF7).toInt()
    val red = remember { mutableStateOf(((raw shr 16) and 255).toFloat()) }
    val green = remember { mutableStateOf(((raw shr 8) and 255).toFloat()) }
    val blue = remember { mutableStateOf((raw and 255).toFloat()) }
    val selected = String.format(Locale.ROOT, "#%02x%02x%02x", red.value.roundToInt(), green.value.roundToInt(), blue.value.roundToInt())
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(label) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(Tokens.Spacing.s1)) {
                Box(Modifier.fillMaxWidth().height(40.dp).background(hexColor(selected), RoundedCornerShape(Tokens.Radius.sm)))
                listOf("R" to red, "G" to green, "B" to blue).forEach { (channel, value) ->
                    Text("$channel · ${value.value.roundToInt()}", style = MaterialTheme.typography.labelMedium)
                    Slider(value = value.value, onValueChange = { value.value = it }, valueRange = 0f..255f)
                }
            }
        },
        confirmButton = { Button(onClick = { onChange(selected); onDismiss() }) { Text("OK") } },
        properties = DialogProperties(usePlatformDefaultWidth = true),
    )
}

@Composable
private fun ratioLabel(ratio: Double?): String {
    if (ratio == null) return "—"
    val pass = if (ratio >= 4.5) stringResource(R.string.appearance_contrast_pass) else stringResource(R.string.appearance_contrast_fail)
    return String.format(Locale("pt", "BR"), "%.1f:1 · %s", ratio, pass)
}

@Composable
private fun GroupLabel(text: String) {
    Text(
        text = text.uppercase(),
        style = MaterialTheme.typography.labelSmall,
        color = Praxis.colors.textSecondary,
        modifier = Modifier.padding(top = Tokens.Spacing.s6, bottom = Tokens.Spacing.s2),
    )
}

@Composable
private fun SliderRow(label: String, value: String, content: @Composable () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = Tokens.Spacing.s3),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            color = Praxis.colors.textPrimary,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = Praxis.colors.textSecondary,
        )
    }
    content()
}

@Composable
private fun FontChip(label: String, selected: Boolean, onClick: () -> Unit) {
    val shape = RoundedCornerShape(Tokens.Radius.sm)
    Box(
        modifier = Modifier
            .height(36.dp)
            .background(
                if (selected) Praxis.colors.chipSelectedBackground else Praxis.colors.chipBackground,
                shape,
            )
            .clickable(onClick = onClick)
            .padding(horizontal = Tokens.Spacing.s4),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = if (selected) Praxis.colors.chipSelectedContent else Praxis.colors.chipContent,
        )
    }
}

@Composable
private fun ThemeSwatch(name: String, selected: Boolean, onClick: () -> Unit) {
    val palette = ReaderAppearance.themes[name] ?: return
    val background = hexColor(palette[0])
    val ink = hexColor(palette[1])
    Box(
        modifier = Modifier
            .size(44.dp)
            .background(background, CircleShape)
            .border(
                width = if (selected) 3.dp else 1.dp,
                color = if (selected) Praxis.colors.accent else Praxis.colors.separator,
                shape = CircleShape,
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = "A", color = ink, fontWeight = FontWeight.SemiBold)
    }
}
