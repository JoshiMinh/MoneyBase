package com.thebase.moneybase.functionalities.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.firebase.Wallet
import com.thebase.moneybase.functionalities.customizability.ColorPalette
import com.thebase.moneybase.functionalities.customizability.Icon

@Composable
fun WalletAgent(
    wallet: Wallet,
    onEditDone: (Wallet) -> Unit,
    onRemove: (Wallet) -> Unit,
    onDismiss: () -> Unit
) {
    var confirmDelete by remember { mutableStateOf(false) }
    var editMode by remember { mutableStateOf(false) }

    // Delete confirmation
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete \"${wallet.name}\"?") },
            text = { Text("This will remove the wallet and all its transactions.") },
            confirmButton = {
                TextButton(onClick = {
                    onRemove(wallet)
                    confirmDelete = false
                    onDismiss()
                }) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Edit dialog
    if (editMode) {
        EditWallet(
            wallet = wallet,
            onSave = { updated ->
                onEditDone(updated)
                editMode = false
                onDismiss()
            },
            onDelete = {
                editMode = false
                confirmDelete = true
            },
            onDismiss = { editMode = false }
        )
    }

    // Main agent dialog
    if (!confirmDelete && !editMode) {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text(wallet.name) },
            text = {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = { editMode = true },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Edit")
                    }
                    Button(
                        onClick = { confirmDelete = true },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        ),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Remove")
                    }
                }
            },
            confirmButton = {},
            dismissButton = {
                TextButton(onClick = onDismiss) {
                    Text("Close")
                }
            }
        )
    }
}

@Composable
fun AddWallet(
    onDismiss: () -> Unit,
    onWalletAdded: (Wallet) -> Unit
) {
    var name by rememberSaveable { mutableStateOf("") }
    var balance by rememberSaveable { mutableStateOf("0.0") }
    var type by rememberSaveable { mutableStateOf(Wallet.WalletType.OTHER) }
    var currency by rememberSaveable { mutableStateOf("USD") }
    // Initialize directly inside rememberSaveable
    var colorKey by rememberSaveable {
        mutableStateOf(ColorPalette.reverseColorMap.entries
            .firstOrNull { it.value == Wallet().color }?.key
            ?: "purple")
    }
    var iconKey by rememberSaveable { mutableStateOf("account_balance_wallet") }

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
                    onValueChange = { if (it.isValidDecimal()) balance = it },
                    label = { Text("Initial Balance") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                WalletTypeDropdown(selected = type, onSelect = { type = it })
                OutlinedTextField(
                    value = currency,
                    onValueChange = { currency = it.take(3).uppercase() },
                    label = { Text("Currency Code") },
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Choose a Color", style = MaterialTheme.typography.labelLarge)
                ColorSelector(selected = colorKey, onSelect = { colorKey = it })
                Spacer(Modifier.height(12.dp))
                Text("Choose an Icon", style = MaterialTheme.typography.labelLarge)
                IconSelector(selected = iconKey, onSelect = { iconKey = it })
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onWalletAdded(
                        Wallet(
                            id = "",
                            name = name.trim(),
                            balance = balance.toDoubleOrNull() ?: 0.0,
                            type = type,
                            currencyCode = currency,
                            userId = "", // inject as needed
                            color = ColorPalette.getHexCode(colorKey),
                            iconName = iconKey
                        )
                    )
                },
                enabled = name.isNotBlank()
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
fun EditWallet(
    wallet: Wallet,
    onSave: (Wallet) -> Unit,
    onDelete: () -> Unit,
    onDismiss: () -> Unit
) {
    var name by rememberSaveable { mutableStateOf(wallet.name) }
    var balance by rememberSaveable { mutableStateOf(wallet.balance.toString()) }
    var type by rememberSaveable { mutableStateOf(wallet.type) }
    var currency by rememberSaveable { mutableStateOf(wallet.currencyCode) }
    // NO nested remember{}, just initialize via mutableStateOf
    var colorKey by rememberSaveable {
        mutableStateOf(ColorPalette.reverseColorMap[wallet.color] ?: "purple")
    }
    var iconKey by rememberSaveable { mutableStateOf(wallet.iconName) }

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
                    onValueChange = { if (it.isValidDecimal()) balance = it },
                    label = { Text("Balance") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                WalletTypeDropdown(selected = type, onSelect = { type = it })
                OutlinedTextField(
                    value = currency,
                    onValueChange = { currency = it.take(3).uppercase() },
                    label = { Text("Currency Code") },
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Choose a Color", style = MaterialTheme.typography.labelLarge)
                ColorSelector(selected = colorKey, onSelect = { colorKey = it })
                Spacer(Modifier.height(12.dp))
                Text("Choose an Icon", style = MaterialTheme.typography.labelLarge)
                IconSelector(selected = iconKey, onSelect = { iconKey = it })
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onSave(
                        wallet.copy(
                            name = name.trim(),
                            balance = balance.toDoubleOrNull() ?: wallet.balance,
                            type = type,
                            currencyCode = currency,
                            color = ColorPalette.getHexCode(colorKey),
                            iconName = iconKey
                        )
                    )
                },
                enabled = name.isNotBlank()
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(onClick = onDelete) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
                TextButton(onClick = onDismiss) {
                    Text("Cancel")
                }
            }
        }
    )
}

@Composable
private fun ColorSelector(
    selected: String,
    onSelect: (String) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
    ) {
        items(ColorPalette.colorMap.keys.toList()) { key ->
            val col = ColorPalette.colorMap[key]!!
            Surface(
                modifier = Modifier
                    .size(40.dp)
                    .clickable { onSelect(key) },
                shape = CircleShape,
                tonalElevation = if (selected == key) 6.dp else 0.dp,
                border = if (selected == key)
                    BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                else null,
                color = col
            ) {}
        }
    }
}

@Composable
private fun IconSelector(
    selected: String,
    onSelect: (String) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
    ) {
        items(Icon.iconMap.keys.toList()) { key ->
            val img = Icon.getIcon(key)
            Surface(
                modifier = Modifier
                    .size(48.dp)
                    .clickable { onSelect(key) },
                shape = CircleShape,
                tonalElevation = if (selected == key) 6.dp else 0.dp,
                border = if (selected == key)
                    BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                else null,
                color = MaterialTheme.colorScheme.surfaceVariant
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(img, contentDescription = key)
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

    Box(modifier = Modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = selected.name.replace("_", " "),
            onValueChange = { },
            readOnly = true,
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = true },
            trailingIcon = {
                Icon(
                    Icons.Default.ArrowDropDown,
                    contentDescription = null,
                    modifier = Modifier.clickable { expanded = true }
                )
            }
        )
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            Wallet.WalletType.entries.forEach { t ->
                DropdownMenuItem(
                    text = { Text(t.name.replace("_", " ")) },
                    onClick = {
                        onSelect(t)
                        expanded = false
                    }
                )
            }
        }
    }
}

private fun String.isValidDecimal() =
    matches(Regex("^\\d*\\.?\\d*$")) && count { it == '.' } <= 1