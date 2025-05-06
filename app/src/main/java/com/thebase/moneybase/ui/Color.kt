package com.thebase.moneybase.ui

import androidx.compose.ui.graphics.Color

object ColorPalette {

    // Predefined named color map for consistent usage across the app
    val colorMap: Map<String, Color> = mapOf(
        "red" to Color(0xFFF44336),
        "pink" to Color(0xFFE91E63),
        "purple" to Color(0xFF9C27B0),
        "deep_purple" to Color(0xFF673AB7),
        "indigo" to Color(0xFF3F51B5),
        "blue" to Color(0xFF2196F3),
        "light_blue" to Color(0xFF03A9F4),
        "cyan" to Color(0xFF00BCD4),
        "teal" to Color(0xFF009688),
        "green" to Color(0xFF4CAF50),
        "light_green" to Color(0xFF8BC34A),
        "lime" to Color(0xFFCDDC39),
        "amber" to Color(0xFFFFC107),
        "orange" to Color(0xFFFF9800),
        "deep_orange" to Color(0xFFFF5722),
        "brown" to Color(0xFF795548),
        "grey" to Color(0xFF9E9E9E),
        "blue_grey" to Color(0xFF607D8B),
        "black" to Color(0xFF000000)
    )

    // Lazily generated reverse map: hex string → color name
    val reverseColorMap: Map<String, String> by lazy {
        colorMap.entries.associate { (name, color) -> color.toHexString() to name }
    }

    val defaultColor = Color(0xFF2196F3) // Default fallback color: blue

    /**
     * Returns hex code of a color by name, or default if not found.
     */
    fun getHexCode(colorName: String): String {
        return colorMap[colorName]?.toHexString() ?: defaultColor.toHexString()
    }
}

/**
 * Converts a Color object to a hex string (e.g., "#2196F3").
 */
fun Color.toHexString(): String {
    val red = (red * 255).toInt()
    val green = (green * 255).toInt()
    val blue = (blue * 255).toInt()
    return String.format("#%02X%02X%02X", red, green, blue)
}