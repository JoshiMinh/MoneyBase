package com.thebase.moneybase.functionalities.wallet

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
// at the top of WalletAgent.kt
import android.graphics.Color as AndroidColor
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
import androidx.compose.ui.unit.Dp
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
    var showChangeBalanceDialog by remember { mutableStateOf(false) }
    var showRemoveConfirmation by remember { mutableStateOf(false) }

    if (showChangeBalanceDialog) {
        ChangeBalanceDialog(
            wallet = wallet,
            onConfirm = { newBalance ->
                onChangeBalance(wallet, newBalance)
                showChangeBalanceDialog = false
                onDismiss()
            },
            onCancel = { showChangeBalanceDialog = false }
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
                TextButton(
                    onClick = { showRemoveConfirmation = false }
                ) { Text("Cancel") }
            }
        )
    }


    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {},
        text = {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Manage Wallet: ${wallet.name}", style = MaterialTheme.typography.titleMedium)
                Spacer(Modifier.height(16.dp))
                Button(
                    onClick = { showChangeBalanceDialog = true },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Change Balance") }
                Spacer(Modifier.height(8.dp))
                Button(
                    onClick = {
                        onEdit()
                        onDismiss()
                    },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Edit") }
                Spacer(Modifier.height(8.dp))
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
fun ChangeBalanceDialog(
    wallet: Wallet,
    onConfirm: (Double) -> Unit,
    onCancel: () -> Unit
) {
    var input by remember { mutableStateOf(wallet.balance.toString()) }
    AlertDialog(
        onDismissRequest = onCancel,
        confirmButton = {
            TextButton(
                onClick = {
                    val newBalance = input.toDoubleOrNull()
                    if (newBalance != null) onConfirm(newBalance)
                }
            ) {
                Text("Confirm")
            }
        },
        dismissButton = {
            TextButton(onClick = onCancel) { Text("Cancel") }
        },
        title = { Text("Change Balance") },
        text = {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it.filter { c -> c.isDigit() || c == '.' } },
                singleLine = true,
                label = { Text("New Balance") }
            )
        }
    )
}

@Composable
fun AddWallet(
    onDismiss: () -> Unit,
    onWalletAdded: (Wallet) -> Unit
) {
    var walletName by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf(Wallet.WalletType.OTHER) }
    var currencyCode by remember { mutableStateOf("USD") }
    var initialBalance by remember { mutableStateOf("0.0") }
    var selectedColor by remember { mutableStateOf("#6200EE") }

    // your preset swatches
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
                    value = walletName,
                    onValueChange = { walletName = it },
                    label = { Text("Wallet Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = initialBalance,
                    onValueChange = { initialBalance = it.filter { c -> c.isDigit() || c == '.' } },
                    label = { Text("Initial Balance") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
                WalletTypeDropdown(
                    selectedType = selectedType,
                    onTypeSelected = { selectedType = it }
                )
                OutlinedTextField(
                    value = currencyCode,
                    onValueChange = { currencyCode = it.take(3).uppercase() },
                    label = { Text("Currency Code") },
                    modifier = Modifier.fillMaxWidth()
                )

                Text("Choose a color", style = MaterialTheme.typography.labelLarge)
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp),
                    modifier = Modifier.fillMaxWidth().height(56.dp)
                ) {
                    items(presetColors) { hex ->
                        val col = Color(hex.toColorInt())
                        Surface(
                            modifier = Modifier
                                .size(40.dp)
                                .clickable { selectedColor = hex },
                            shape = CircleShape,
                            tonalElevation = if (selectedColor == hex) 6.dp else 0.dp,
                            border = if (selectedColor == hex)
                                BorderStroke(2.dp, MaterialTheme.colorScheme.onSurface)
                            else null,
                            color = col
                        ) { /* the colored circle */ }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                val wallet = Wallet(
                    id = UUID.randomUUID().toString(),
                    name = walletName,
                    type = selectedType,
                    currencyCode = currencyCode,
                    balance = initialBalance.toDoubleOrNull() ?: 0.0,
                    userId = "0123",
                    iconName = "account_balance_wallet",
                    color = selectedColor
                )
                onWalletAdded(wallet)
            }) { Text("Create") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}


@Composable
private fun WalletTypeDropdown(
    selectedType: Wallet.WalletType,
    onTypeSelected: (Wallet.WalletType) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxWidth()) {
        OutlinedTextField(
            value = selectedType.name.replace("_", " "),
            onValueChange = {},
            readOnly = true,
            trailingIcon = {
                Icon(Icons.Default.ArrowDropDown, null,
                    Modifier.clickable { expanded = true })
            },
            modifier = Modifier
                .fillMaxWidth()
                .clickable { expanded = true }
        )

        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            Wallet.WalletType.entries.forEach { type ->
                DropdownMenuItem(
                    text = { Text(type.name.replace("_", " ")) },
                    onClick = {
                        onTypeSelected(type)
                        expanded = false
                    }
                )
            }
        }
    }
}