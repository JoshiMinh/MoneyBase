package com.thebase.moneybase.ui

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightTheme = lightColorScheme(
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = Color.Black
)

private val DarkTheme = darkColorScheme(
    onPrimary = Color.Black,
    onSecondary = Color.Black,
    onBackground = Color.White
)

private data class Palette(val primary: Color, val secondary: Color, val background: Color)

private val PurplePalette = Palette(
    primary = Color(0xFF6200EE),
    secondary = Color(0xFF03DAC6),
    background = Color(0xFFE4D3FC)
)

private val BluePalette = Palette(
    primary = Color(0xFF1E88E5),
    secondary = Color(0xFF0D47A1),
    background = Color(0xFFE3F2FD)
)

private val GreenPalette = Palette(
    primary = Color(0xFF43A047),
    secondary = Color(0xFF1B5E20),
    background = Color(0xFFE8F5E9)
)

private val RedPalette = Palette(
    primary = Color(0xFFD32F2F),
    secondary = Color(0xFFB71C1C),
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