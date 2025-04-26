package com.thebase.moneybase.functionalities.components

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
import com.thebase.moneybase.firebase.Category
import com.thebase.moneybase.firebase.CategoryRepository
import com.thebase.moneybase.functionalities.customizability.Icon
import kotlinx.coroutines.launch

@Suppress("DEPRECATION")
@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun CategorySelector(
    categories: List<Category>,
    onCategorySelected: (Category) -> Unit,
    onDismiss: () -> Unit,
    onAddCategory: () -> Unit,
    onEditCategory: (Category) -> Unit,
    onRemoveCategory: (Category) -> Unit,
    userId: String
) {
    val categoryRepo = remember { CategoryRepository() }
    val scope = rememberCoroutineScope()
    var actionCat by remember { mutableStateOf<Category?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        containerColor = MaterialTheme.colorScheme.surfaceContainer,
        tonalElevation = 4.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Select Category",
                    style = MaterialTheme.typography.titleMedium
                )
                IconButton(onClick = onAddCategory) {
                    Icon(Icons.Default.Add, contentDescription = "Add category")
                }
            }
            Divider(Modifier.padding(vertical = 8.dp))

            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(max = 400.dp)
            ) {
                items(categories, key = { it.id }) { cat ->  // Fixed items usage
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp)
                            .combinedClickable(
                                onClick = { onCategorySelected(cat) },
                                onLongClick = { actionCat = cat }
                            ),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icon.getIcon(cat.iconName),  // Fixed icon reference
                            contentDescription = cat.name,
                            tint = try {
                                Color(cat.color.toColorInt())
                            } catch (e: Exception) {
                                MaterialTheme.colorScheme.primary
                            },
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(Modifier.width(12.dp))
                        Text(
                            text = cat.name,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
            }
        }
    }

    actionCat?.let { cat ->
        AlertDialog(
            onDismissRequest = { actionCat = null },
            title = { Text(cat.name) },
            text = { Text("What do you want to do?") },
            confirmButton = {
                TextButton(onClick = {
                    onEditCategory(cat)
                    actionCat = null
                }) {
                    Text("Edit")
                }
            },
            dismissButton = {
                Column {
                    TextButton(
                        onClick = {
                            scope.launch {
                                categoryRepo.deleteCategory(userId, cat.id)
                                onRemoveCategory(cat)
                            }
                            actionCat = null
                        }
                    ) {
                        Text("Delete", color = MaterialTheme.colorScheme.error)
                    }
                    TextButton(onClick = { actionCat = null }) {
                        Text("Cancel")
                    }
                }
            }
        )
    }
}