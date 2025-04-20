package com.thebase.moneybase.functionalities.category

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import com.thebase.moneybase.data.Category
import java.util.UUID

private const val DEFAULT_ICON_NAME = "shopping_cart"
private const val DEFAULT_COLOR = "#2196F3"

@Composable
fun AddCategoryDialog(
    onDismiss: () -> Unit,
    onCategoryAdded: (Category) -> Unit
) {
    var name by rememberSaveable { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(text = "New Category") },
        text = {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text(text = "Name") },
                singleLine = true
            )
        },
        confirmButton = {
            TextButton(onClick = {
                onCategoryAdded(
                    Category(
                        id = UUID.randomUUID().toString(),
                        name = name,
                        iconName = DEFAULT_ICON_NAME,
                        color = DEFAULT_COLOR
                    )
                )
                onDismiss()
            }) {
                Text(text = "Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(text = "Cancel")
            }
        }
    )
}

@Composable
fun EditCategoryDialog(
    category: Category,
    onDismiss: () -> Unit,
    onCategoryUpdated: (Category) -> Unit
) {
    var name by rememberSaveable { mutableStateOf(category.name) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(text = "Edit Category") },
        text = {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text(text = "Name") },
                singleLine = true
            )
        },
        confirmButton = {
            TextButton(onClick = {
                onCategoryUpdated(category.copy(name = name))
                onDismiss()
            }) {
                Text(text = "Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(text = "Cancel")
            }
        }
    )
}