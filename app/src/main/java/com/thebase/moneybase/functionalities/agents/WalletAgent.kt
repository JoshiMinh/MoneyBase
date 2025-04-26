// WalletComponents.kt
package com.thebase.moneybase.functionalities.agents

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.firebase.*
import com.thebase.moneybase.functionalities.customizability.ColorPalette
import com.thebase.moneybase.functionalities.customizability.Icon

@Composable
fun WalletAgent(
    wallet: Wallet,
    onEditDone: (Wallet) -> Unit,
    onRemove: (Wallet) -> Unit,
    onDismiss: () -> Unit,
    userId: String
) {
    var showRemoveConfirmation by remember { mutableStateOf(false) }
    var showEditWallet by remember { mutableStateOf(false) }

    if (showRemoveConfirmation) {
        AlertDialog(
            onDismissRequest = { showRemoveConfirmation = false },
            title = { Text("Delete Wallet") },
            text = { Text("Are you sure you want to delete ${wallet.name}?") },
            confirmButton = {
                TextButton(onClick = {
                    onRemove(wallet)
                    showRemoveConfirmation = false
                    onDismiss()
                }) { Text("Delete") }
            },
            dismissButton = {
                TextButton(onClick = { showRemoveConfirmation = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showEditWallet) {
        EditWalletDialog(
            wallet = wallet,
            onDismiss = { showEditWallet = false },
            onSave = { updatedWallet ->
                onEditDone(updatedWallet)
                showEditWallet = false
            },
            onDelete = {
                showEditWallet = false
                showRemoveConfirmation = true
            },
            userId = userId
        )
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {},
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp) // Fixed: Added closing parenthesis
            ) {
                Text(wallet.name, style = MaterialTheme.typography.titleMedium)
                Button(
                    onClick = { showEditWallet = true },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Edit") }
                Button(
                    onClick = { showRemoveConfirmation = true },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    ),
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Remove") }
            }
        }
    )
}

@Composable
fun AddWallet(
    onDismiss: () -> Unit,
    onWalletAdded: (Wallet) -> Unit,
    userId: String
) {
    var name by rememberSaveable { mutableStateOf("") }
    var type by rememberSaveable { mutableStateOf(Wallet.WalletType.OTHER) }
    var currency by rememberSaveable { mutableStateOf("USD") }
    var balance by rememberSaveable { mutableStateOf("0.0") }
    var colorName by rememberSaveable { mutableStateOf("purple") }
    var selectedIcon by rememberSaveable { mutableStateOf("account_balance_wallet") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create New Wallet") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Wallet Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = balance,
                    onValueChange = {
                        if (it.isValidDecimal()) balance = it
                    },
                    label = { Text("Initial Balance") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                WalletTypeDropdown(type) { type = it }
                OutlinedTextField(
                    value = currency,
                    onValueChange = { currency = it.take(3).uppercase() },
                    label = { Text("Currency Code") },
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Choose a Color", style = MaterialTheme.typography.labelLarge)
                ColorSelector(colorName) { colorName = it }
                Spacer(modifier = Modifier.height(12.dp))
                Text("Choose an Icon", style = MaterialTheme.typography.labelLarge)
                IconSelector(selectedIcon) { selectedIcon = it }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onWalletAdded(
                        Wallet(
                            name = name,
                            type = type,
                            currencyCode = currency,
                            balance = balance.toDoubleOrNull() ?: 0.0,
                            userId = userId,
                            iconName = selectedIcon,
                            color = ColorPalette.getHexCode(colorName)
                        ))
                },
                enabled = name.isNotBlank()
            ) { Text("Create") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
private fun EditWalletDialog(
    wallet: Wallet,
    onDismiss: () -> Unit,
    onSave: (Wallet) -> Unit,
    onDelete: () -> Unit,
    userId: String
) {
    var name by rememberSaveable { mutableStateOf(wallet.name) }
    var type by rememberSaveable { mutableStateOf(wallet.type) }
    var currency by rememberSaveable { mutableStateOf(wallet.currencyCode) }
    var balance by rememberSaveable { mutableStateOf(wallet.balance.toString()) }
    var colorName by rememberSaveable {
        mutableStateOf(
            ColorPalette.reverseColorMap[wallet.color] ?: "purple"
        )
    }
    var selectedIcon by rememberSaveable { mutableStateOf(wallet.iconName) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Wallet") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Wallet Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = balance,
                    onValueChange = {
                        if (it.isValidDecimal()) balance = it
                    },
                    label = { Text("Balance") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                WalletTypeDropdown(type) { type = it }
                OutlinedTextField(
                    value = currency,
                    onValueChange = { currency = it.take(3).uppercase() },
                    label = { Text("Currency Code") },
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Choose a Color", style = MaterialTheme.typography.labelLarge)
                ColorSelector(colorName) { colorName = it }
                Spacer(modifier = Modifier.height(12.dp))
                Text("Choose an Icon", style = MaterialTheme.typography.labelLarge)
                IconSelector(selectedIcon) { selectedIcon = it }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onSave(
                        wallet.copy(
                            name = name,
                            type = type,
                            currencyCode = currency,
                            balance = balance.toDoubleOrNull() ?: 0.0,
                            color = ColorPalette.getHexCode(colorName),
                            iconName = selectedIcon,
                            userId = userId
                        )
                    )
                },
                enabled = name.isNotBlank()
            ) { Text("Save") }
        },
        dismissButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(
                    onClick = onDelete,
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) { Text("Delete") }
                TextButton(onClick = onDismiss) { Text("Cancel") }
            }
        }
    )
}

@Composable
private fun ColorSelector(selectedColor: String, onColorSelected: (String) -> Unit) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        modifier = Modifier.fillMaxWidth().height(56.dp)
    ) {
        items(ColorPalette.colorMap.keys.toList()) { colorName ->
            val color = ColorPalette.colorMap[colorName] ?: ColorPalette.defaultColor
            Surface(
                modifier = Modifier
                    .size(40.dp)
                    .clickable { onColorSelected(colorName) },
                shape = CircleShape,
                tonalElevation = if (selectedColor == colorName) 6.dp else 0.dp,
                border = if (selectedColor == colorName)
                    BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                else null,
                color = color
            ) {}
        }
    }
}

@Composable
private fun IconSelector(selectedIcon: String, onIconSelected: (String) -> Unit) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        modifier = Modifier.fillMaxWidth().height(56.dp)
    ) {
        items(Icon.iconMap.keys.toList()) { iconName ->
            val icon = Icon.iconMap[iconName]
            Surface(
                modifier = Modifier
                    .size(48.dp)
                    .clickable { onIconSelected(iconName) },
                shape = CircleShape,
                tonalElevation = if (selectedIcon == iconName) 6.dp else 0.dp,
                border = if (selectedIcon == iconName)
                    BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                else null,
                color = MaterialTheme.colorScheme.surfaceVariant
            ) {
                Box(contentAlignment = Alignment.Center) {
                    icon?.let {
                        Icon(it, iconName, tint = MaterialTheme.colorScheme.onSurface)
                    }
                }
            }
        }
    }
}

@Composable
private fun WalletTypeDropdown(
    selected: Wallet.WalletType,
    onSelect: (Wallet.WalletType) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    Box(Modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = selected.name.replace("_", " "),
            onValueChange = {},
            readOnly = true,
            trailingIcon = {
                Icon(Icons.Default.ArrowDropDown, null, Modifier.clickable { expanded = true })
            },
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = true }
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            Wallet.WalletType.entries.forEach { type ->
                DropdownMenuItem(
                    text = { Text(type.name.replace("_", " ")) },
                    onClick = {
                        onSelect(type)
                        expanded = false
                    }
                )
            }
        }
    }
}

private fun String.isValidDecimal(): Boolean {
    return matches(Regex("^\\d*\\.?\\d*$")) && count { it == '.' } <= 1
}
