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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.data.Wallet
import java.util.UUID

@Composable
fun WalletAgent(
    wallet: Wallet,
    onEdit: () -> Unit,
    onRemove: (Wallet) -> Unit,
    onChangeBalance: (Wallet, Double) -> Unit,
    onDismiss: () -> Unit
) {
    var showChangeBalance by remember { mutableStateOf(false) }
    var showRemoveConfirmation by remember { mutableStateOf(false) }

    if (showChangeBalance) {
        ChangeBalanceDialog(
            wallet = wallet,
            onConfirm = { newBalance ->
                onChangeBalance(wallet, newBalance)
                showChangeBalance = false
                onDismiss()
            },
            onCancel = { showChangeBalance = false }
        )
    }

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

    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {},
        text = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    "Manage Wallet: ${wallet.name}",
                    style = MaterialTheme.typography.titleMedium
                )
                Button(
                    onClick = { showChangeBalance = true },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Change Balance") }
                Button(
                    onClick = {
                        onEdit()
                        onDismiss()
                    },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Edit") }
                Button(
                    onClick = { showRemoveConfirmation = true },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error),
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Remove") }
            }
        }
    )
}

@Suppress("UNCHECKED_CAST")
@Composable
fun ChangeBalanceDialog(
    wallet: Wallet,
    onConfirm: (Double) -> Unit,
    onCancel: () -> Unit
) {
    var input by remember { mutableStateOf(wallet.balance.toString()) }

    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text("Change Balance") },
        text = {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it.filter { c -> c.isDigit() || c == '.' } },
                singleLine = true,
                label = { Text("New Balance") }
            )
        },
        confirmButton = {
            TextButton(
                onClick = (input.toDoubleOrNull()?.let(onConfirm) ?: {}) as () -> Unit
            ) { Text("Confirm") }
        },
        dismissButton = {
            TextButton(onClick = onCancel) { Text("Cancel") }
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
    var colorHex by remember { mutableStateOf("#6200EE") }

    val presetColors = listOf(
        "#F44336", "#E91E63", "#9C27B0", "#3F51B5",
        "#03A9F4", "#009688", "#4CAF50", "#FF9800", "#795548"
    )

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
                    onValueChange = { balance = it.filter { c -> c.isDigit() || c == '.' } },
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
                Text("Choose a color", style = MaterialTheme.typography.labelLarge)
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                ) {
                    items(presetColors) { hex ->
                        val col = Color(hex.toColorInt())
                        Surface(
                            modifier = Modifier
                                .size(40.dp)
                                .clickable { colorHex = hex },
                            shape = CircleShape,
                            tonalElevation = if (colorHex == hex) 6.dp else 0.dp,
                            border = if (colorHex == hex)
                                BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                            else null,
                            color = col
                        ) {}
                    }
                }
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
                            userId = "0123",
                            iconName = "account_balance_wallet",
                            color = colorHex
                        )
                    )
                }
            ) { Text("Create") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
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