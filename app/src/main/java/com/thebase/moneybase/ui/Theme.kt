package com.thebase.moneybase.ui

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightTheme = lightColorScheme(
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = Color(0xFF121212)
)

private val DarkTheme = darkColorScheme(
    onPrimary = Color(0xFF121212),
    onSecondary = Color(0xFF1E1E1E),
    onBackground = Color(0xFFF5F5F5)
)

private data class Palette(val primary: Color, val secondary: Color, val background: Color)

private val PurplePalette = Palette(
    primary = Color(0xFF7E57C2),
    secondary = Color(0xFFB39DDB),
    background = Color(0xFFF3E5F5)
)

private val BluePalette = Palette(
    primary = Color(0xFF42A5F5),
    secondary = Color(0xFF90CAF9),
    background = Color(0xFFE3F2FD)
)

private val GreenPalette = Palette(
    primary = Color(0xFF66BB6A),
    secondary = Color(0xFFA5D6A7),
    background = Color(0xFFE8F5E9)
)

private val RedPalette = Palette(
    primary = Color(0xFFEF5350),
    secondary = Color(0xFFEF9A9A),
    background = Color(0xFFFFEBEE)
)

enum class ColorScheme { Purple, Blue, Green, Red }

@Composable
fun MoneyBaseTheme(
    colorScheme: ColorScheme,
    darkMode: Boolean,
    content: @Composable () -> Unit
) {
    val base = if (darkMode) DarkTheme else LightTheme
    val palette = when (colorScheme) {
        ColorScheme.Purple -> PurplePalette
        ColorScheme.Blue   -> BluePalette
        ColorScheme.Green  -> GreenPalette
        ColorScheme.Red    -> RedPalette
    }
    val colors = if (darkMode) {
        base.copy(
            primary = palette.primary,
            secondary = palette.secondary
        )
    } else {
        base.copy(
            primary = palette.primary,
            secondary = palette.secondary,
            background = palette.background
        )
    }

    MaterialTheme(colorScheme = colors, content = content)
}

fun getIconColorForScheme(scheme: ColorScheme): Color = when (scheme) {
    ColorScheme.Purple -> PurplePalette.primary
    ColorScheme.Blue   -> BluePalette.primary
    ColorScheme.Green  -> GreenPalette.primary
    ColorScheme.Red    -> RedPalette.primary
}