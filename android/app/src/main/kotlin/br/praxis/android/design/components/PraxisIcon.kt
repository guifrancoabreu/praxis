package br.praxis.android.design.components

import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import br.praxis.android.R
import br.praxis.android.design.Praxis

/**
 * Icons drawn by the app rather than the platform: Lucide drawables generated from
 * `shared/assets/icons`. Platform chrome keeps the system icons, so this covers only the
 * app's own semantic icons.
 */
enum class PraxisIcon(val res: Int, val defaultSize: Dp) {
    ArrowUpRight(R.drawable.lucide_arrow_up_right, 16.dp),
    BookOpen(R.drawable.lucide_book_open, 20.dp),
    ChartColumn(R.drawable.lucide_chart_column, 20.dp),
    ChevronRight(R.drawable.lucide_chevron_right, 16.dp),
    CircleAlert(R.drawable.lucide_circle_alert, 28.dp),
    CloudOff(R.drawable.lucide_cloud_off, 28.dp),
    Coffee(R.drawable.lucide_coffee, 20.dp),
    Globe(R.drawable.lucide_globe, 16.dp),
    Heart(R.drawable.lucide_heart, 20.dp),
    Library(R.drawable.lucide_library, 20.dp),
    MessageCircle(R.drawable.lucide_message_circle, 20.dp),
    WifiOff(R.drawable.lucide_wifi_off, 28.dp),
}

/** Renders one Lucide icon tinted with the theme, sized to its optical default. */
@Composable
fun PraxisIconView(
    icon: PraxisIcon,
    modifier: Modifier = Modifier,
    size: Dp = icon.defaultSize,
    tint: Color = Praxis.colors.textSecondary,
) {
    Icon(
        painter = painterResource(icon.res),
        contentDescription = null,
        tint = tint,
        modifier = modifier.size(size),
    )
}
