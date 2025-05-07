package com.thebase.moneybase.utils.components

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.ui.Icon

@Suppress("DEPRECATION", "unused")
@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun CategorySelector(
    categories: List<Category>,
    userId: String,
    onCategorySelected: (Category) -> Unit,
    onAddCategory: () -> Unit,
    onEditCategory: (Category) -> Unit,
    onRemoveCategory: (Category) -> Unit,
    onDismiss: () -> Unit
) {
    var actionCategory by remember { mutableStateOf<Category?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        tonalElevation = 8.dp
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Select Category", style = MaterialTheme.typography.titleMedium)
                IconButton(onClick = onAddCategory) {
                    Icon(Icons.Default.Add, contentDescription = "Add")
                }
            }
            Divider(modifier = Modifier.padding(vertical = 8.dp))
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 400.dp)
            ) {
                items(categories, key = { it.id }) { cat ->
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                            .combinedClickable(
                                onClick = {
                                    onCategorySelected(cat)
                                    onDismiss()
                                },
                                onLongClick = { actionCategory = cat }
                            ),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icon.getIcon(cat.iconName),
                            contentDescription = cat.name,
                            tint = runCatching { Color(cat.color.toColorInt()) }
                                .getOrElse { MaterialTheme.colorScheme.primary }
                        )
                        Spacer(Modifier.width(12.dp))
                        Text(cat.name, style = MaterialTheme.typography.bodyLarge)
                    }
                }
            }
        }
    }

    actionCategory?.let { cat ->
        AlertDialog(
            onDismissRequest = { actionCategory = null },
            title = { Text(cat.name) },
            text = { Text("What would you like to do?") },
            confirmButton = {
                TextButton(onClick = {
                    onEditCategory(cat)
                    actionCategory = null
                }) { Text("Edit") }
            },
            dismissButton = {
                Column {
                    TextButton(onClick = {
                        onRemoveCategory(cat)
                        actionCategory = null
                        onDismiss()
                    }) {
                        Text("Delete", color = MaterialTheme.colorScheme.error)
                    }
                    TextButton(onClick = { actionCategory = null }) {
                        Text("Cancel")
                    }
                }
            }
        )
    }
}