package com.thebase.moneybase.functionalities.agents

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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.firebase.*
import com.thebase.moneybase.functionalities.customizability.Icon
import kotlinx.coroutines.launch
import com.thebase.moneybase.functionalities.customizability.ColorPalette

@Composable
fun AddCategoryDialog(
    onDismiss: () -> Unit,
    onCategoryAdded: suspend (Category) -> Unit,
    existingCategories: List<Category>,
    userId: String,
    showError: (String) -> Unit
) {
    var name by rememberSaveable { mutableStateOf("") }
    var selectedIcon by rememberSaveable { mutableStateOf("shopping_cart") }
    var selectedColor by rememberSaveable { mutableStateOf("#2196F3") }
    val scope = rememberCoroutineScope()

    CategoryDialogContent(
        name = name,
        onNameChange = { name = it },
        selectedIcon = selectedIcon,
        onIconSelected = { selectedIcon = it },
        selectedColor = selectedColor,
        onColorSelected = { selectedColor = it },
        onConfirm = {
            scope.launch {
                try {
                    if (name.isBlank()) {
                        showError("Category name cannot be empty")
                        return@launch
                    }

                    if (existingCategories.any { it.name.equals(name, true) }) {
                        showError("Category with this name already exists")
                        return@launch
                    }

                    val category = Category(
                        id = "",
                        name = name,
                        iconName = selectedIcon,
                        color = ColorPalette.getHexCode(selectedColor),
                        userId = userId
                    )
                    onCategoryAdded(category)
                    onDismiss()
                } catch (e: Exception) {
                    showError("Failed to create category: ${e.message}")
                }
            }
        },
        onDismiss = onDismiss,
        showDelete = false
    )
}

@Composable
fun EditCategoryDialog(
    category: Category,
    onDismiss: () -> Unit,
    onCategoryUpdated: suspend (Category) -> Unit,
    onCategoryDeleted: suspend (Category) -> Unit,
    userId: String,
    showError: (String) -> Unit
) {
    var name by rememberSaveable { mutableStateOf(category.name) }
    var selectedIcon by rememberSaveable { mutableStateOf(category.iconName) }
    var selectedColor by rememberSaveable { mutableStateOf(category.color) }
    val scope = rememberCoroutineScope()

    CategoryDialogContent(
        name = name,
        onNameChange = { name = it },
        selectedIcon = selectedIcon,
        onIconSelected = { selectedIcon = it },
        selectedColor = selectedColor,
        onColorSelected = { selectedColor = it },
        onConfirm = {
            scope.launch {
                try {
                    if (name.isBlank()) {
                        showError("Category name cannot be empty")
                        return@launch
                    }

                    val updatedCategory = category.copy(
                        name = name,
                        iconName = selectedIcon,
                        color = selectedColor,
                        userId = userId
                    )
                    onCategoryUpdated(updatedCategory)
                    onDismiss()
                } catch (e: Exception) {
                    showError("Failed to update category: ${e.message}")
                }
            }
        },
        onDismiss = onDismiss,
        showDelete = true,
        onDelete = {
            scope.launch {
                try {
                    onCategoryDeleted(category)
                    onDismiss()
                } catch (e: Exception) {
                    showError("Failed to delete category: ${e.message}")
                }
            }
        }
    )
}

@Composable
private fun CategoryDialogContent(
    name: String,
    onNameChange: (String) -> Unit,
    selectedIcon: String,
    onIconSelected: (String) -> Unit,
    selectedColor: String,
    onColorSelected: (String) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    showDelete: Boolean,
    onDelete: (() -> Unit)? = null
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(text = "Category") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = onNameChange,
                    label = { Text("Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Text("Choose an Icon", style = MaterialTheme.typography.labelLarge)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(Icon.iconMap.keys.toList()) { iconName ->
                        val icon = Icon.getIcon(iconName)
                        Surface(
                            modifier = Modifier
                                .size(56.dp)
                                .clickable { onIconSelected(iconName) },
                            shape = CircleShape,
                            color = if (selectedIcon == iconName) MaterialTheme.colorScheme.primary.copy(alpha = 0.2f) else Color.Transparent,
                            border = if (selectedIcon == iconName) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Icon(
                                    imageVector = icon,
                                    contentDescription = iconName,
                                    tint = MaterialTheme.colorScheme.onSurface
                                )
                            }
                        }
                    }
                }

                Text("Choose a Color", style = MaterialTheme.typography.labelLarge)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(ColorPalette.colorMap.keys.toList()) { colorName ->
                        val color = ColorPalette.colorMap[colorName] ?: ColorPalette.defaultColor
                        Surface(
                            modifier = Modifier
                                .size(40.dp)
                                .clickable { onColorSelected(colorName) },
                            shape = CircleShape,
                            color = color,
                            border = if (selectedColor == colorName) BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface) else null
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