package com.thebase.moneybase.ui

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Core light/dark overrides
private val LightTheme = lightColorScheme(
    onPrimary = Color.White,
    onSecondary = Color.White,
    background = Color.White,
    onBackground = Color(0xFF1C1C1C) // deep charcoal for content
)

private val DarkTheme = darkColorScheme(
    onPrimary = Color(0xFF1C1C1C),
    onSecondary = Color(0xFF2C2C2C),
    background = Color.Black,
    onBackground = Color(0xFFF5F5F5) // near-white for content on dark
)

private data class Palette(val primary: Color, val secondary: Color, val background: Color)

private val DefaultPalette = Palette(
    primary   = Color(0xFF9575CD), // Lighter Purple (Purple 300)
    secondary = Color(0xFFB0BEC5), // Blue Grey 200 – cool, modern
    background= Color(0xFFF5F5F5)  // Neutral light background
)

private val BluePalette = Palette(
    primary   = Color(0xFF1E88E5), // Blue 600
    secondary = Color(0xFF90CAF9), // Blue 200
    background= Color(0xFFE3F2FD)  // light sky
)

private val GreenPalette = Palette(
    primary   = Color(0xFF43A047), // Green 600
    secondary = Color(0xFFA5D6A7), // Green 200
    background= Color(0xFFE8F5E9)  // minty fresh
)

private val RedPalette = Palette(
    primary   = Color(0xFFE53935), // Red 600
    secondary = Color(0xFFEF9A9A), // Red 200
    background= Color(0xFFFFEBEE)  // blush
)

enum class ColorScheme { Default, Blue, Green, Red, Custom }

@Composable
fun MoneyBaseTheme(
    colorScheme: ColorScheme = ColorScheme.Default,
    darkMode: Boolean = false,
    customColorHex: String? = null,
    content: @Composable () -> Unit
) {
    // base on light/dark
    val baseScheme = if (darkMode) DarkTheme else LightTheme

    // pick the palette
    val palette = when (colorScheme) {
        ColorScheme.Default -> DefaultPalette
        ColorScheme.Blue    -> BluePalette
        ColorScheme.Green   -> GreenPalette
        ColorScheme.Red     -> RedPalette
        ColorScheme.Custom  -> {
            val customColor = customColorHex?.toColorOrNull() ?: ColorPalette.defaultColor
            Palette(
                primary = customColor,
                secondary = customColor,
                background = if (darkMode) Color.Black else Color.White
            )
        }
    }

    // merge in primary, secondary, and background
    val colors = baseScheme.copy(
        primary   = palette.primary,
        secondary = palette.secondary,
        background = if (darkMode) Color.Black else palette.background
    )

    MaterialTheme(
        colorScheme = colors,
        content = content
    )
}

fun getIconColorForScheme(scheme: ColorScheme, customHex: String? = null): Color = when (scheme) {
    ColorScheme.Default -> DefaultPalette.primary
    ColorScheme.Blue    -> BluePalette.primary
    ColorScheme.Green   -> GreenPalette.primary
    ColorScheme.Red     -> RedPalette.primary
    ColorScheme.Custom  -> customHex?.toColorOrNull() ?: ColorPalette.defaultColor
}
