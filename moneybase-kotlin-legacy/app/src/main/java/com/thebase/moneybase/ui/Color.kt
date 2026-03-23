package com.thebase.moneybase.ui

import androidx.compose.ui.graphics.Color
import androidx.core.graphics.toColorInt
import java.util.Locale

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
        "yellow" to Color(0xFFFFEB3B),
        "amber" to Color(0xFFFFC107),
        "orange" to Color(0xFFFF9800),
        "deep_orange" to Color(0xFFFF5722),
        "brown" to Color(0xFF795548),
        "grey" to Color(0xFF9E9E9E),
        "blue_grey" to Color(0xFF607D8B),
        "black" to Color(0xFF000000)
    )

    private val normalizedColorMap: Map<String, Color> =
        colorMap.mapKeys { it.key.lowercase(Locale.ROOT) }

    // Lazily generated reverse map: hex string → color name
    val reverseColorMap: Map<String, String> by lazy {
        buildMap {
            colorMap.forEach { (name, color) ->
                put(color.toHexString(), name)
                put(name.lowercase(Locale.ROOT), name)
            }
        }
    }

    val defaultColor = Color(0xFF2196F3) // Default fallback color: blue

    /**
     * Returns hex code of a color by name, or default if not found.
     */
    fun getHexCode(colorName: String): String {
        val lookupKey = colorName.trim()
        if (lookupKey.isEmpty()) return defaultColor.toHexString()

        val paletteMatch = normalizedColorMap[lookupKey.lowercase(Locale.ROOT)]
        if (paletteMatch != null) {
            return paletteMatch.toHexString()
        }

        val normalizedHex = normalizeHexCandidate(lookupKey)
        return normalizedHex ?: defaultColor.toHexString()
    }

    /**
     * Attempts to resolve the canonical palette key (e.g. "blue") for a stored color value.
     */
    fun resolveColorKey(colorValue: String): String? {
        val lookup = colorValue.trim()
        if (lookup.isEmpty()) return null

        colorMap.keys.firstOrNull { it.equals(lookup, ignoreCase = true) }?.let { return it }

        val normalizedHex = normalizeHexCandidate(lookup) ?: return null
        return reverseColorMap[normalizedHex]
    }

    /**
     * Attempts to resolve a Compose [Color] from the provided value. Supports palette keys
     * (e.g. "blue") and hex strings in the forms `#RRGGBB`, `#AARRGGBB`, `RRGGBB`, `AARRGGBB`,
     * or `0xAARRGGBB`.
     */
    fun resolveColor(value: String): Color? {
        val lookup = value.trim()
        if (lookup.isEmpty()) return null

        normalizedColorMap[lookup.lowercase(Locale.ROOT)]?.let { return it }

        val normalizedHex = normalizeHexCandidate(lookup) ?: return null
        return normalizedHex.toColorOrNull()
    }

    private fun normalizeHexCandidate(value: String): String? {
        var hex = value.trim()
        if (hex.isEmpty()) return null

        hex = when {
            hex.startsWith("#") -> hex.substring(1)
            hex.startsWith("0x", ignoreCase = true) -> hex.substring(2)
            else -> hex
        }

        if (hex.length == 6 || hex.length == 8) {
            return "#" + hex.uppercase(Locale.ROOT)
        }

        return null
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

/**
 * Converts a hex string (e.g. "#FF0000") to a [Color] or returns null if invalid.
 */
fun String.toColorOrNull(): Color? = runCatching { Color(this.toColorInt()) }.getOrNull()

/**
 * Attempts to resolve the string into a palette-backed [Color]. Returns null if parsing fails.
 */
fun String?.toResolvedColor(): Color? = this?.let { ColorPalette.resolveColor(it) }
