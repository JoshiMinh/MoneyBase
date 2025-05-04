package com.thebase.moneybase.functionalities.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.firebase.Category
import com.thebase.moneybase.functionalities.customizability.Icon
import com.thebase.moneybase.functionalities.customizability.ColorPalette
import kotlinx.coroutines.launch

@Composable
fun AddCategoryDialog(
    existingCategories: List<Category>,
    userId: String,
    onCategoryAdded: suspend (Category) -> Unit,
    onDismiss: () -> Unit,
    showError: (String) -> Unit
) {
    var name by rememberSaveable { mutableStateOf("") }
    var selectedIcon by rememberSaveable { mutableStateOf("shopping_cart") }
    var selectedColor by rememberSaveable { mutableStateOf("blue") }
    val scope = rememberCoroutineScope()

    CategoryDialogContent(
        title = "New Category",
        name = name,
        onNameChange = { name = it },
        selectedIcon = selectedIcon,
        onIconSelected = { selectedIcon = it },
        selectedColor = selectedColor,
        onColorSelected = { selectedColor = it },
        showDelete = false,
        onConfirm = {
            scope.launch {
                when {
                    name.isBlank() -> showError("Category name cannot be empty")
                    existingCategories.any { it.name.equals(name, true) } ->
                        showError("A category with this name already exists")
                    else -> {
                        val newCat = Category(
                            id = "",
                            userId = userId,
                            name = name.trim(),
                            iconName = selectedIcon,
                            color = ColorPalette.getHexCode(selectedColor)
                        )
                        onCategoryAdded(newCat)
                        onDismiss()
                    }
                }
            }
        },
        onDelete = null,
        onDismiss = onDismiss
    )
}

@Composable
fun EditCategoryDialog(
    category: Category,
    userId: String,
    onCategoryUpdated: suspend (Category) -> Unit,
    onCategoryDeleted: suspend (Category) -> Unit,
    onDismiss: () -> Unit,
    showError: (String) -> Unit
) {
    var name by rememberSaveable { mutableStateOf(category.name) }
    var selectedIcon by rememberSaveable { mutableStateOf(category.iconName) }
    var selectedColor by rememberSaveable {
        mutableStateOf(ColorPalette.reverseColorMap[category.color] ?: "blue")
    }
    val scope = rememberCoroutineScope()

    CategoryDialogContent(
        title = "Edit Category",
        name = name,
        onNameChange = { name = it },
        selectedIcon = selectedIcon,
        onIconSelected = { selectedIcon = it },
        selectedColor = selectedColor,
        onColorSelected = { selectedColor = it },
        showDelete = true,
        onConfirm = {
            scope.launch {
                if (name.isBlank()) {
                    showError("Category name cannot be empty")
                    return@launch
                }
                val updated = category.copy(
                    name = name.trim(),
                    iconName = selectedIcon,
                    color = ColorPalette.getHexCode(selectedColor)
                )
                onCategoryUpdated(updated)
                onDismiss()
            }
        },
        onDelete = {
            scope.launch {
                onCategoryDeleted(category)
                onDismiss()
            }
        },
        onDismiss = onDismiss
    )
}

@Composable
private fun CategoryDialogContent(
    title: String,
    name: String,
    onNameChange: (String) -> Unit,
    selectedIcon: String,
    onIconSelected: (String) -> Unit,
    selectedColor: String,
    onColorSelected: (String) -> Unit,
    showDelete: Boolean,
    onConfirm: () -> Unit,
    onDelete: (() -> Unit)?,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = onNameChange,
                    label = { Text("Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Choose an icon", style = MaterialTheme.typography.labelLarge)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(Icon.iconMap.keys.toList()) { iconName ->
                        Surface(
                            modifier = Modifier
                                .size(48.dp)
                                .clickable { onIconSelected(iconName) },
                            shape = CircleShape,
                            tonalElevation = if (iconName == selectedIcon) 4.dp else 0.dp,
                            border = if (iconName == selectedIcon)
                                BorderStroke(2.dp, MaterialTheme.colorScheme.primary)
                            else null
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = Icon.getIcon(iconName),
                                    contentDescription = iconName
                                )
                            }
                        }
                    }
                }
                Text("Choose a color", style = MaterialTheme.typography.labelLarge)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(ColorPalette.colorMap.keys.toList()) { colorKey ->
                        val colorValue = ColorPalette.colorMap[colorKey]!!
                        Surface(
                            modifier = Modifier
                                .size(36.dp)
                                .clickable { onColorSelected(colorKey) },
                            shape = CircleShape,
                            tonalElevation = if (colorKey == selectedColor) 4.dp else 0.dp,
                            border = if (colorKey == selectedColor)
                                BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                            else null,
                            color = colorValue
                        ) {}
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onConfirm) { Text("Save") }
        },
        dismissButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (showDelete && onDelete != null) {
                    TextButton(onClick = onDelete) {
                        Text("Delete", color = MaterialTheme.colorScheme.error)
                    }
                }
                TextButton(onClick = onDismiss) { Text("Cancel") }
            }
        }
    )
}