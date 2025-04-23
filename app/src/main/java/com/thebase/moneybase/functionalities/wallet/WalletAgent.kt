package com.thebase.moneybase.functionalities.wallet

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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.data.ColorPalette
import com.thebase.moneybase.data.Wallet
import java.util.UUID

@Composable
fun WalletAgent(
    wallet: Wallet,
    onEditDone: (Wallet) -> Unit,
    onRemove: (Wallet) -> Unit,
    onDismiss: () -> Unit
) {
    var showRemoveConfirmation by remember { mutableStateOf(false) }
    var showEditWallet by remember { mutableStateOf(false) }

    if (showRemoveConfirmation) {
        AlertDialog(
            onDismissRequest = { showRemoveConfirmation = false },
            title = { Text("Delete Wallet") },
            text = { Text("Are you sure you want to delete ${wallet.name}?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        onRemove(wallet)
                        showRemoveConfirmation = false
                        onDismiss()
                    }
                ) { Text("Delete") }
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
            }
        )
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {},
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    wallet.name,
                    style = MaterialTheme.typography.titleMedium
                )
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
    onWalletAdded: (Wallet) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var type by remember { mutableStateOf(Wallet.WalletType.OTHER) }
    var currency by remember { mutableStateOf("USD") }
    var balance by remember { mutableStateOf("0.0") }
    var colorName by remember { mutableStateOf("purple") }
    var selectedIcon by remember { mutableStateOf("account_balance_wallet") }

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
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
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
                            id = UUID.randomUUID().toString(),
                            name = name,
                            type = type,
                            currencyCode = currency,
                            balance = balance.toDoubleOrNull() ?: 0.0,
                            userId = "0123", // Replace with actual user ID
                            iconName = selectedIcon,
                            color = ColorPalette.getHexCode(colorName)
                        )
                    )
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
    onDelete: () -> Unit
) {
    var name by remember { mutableStateOf(wallet.name) }
    var type by remember { mutableStateOf(wallet.type) }
    var currency by remember { mutableStateOf(wallet.currencyCode) }
    var balance by remember { mutableStateOf(wallet.balance.toString()) }
    var colorName by remember {
        mutableStateOf(
            ColorPalette.reverseColorMap[wallet.color] ?: "purple"
        )
    }
    var selectedIcon by remember { mutableStateOf(wallet.iconName) }

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
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
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
                            iconName = selectedIcon
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
                ) {
                    Text("Delete")
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
    selectedColor: String,
    onColorSelected: (String) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
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
private fun IconSelector(
    selectedIcon: String,
    onIconSelected: (String) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        contentPadding = PaddingValues(horizontal = 8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
    ) {
        items(com.thebase.moneybase.data.Icon.iconMap.keys.toList()) { iconName ->
            val icon = com.thebase.moneybase.data.Icon.iconMap[iconName]
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
                        Icon(
                            imageVector = it,
                            contentDescription = iconName,
                            tint = MaterialTheme.colorScheme.onSurface
                        )
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