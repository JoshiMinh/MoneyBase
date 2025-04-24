package com.thebase.moneybase.functionalities.category

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Icon.getIcon

@Suppress("DEPRECATION")
@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun CategorySelector(
    categories: List<Category>,
    onCategorySelected: (Category) -> Unit,
    onDismiss: () -> Unit,
    onAddCategory: () -> Unit,
    onEditCategory: (Category) -> Unit,
    onRemoveCategory: (Category) -> Unit
) {
    var actionCat by remember { mutableStateOf<Category?>(null) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        dragHandle = {},
        containerColor = MaterialTheme.colorScheme.background,
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
                    Icon(Icons.Default.Add, contentDescription = null)
                }
            }
            Divider()
            LazyColumn {
                items(categories) { cat ->
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
                            imageVector = getIcon(cat.iconName),
                            contentDescription = cat.name,
                            tint = Color(cat.color.toColorInt()),
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
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
                    actionCat = null // Reset actionCat after edit
                }) {
                    Text("Edit")
                }
            },
            dismissButton = {
                Row {
                    TextButton(onClick = {
                        onRemoveCategory(cat)
                        actionCat = null // Reset actionCat after removal
                    }) {
                        Text("Remove")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    TextButton(onClick = { actionCat = null }) {
                        Text("Cancel")
                    }
                }
            }
        )
    }
}
