package com.thebase.moneybase.screens

import android.app.DatePickerDialog
import android.graphics.Color as AndroidColor
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.functionalities.wallet.WalletAgent
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Transaction
import com.thebase.moneybase.data.Wallet
import com.thebase.moneybase.data.Icon.getIcon
import com.thebase.moneybase.database.AppDatabase
import com.thebase.moneybase.functionalities.category.CategorySelector
import com.thebase.moneybase.functionalities.wallet.AddWallet
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddScreen(onBack: () -> Unit = {}) {
    val context = LocalContext.current
    val db = remember { AppDatabase.getInstance(context, "0123") }
    val categoryDao = db.categoryDao()
    val walletDao = db.walletDao()
    val transactionDao = db.transactionDao()
    val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    var date by remember { mutableStateOf(LocalDate.now().format(formatter)) }
    var note by remember { mutableStateOf("") }
    var rawAmount by remember { mutableStateOf("") }
    var selectedCategoryId by remember { mutableStateOf<String?>(null) }
    var selectedWalletId by remember { mutableStateOf<String?>(null) }
    var isIncome by remember { mutableStateOf(false) }
    var categories by remember { mutableStateOf(emptyList<Category>()) }
    var wallets by remember { mutableStateOf(emptyList<Wallet>()) }
    var showWalletAgent by remember { mutableStateOf<Wallet?>(null) }
    var showAddWalletDialog by remember { mutableStateOf(false) }
    var showCategorySheet by remember { mutableStateOf(false) }
    var showDatePicker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        categories = categoryDao.getCategoriesByUser("0123")
        wallets = walletDao.getWalletsByUser("0123")
        transactionDao.getTop10Transactions("0123").firstOrNull()?.let {
            selectedCategoryId = it.categoryId
            selectedWalletId = it.walletId
        } ?: run {
            selectedCategoryId = categories.firstOrNull()?.id
            selectedWalletId = wallets.firstOrNull()?.id
        }
    }


    if (showDatePicker) {
        DatePickerDialog(
            context,
            { _, y, m, d ->
                date = LocalDate.of(y, m + 1, d).format(formatter)
                showDatePicker = false
            },
            Calendar.getInstance().apply { time = Date() }.run { get(Calendar.YEAR) },
            Calendar.getInstance().get(Calendar.MONTH),
            Calendar.getInstance().get(Calendar.DAY_OF_MONTH)
        ).show()
    }

    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
                .padding(padding)
        ) {
            IncomeExpenseToggle(isIncome) { isIncome = it }
            DateField(date) { showDatePicker = true }
            NoteField(note) { note = it }
            AmountField(rawAmount, isIncome) { rawAmount = it }
            CategoryField(categories.find { it.id == selectedCategoryId }) { showCategorySheet = true }
            WalletCarousel(wallets, selectedWalletId, { selectedWalletId = it }, { showAddWalletDialog = true }) { showWalletAgent = it }
            Spacer(Modifier.height(24.dp))
            SubmitButton(
                isValid = selectedCategoryId != null && selectedWalletId != null && rawAmount.isNotBlank()
            ) {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        val amount = rawAmount.toDoubleOrNull() ?: return@withContext
                        val wallet = wallets.first { it.id == selectedWalletId }
                        transactionDao.insert(Transaction(
                            id = UUID.randomUUID().toString(),
                            walletId = wallet.id,
                            description = note,
                            date = date,
                            amount = amount,
                            currencyCode = wallet.currencyCode,
                            isIncome = isIncome,
                            categoryId = selectedCategoryId!!,
                            userId = "0123",
                            createdAt = Instant.now(),
                            updatedAt = Instant.now()
                        ))
                        walletDao.update(wallet.copy(
                            balance = if (isIncome) wallet.balance + amount else wallet.balance - amount
                        ))
                        wallets = walletDao.getWalletsByUser("0123")
                    }
                    snackbarHostState.showSnackbar("Transaction added")
                    onBack()
                }
            }
        }
    }

    if (showCategorySheet) {
        CategorySelector(
            categories = categories,
            onCategorySelected = {
                selectedCategoryId = it.id
                showCategorySheet = false
            },
            onDismiss = { showCategorySheet = false }
        )
    }
    showWalletAgent?.let { wallet ->
        WalletAgent(
            wallet = wallet,
            onEdit = {},
            onRemove = {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        walletDao.delete(it)
                        wallets = walletDao.getWalletsByUser("0123")
                    }
                    showWalletAgent = null
                }
            },
            onChangeBalance = { w, newBalance ->
                scope.launch {
                    withContext(Dispatchers.IO) {
                        walletDao.update(w.copy(balance = newBalance))
                        wallets = walletDao.getWalletsByUser("0123")
                    }
                }
            },
            onDismiss = { showWalletAgent = null }
        )
    }
    if (showAddWalletDialog) {
        AddWallet(
            onDismiss = { showAddWalletDialog = false },
            onWalletAdded = {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        walletDao.insert(it)
                        wallets = walletDao.getWalletsByUser("0123")
                    }
                }
                showAddWalletDialog = false
            }
        )
    }
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
                    color = if (!isIncome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
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
                    color = if (isIncome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
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
        onValueChange = { newValue -> onAmountChange(newValue.filter { it.isDigit() || it == '.' }) },
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
private fun CategoryField(selectedCategory: Category?, onClick: () -> Unit) {
    Text("Category", style = MaterialTheme.typography.labelLarge)
    OutlinedButton(
        onClick = onClick,
        border = BorderStroke(2.dp, selectedCategory?.let { Color(it.color.toColorInt()) } ?: MaterialTheme.colorScheme.outline),
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
    onAddWallet: () -> Unit,
    onLongPress: (Wallet) -> Unit
) {
    Text("Wallet", style = MaterialTheme.typography.labelLarge)
    Spacer(modifier = Modifier.height(8.dp))
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        items(wallets) { wallet ->
            WalletItem(
                wallet = wallet,
                isSelected = selectedWalletId == wallet.id,
                onSelect = { onSelect(wallet.id) },
                onLongPress = onLongPress, // <- pass it normally, no wrapping needed
                modifier = Modifier
                    .width(140.dp)
                    .height(110.dp)
            )

        }
        item {
            Card(
                modifier = Modifier
                    .width(140.dp)
                    .height(110.dp)
                    .clickable(onClick = onAddWallet),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                shape = RoundedCornerShape(12.dp)
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add wallet",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }
        }
    }
    Spacer(modifier = Modifier.height(32.dp))
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun WalletItem(
    wallet: Wallet,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onLongPress: (Wallet) -> Unit, // <- FIX: onLongPress expects Wallet now
    modifier: Modifier = Modifier
) {
    val borderColor = if (isSelected) Color(wallet.color.toColorInt()) else MaterialTheme.colorScheme.outline
    val iconColor = Color(wallet.color.toColorInt())

    Card(
        modifier = modifier
            .border(2.dp, borderColor, RoundedCornerShape(12.dp))
            .combinedClickable(
                onClick = onSelect,
                onLongClick = { onLongPress(wallet) } // <- FIX: pass the wallet inside here
            ),
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