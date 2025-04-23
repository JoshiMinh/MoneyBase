package com.thebase.moneybase.data

import androidx.compose.ui.graphics.Color

object ColorPalette {
    val colorMap: Map<String, Color> = mapOf(

        "red" to Color(0xFFF44336),
        "pink" to Color(0xFFE91E63),
        "purple" to Color(0xFF9C27B0),
        "indigo" to Color(0xFF3F51B5),
        "light_blue" to Color(0xFF03A9F4),
        "teal" to Color(0xFF009688),
        "green" to Color(0xFF4CAF50),
        "orange" to Color(0xFFFF9800),
        "brown" to Color(0xFF795548),

        // Adding 10 more extra nice ones
        "deep_orange" to Color(0xFFFF5722),
        "amber" to Color(0xFFFFC107),
        "lime" to Color(0xFFCDDC39),
        "light_green" to Color(0xFF8BC34A),
        "cyan" to Color(0xFF00BCD4),
        "blue_grey" to Color(0xFF607D8B),
        "deep_purple" to Color(0xFF673AB7),
        "blue" to Color(0xFF2196F3),
        "grey" to Color(0xFF9E9E9E),
        "black" to Color(0xFF000000)
    )

    val reverseColorMap: Map<String, String> by lazy {
        colorMap.entries.associate { (name, color) -> color.toHexString() to name }
    }

    val defaultColor = Color(0xFF2196F3)

    fun getHexCode(colorName: String): String {
        return colorMap[colorName]?.toHexString() ?: defaultColor.toHexString()
    }
}

fun Color.toHexString(): String {
    val red = (red * 255).toInt()
    val green = (green * 255).toInt()
    val blue = (blue * 255).toInt()
    return String.format("#%02X%02X%02X", red, green, blue)
}