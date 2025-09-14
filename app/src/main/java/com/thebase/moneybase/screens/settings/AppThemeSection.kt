package com.thebase.moneybase.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.ui.ColorScheme
import com.thebase.moneybase.ui.getIconColorForScheme
import com.thebase.moneybase.ui.toColorOrNull

@Composable
fun AppThemeSection(
    selectedScheme: ColorScheme,
    onSchemeChange: (ColorScheme) -> Unit,
    darkMode: Boolean,
    onDarkModeToggle: (Boolean) -> Unit,
    customColorHex: String,
    onCustomColorChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        // Dark Mode Toggle
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.DarkMode,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("Dark Mode", style = MaterialTheme.typography.bodyLarge)
                Text(
                    text = if (darkMode) "On" else "Off",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Switch(
                checked = darkMode,
                onCheckedChange = onDarkModeToggle
            )
        }

        Spacer(Modifier.height(16.dp))
        Text("Select Color Scheme", style = MaterialTheme.typography.bodyLarge)
        Spacer(Modifier.height(8.dp))

        // Color Scheme Picker
        Row(
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(vertical = 8.dp)
        ) {
            ColorScheme.entries.forEach { scheme ->
                val isSelected = scheme == selectedScheme
                val baseColor = getIconColorForScheme(scheme, customColorHex)
                val displayColor = if (isSelected) baseColor.copy(alpha = 0.5f) else baseColor

                IconButton(
                    onClick = { onSchemeChange(scheme) },
                    modifier = Modifier
                        .padding(horizontal = 8.dp)
                        .size(48.dp)
                        .border(
                            width = if (isSelected) 2.dp else 1.dp,
                            color = if (isSelected)
                                MaterialTheme.colorScheme.primary
                            else Color.Gray,
                            shape = CircleShape
                        )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(color = displayColor, shape = CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        if (isSelected) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = "Selected",
                                tint = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                }
            }
        }

        if (selectedScheme == ColorScheme.Custom) {
            Spacer(Modifier.height(16.dp))
            HexColorPicker(hex = customColorHex, onHexChange = onCustomColorChange)
        }
    }
}

@Composable
private fun HexColorPicker(hex: String, onHexChange: (String) -> Unit) {
    val display = hex
    val previewColor = display.toColorOrNull() ?: Color.Transparent

    OutlinedTextField(
        value = display,
        onValueChange = {
            if (it.length <= 7 && it.matches(Regex("#?[0-9a-fA-F]*"))) {
                val formatted = if (it.startsWith("#")) it else "#" + it
                onHexChange(formatted)
            }
        },
        label = { Text("Hex Color") },
        leadingIcon = {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(
                        previewColor.takeIf { it != Color.Transparent } ?: Color.Gray,
                        CircleShape
                    )
            )
        }
    )
}

