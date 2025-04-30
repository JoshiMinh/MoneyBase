package com.thebase.moneybase.ui.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val LightThemeColors = lightColorScheme(
    primary = Color(0xFF6200EE),
    onPrimary = Color.White,
    background = Color(0xFFF5F5F5),
    onBackground = Color.Black,
    secondary = Color(0xFF03DAC6),
    onSecondary = Color.Black
)

val DarkThemeColors = darkColorScheme(
    primary = Color(0xFFBB86FC),
    onPrimary = Color.Black,
    background = Color(0xFF121212),
    onBackground = Color.White,
    secondary = Color(0xFF03DAC6),
    onSecondary = Color.White
)

val BlueThemeColors = lightColorScheme(
    primary = Color(0xFF1E88E5),
    onPrimary = Color.White,
    background = Color(0xFFE3F2FD),
    onBackground = Color.Black,
    secondary = Color(0xFF0D47A1),
    onSecondary = Color.White
)

val GreenThemeColors = lightColorScheme(
    primary = Color(0xFF43A047),
    onPrimary = Color.White,
    background = Color(0xFFE8F5E9),
    onBackground = Color.Black,
    secondary = Color(0xFF1B5E20),
    onSecondary = Color.White
)

val RedThemeColors = lightColorScheme(
    primary = Color(0xFFD32F2F),
    onPrimary = Color.White,
    background = Color(0xFFFFEBEE),
    onBackground = Color.Black,
    secondary = Color(0xFFB71C1C),
    onSecondary = Color.White
)

enum class ColorScheme {
    Light, Dark, Blue, Green, Red
}

@Composable
fun MoneyBaseTheme(
    colorScheme: ColorScheme,
    content: @Composable () -> Unit
) {
    val colors = when (colorScheme) {
        ColorScheme.Light -> LightThemeColors
        ColorScheme.Dark -> DarkThemeColors
        ColorScheme.Blue -> BlueThemeColors
        ColorScheme.Green -> GreenThemeColors
        ColorScheme.Red -> RedThemeColors
    }
    MaterialTheme(
        colorScheme = colors,
        content = content
    )
}

fun getIconColorForScheme(scheme: ColorScheme): Color = when (scheme) {
    ColorScheme.Light -> Color.White
    ColorScheme.Dark -> Color.Black
    ColorScheme.Blue -> Color(0xFF1E88E5)
    ColorScheme.Green -> Color(0xFF43A047)
    ColorScheme.Red -> Color(0xFFD32F2F)
}