package com.thebase.moneybase.screens

import android.app.DatePickerDialog
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items as lazyListItems
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.functionalities.category.CategorySelector
import com.thebase.moneybase.database.AppDatabase
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Wallet
import com.thebase.moneybase.data.Transaction
import com.thebase.moneybase.data.Icon.getIcon
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.*

@Composable
fun AddScreen(onBack: () -> Unit = {}) {
    val context = LocalContext.current
    val db = remember { AppDatabase.getInstance(context, "0123") }
    val categoryDao = db.categoryDao()
    val walletDao = db.walletDao()
    val transactionDao = db.transactionDao()

    val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
    var date by remember { mutableStateOf(LocalDate.now().format(formatter)) }
    var showDatePicker by remember { mutableStateOf(false) }
    var note by remember { mutableStateOf("") }
    var rawAmount by remember { mutableStateOf("") }
    var selectedCategoryId by remember { mutableStateOf<String?>(null) }
    var selectedWalletId by remember { mutableStateOf<String?>(null) }
    var isIncome by remember { mutableStateOf(false) }

    var categories by remember { mutableStateOf(emptyList<Category>()) }
    var wallets by remember { mutableStateOf(emptyList<Wallet>()) }

    LaunchedEffect(Unit) {
        categories = categoryDao.getCategoriesByUser("0123")
        wallets = walletDao.getWalletsByUser("0123")
        val transactions = transactionDao.getTop5Transactions("0123")
        if (transactions.isNotEmpty()) {
            val latest = transactions.first()
            selectedCategoryId = latest.categoryId
            selectedWalletId = latest.walletId
        } else {
            if (categories.isNotEmpty() && selectedCategoryId == null) {
                selectedCategoryId = categories.first().id
            }
            if (wallets.isNotEmpty() && selectedWalletId == null) {
                selectedWalletId = wallets.first().id
            }
        }
    }

    if (showDatePicker) {
        val calendar = Calendar.getInstance()
        DatePickerDialog(
            context,
            { _, year, month, day ->
                date = LocalDate.of(year, month + 1, day).format(formatter)
                showDatePicker = false
            },
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            calendar.get(Calendar.DAY_OF_MONTH)
        ).show()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        IncomeExpenseToggle(isIncome) { isIncome = it }
        DateField(date) { showDatePicker = true }
        NoteField(note) { note = it }
        AmountField(rawAmount, isIncome) { rawAmount = it }

        var showCategorySheet by remember { mutableStateOf(false) }

        val selectedCategory = categories.find { it.id == selectedCategoryId }

        CategoryField(selectedCategory) {
            showCategorySheet = true
        }

        if (showCategorySheet && categories.isNotEmpty()) {
            CategorySelector(
                categories = categories,
                onCategorySelected = {
                    selectedCategoryId = it.id
                    showCategorySheet = false
                },
                onDismiss = { showCategorySheet = false }
            )
        }

        WalletCarousel(
            wallets = wallets,
            selectedWalletId = selectedWalletId,
            onSelect = { selectedWalletId = it },
            onAddWallet = { /* TODO: Implement add wallet functionality */ }
        )

        SubmitButton(
            isValid = selectedCategoryId != null && selectedWalletId != null && rawAmount.isNotEmpty()
        ) {
            val amount = rawAmount.toDoubleOrNull() ?: 0.0
            val selectedWallet = wallets.first { it.id == selectedWalletId }
            val transaction = Transaction(
                id = UUID.randomUUID().toString(),
                walletId = selectedWalletId!!,
                description = note,
                date = date,
                amount = amount,
                currencyCode = selectedWallet.currencyCode,
                isIncome = isIncome,
                categoryId = selectedCategoryId!!,
                userId = "0123",
                createdAt = Instant.now(),
                updatedAt = Instant.now()
            )
            CoroutineScope(Dispatchers.IO).launch {
                transactionDao.insert(transaction)
                val updatedWallet = selectedWallet.copy(
                    balance = if (isIncome) selectedWallet.balance + amount
                    else selectedWallet.balance - amount
                )
                walletDao.update(updatedWallet)
                withContext(Dispatchers.Main) { onBack() }
            }
        }
    }
}

@Composable
private fun IncomeExpenseToggle(isIncome: Boolean, onToggle: (Boolean) -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .background(
                        color = if (!isIncome) MaterialTheme.colorScheme.primary else Color.Transparent,
                        shape = RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                    )
                    .clickable { onToggle(false) }
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Expense",
                    color = if (!isIncome) MaterialTheme.colorScheme.onPrimary
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Box(
                modifier = Modifier
                    .weight(1f)
                    .background(
                        if (isIncome) MaterialTheme.colorScheme.primary else Color.Transparent,
                        RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp)
                    )
                    .clickable { onToggle(true) }
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Income",
                    color = if (isIncome) MaterialTheme.colorScheme.onPrimary
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
    Spacer(modifier = Modifier.height(24.dp))
}

@Composable
private fun DateField(date: String, onShowPicker: () -> Unit) {
    Text("Date", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = date,
        onValueChange = {},
        modifier = Modifier.fillMaxWidth(),
        readOnly = true,
        placeholder = { Text("Select date") },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.DateRange,
                contentDescription = "Date picker",
                modifier = Modifier.clickable { onShowPicker() }
            )
        },
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(modifier = Modifier.height(16.dp))
}

@Composable
private fun NoteField(note: String, onNoteChange: (String) -> Unit) {
    Text("Note", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = note,
        onValueChange = onNoteChange,
        modifier = Modifier.fillMaxWidth(),
        placeholder = { Text("Enter note") },
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(modifier = Modifier.height(16.dp))
}

@Composable
private fun AmountField(rawAmount: String, isIncome: Boolean, onAmountChange: (String) -> Unit) {
    Text("Amount", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = rawAmount,
        onValueChange = { newValue ->
            onAmountChange(newValue.filter { it.isDigit() || it == '.' })
        },
        modifier = Modifier.fillMaxWidth(),
        placeholder = { Text("Enter amount") },
        leadingIcon = {
            Icon(
                Icons.Default.AttachMoney,
                contentDescription = "Amount",
                tint = if (isIncome) Color(0xFF4CAF50) else Color(0xFFF44336)
            )
        },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(modifier = Modifier.height(24.dp))
}

@Composable
private fun SubmitButton(isValid: Boolean, onSubmit: () -> Unit) {
    Button(
        onClick = onSubmit,
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp),
        shape = RoundedCornerShape(12.dp),
        enabled = isValid
    ) {
        Text("Submit", style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
private fun CategoryField(selectedCategory: Category?, onClick: () -> Unit) {
    Text("Category", style = MaterialTheme.typography.labelLarge)
    OutlinedButton(
        onClick = onClick,
        border = BorderStroke(2.dp, selectedCategory?.let { Color(it.color.toColorInt()) }
            ?: MaterialTheme.colorScheme.outline),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (selectedCategory != null) {
                Icon(
                    imageVector = getIcon(selectedCategory.iconName),
                    contentDescription = selectedCategory.name,
                    tint = Color(selectedCategory.color.toColorInt()),
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text(
                selectedCategory?.name ?: "Select Category",
                color = MaterialTheme.colorScheme.onSurface,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
    Spacer(modifier = Modifier.height(24.dp))
}

@Composable
private fun WalletCarousel(
    wallets: List<Wallet>,
    selectedWalletId: String?,
    onSelect: (String) -> Unit,
    onAddWallet: () -> Unit
) {
    Text("Wallet", style = MaterialTheme.typography.labelLarge)
    Spacer(modifier = Modifier.height(8.dp))
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        lazyListItems(wallets) { wallet ->
            WalletItem(
                wallet = wallet,
                isSelected = selectedWalletId == wallet.id,
                onSelect = { onSelect(wallet.id) },
                modifier = Modifier
                    .width(140.dp)
                    .height(110.dp) // Fixed height for wallet items
            )
        }
        item {
            Box(
                modifier = Modifier
                    .width(150.dp)
                    .height(150.dp),
                contentAlignment = Alignment.Center
            ) {
                IconButton(onClick = onAddWallet) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add wallet",
                        tint = Color.Gray,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
        }
    }
    Spacer(modifier = Modifier.height(32.dp))
}

@Composable
private fun WalletItem(wallet: Wallet, isSelected: Boolean, onSelect: () -> Unit, modifier: Modifier = Modifier) {
    val borderColor = if (isSelected) Color(wallet.color.toColorInt())
    else MaterialTheme.colorScheme.outline
    val iconColor = Color(wallet.color.toColorInt())
    Card(
        modifier = modifier
            .border(2.dp, borderColor, RoundedCornerShape(12.dp))
            .clickable(onClick = onSelect),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Column(
            modifier = Modifier
                .padding(12.dp)
                .fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = getIcon(wallet.iconName),
                contentDescription = wallet.name,
                tint = iconColor,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(wallet.name, style = MaterialTheme.typography.bodyLarge)
            Text(
                "${wallet.currencyCode} ${"%.2f".format(wallet.balance)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}