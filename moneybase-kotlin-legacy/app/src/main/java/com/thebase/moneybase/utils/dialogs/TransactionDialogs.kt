@file:Suppress("DEPRECATION")

package com.thebase.moneybase.utils.dialogs

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.thebase.moneybase.database.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import com.google.firebase.Timestamp
import kotlin.math.abs

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditTransaction(
    transaction: Transaction,
    userId: String,
    onDismiss: () -> Unit,
    onEditComplete: () -> Unit = {}
) {
    val repo = remember { FirebaseRepositories() }
    var categories by remember { mutableStateOf<List<Category>>(emptyList()) }
    var wallets by remember { mutableStateOf<List<Wallet>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var isSaving by remember { mutableStateOf(false) }

    var amount by rememberSaveable { mutableStateOf(abs(transaction.amount).toString()) }
    var description by rememberSaveable { mutableStateOf(transaction.description) }
    var selectedCategoryId by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedWalletId by rememberSaveable { mutableStateOf<String?>(null) }
    var isIncome by rememberSaveable(transaction.id) { mutableStateOf(transaction.isIncome) }

    val dateFormatter = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())
    var selectedDate by rememberSaveable { mutableStateOf(transaction.date.toDate()) }

    var categoryExpanded by rememberSaveable { mutableStateOf(false) }
    var walletExpanded by rememberSaveable { mutableStateOf(false) }
    var showDatePicker by rememberSaveable { mutableStateOf(false) }

    var amountError by rememberSaveable { mutableStateOf<String?>(null) }
    var descriptionError by rememberSaveable { mutableStateOf<String?>(null) }
    var categoryError by rememberSaveable { mutableStateOf<String?>(null) }
    var walletError by rememberSaveable { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        try {
            categories = repo.getAllCategories(transaction.userId)
            wallets = repo.getAllWallets(transaction.userId)
            selectedCategoryId = transaction.categoryId
            selectedWalletId = transaction.walletId
        } catch (_: Exception) {
        } finally {
            isLoading = false
        }
    }

    val selectedCategory = categories.find { it.id == selectedCategoryId }
    val selectedWallet = wallets.find { it.id == selectedWalletId }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Edit Transaction", style = MaterialTheme.typography.titleLarge)
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }

                Spacer(Modifier.height(16.dp))

                if (isLoading) {
                    Box(Modifier.fillMaxWidth(), Alignment.Center) {
                        CircularProgressIndicator()
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        item {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = MaterialTheme.colorScheme.surfaceVariant,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(Modifier.height(48.dp)) {
                                    listOf(false to "Expense", true to "Income").forEach { (type, label) ->
                                        val selected = isIncome == type
                                        Box(
                                            modifier = Modifier
                                                .weight(1f)
                                                .fillMaxHeight()
                                                .background(
                                                    if (selected) MaterialTheme.colorScheme.primary else Color.Transparent,
                                                    shape = if (type) RoundedCornerShape(
                                                        topEnd = 12.dp,
                                                        bottomEnd = 12.dp
                                                    ) else RoundedCornerShape(
                                                        topStart = 12.dp,
                                                        bottomStart = 12.dp
                                                    )
                                                )
                                                .clickable { isIncome = type },
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Text(
                                                text = label,
                                                color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant,
                                                style = MaterialTheme.typography.bodyMedium
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        item {
                            OutlinedTextField(
                                value = amount,
                                onValueChange = {
                                    if (it.isEmpty() || it.all { c -> c.isDigit() || c == '.' }) {
                                        amount = it
                                        amountError = null
                                    }
                                },
                                label = { Text("Amount") },
                                prefix = { Text("$") },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                modifier = Modifier.fillMaxWidth(),
                                isError = amountError != null,
                                supportingText = amountError?.let { { Text(it) } }
                            )
                        }

                        item {
                            OutlinedTextField(
                                value = description,
                                onValueChange = {
                                    description = it
                                    descriptionError = null
                                },
                                label = { Text("Description") },
                                modifier = Modifier.fillMaxWidth(),
                                isError = descriptionError != null,
                                supportingText = descriptionError?.let { { Text(it) } }
                            )
                        }

                        item {
                            ExposedDropdownMenuBox(
                                expanded = categoryExpanded,
                                onExpandedChange = { categoryExpanded = !categoryExpanded }
                            ) {
                                OutlinedTextField(
                                    value = selectedCategory?.name ?: "Select Category",
                                    onValueChange = {},
                                    readOnly = true,
                                    trailingIcon = {
                                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded)
                                    },
                                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                                    isError = categoryError != null,
                                    supportingText = categoryError?.let { { Text(it) } }
                                )
                                ExposedDropdownMenu(
                                    expanded = categoryExpanded,
                                    onDismissRequest = { categoryExpanded = false }
                                ) {
                                    categories.forEach { category ->
                                        DropdownMenuItem(
                                            text = { Text(category.name) },
                                            onClick = {
                                                selectedCategoryId = category.id
                                                categoryExpanded = false
                                                categoryError = null
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        item {
                            ExposedDropdownMenuBox(
                                expanded = walletExpanded,
                                onExpandedChange = { walletExpanded = !walletExpanded }
                            ) {
                                OutlinedTextField(
                                    value = selectedWallet?.name ?: "Select Wallet",
                                    onValueChange = {},
                                    readOnly = true,
                                    trailingIcon = {
                                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = walletExpanded)
                                    },
                                    modifier = Modifier.fillMaxWidth().menuAnchor(),
                                    isError = walletError != null,
                                    supportingText = walletError?.let { { Text(it) } }
                                )
                                ExposedDropdownMenu(
                                    expanded = walletExpanded,
                                    onDismissRequest = { walletExpanded = false }
                                ) {
                                    wallets.forEach { wallet ->
                                        DropdownMenuItem(
                                            text = { Text(wallet.name) },
                                            onClick = {
                                                selectedWalletId = wallet.id
                                                walletExpanded = false
                                                walletError = null
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        item {
                            OutlinedTextField(
                                value = dateFormatter.format(selectedDate),
                                onValueChange = {},
                                label = { Text("Date") },
                                readOnly = true,
                                modifier = Modifier.fillMaxWidth().clickable {
                                    showDatePicker = true
                                }
                            )
                        }

                        item {
                            Button(
                                onClick = {
                                    var hasError = false

                                    if (amount.isEmpty() || amount.toDoubleOrNull() == null) {
                                        amountError = "Please enter a valid amount"
                                        hasError = true
                                    }

                                    if (selectedCategoryId == null) {
                                        categoryError = "Please select a category"
                                        hasError = true
                                    }

                                    if (selectedWalletId == null) {
                                        walletError = "Please select a wallet"
                                        hasError = true
                                    }

                                    if (!hasError) {
                                        isSaving = true
                                        val amountValue = amount.toDoubleOrNull() ?: 0.0
                                        val updatedTransaction = transaction.copy(
                                            amount = amountValue,
                                            description = description,
                                            categoryId = selectedCategoryId!!,
                                            walletId = selectedWalletId!!,
                                            date = Timestamp(selectedDate),
                                            isIncome = isIncome
                                        )

                                        CoroutineScope(Dispatchers.IO).launch {
                                            try {
                                                repo.updateTransaction(userId, updatedTransaction)
                                                onEditComplete()
                                            } finally {
                                                isSaving = false
                                            }
                                        }
                                    }
                                },
                                modifier = Modifier.fillMaxWidth(),
                                enabled = !isSaving
                            ) {
                                if (isSaving) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(24.dp),
                                        color = MaterialTheme.colorScheme.onPrimary
                                    )
                                } else {
                                    Text("Save Changes")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}