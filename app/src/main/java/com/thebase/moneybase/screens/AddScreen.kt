package com.thebase.moneybase.screens

import com.thebase.moneybase.functionalities.category.AddCategoryDialog
import com.thebase.moneybase.functionalities.category.EditCategoryDialog
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.functionalities.wallet.WalletAgent
import com.thebase.moneybase.data.*
import com.thebase.moneybase.data.Icon.getIcon
import com.thebase.moneybase.database.AppDatabase
import com.thebase.moneybase.functionalities.category.CategorySelector
import com.thebase.moneybase.functionalities.wallet.AddWallet
import kotlinx.coroutines.*
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
    var showAddCategoryDialog by remember { mutableStateOf(false) }
    var actionCategory by remember { mutableStateOf<Category?>(null) }

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

    Scaffold(snackbarHost = { SnackbarHost(hostState = snackbarHostState) }) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
                .padding(padding)
        ) {
            IncomeExpenseToggle(isIncome) { isIncome = it }
            DateField(date) { date = LocalDate.now().format(formatter) }
            NoteField(note) { note = it }
            AmountField(rawAmount, isIncome) { rawAmount = it }
            CategoryField(categories.find { it.id == selectedCategoryId }) { showCategorySheet = true }
            WalletCarousel(wallets, selectedWalletId, { selectedWalletId = it }, { showAddWalletDialog = true }) {
                showWalletAgent = it
            }
            Spacer(Modifier.height(24.dp))
            SubmitButton(
                isValid = selectedCategoryId != null && selectedWalletId != null && rawAmount.isNotBlank()
            ) {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        val amount = rawAmount.toDoubleOrNull() ?: return@withContext
                        val wallet = wallets.first { it.id == selectedWalletId }
                        transactionDao.insert(
                            Transaction(
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
                            )
                        )
                        walletDao.update(wallet.copy(balance = if (isIncome) wallet.balance + amount else wallet.balance - amount))
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
            categories,
            { selectedCategoryId = it.id; showCategorySheet = false },
            { showCategorySheet = false },
            { showCategorySheet = false; showAddCategoryDialog = true },
            { actionCategory = it; showCategorySheet = false },
            {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        categoryDao.delete(it)
                        categories = categoryDao.getCategoriesByUser("0123")
                    }
                    showCategorySheet = false
                }
            }
        )
    }

    if (showAddCategoryDialog) {
        AddCategoryDialog(
            onDismiss = { showAddCategoryDialog = false },
            onCategoryAdded = {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        categoryDao.insert(it)
                        categories = categoryDao.getCategoriesByUser("0123")
                    }
                    showAddCategoryDialog = false
                }
            },
            existingCategories = categories
        )
    }

    actionCategory?.let { category ->
        EditCategoryDialog(
            category = category,
            onDismiss = { actionCategory = null },
            onCategoryUpdated = { updatedCategory ->
                scope.launch {
                    withContext(Dispatchers.IO) {
                        categoryDao.update(updatedCategory)
                        categories = categoryDao.getCategoriesByUser("0123")
                    }
                    actionCategory = null
                }
            },
            onCategoryDeleted = { deletedCategory ->
                scope.launch {
                    withContext(Dispatchers.IO) {
                        categoryDao.delete(deletedCategory)
                        categories = categoryDao.getCategoriesByUser("0123")
                    }
                    actionCategory = null
                }
            }
        )
    }

    showWalletAgent?.let {
        WalletAgent(
            it,
            {},
            {
                scope.launch {
                    withContext(Dispatchers.IO) {
                        walletDao.delete(it)
                        wallets = walletDao.getWalletsByUser("0123")
                    }
                    showWalletAgent = null
                }
            },
            { showWalletAgent = null }
        )
    }

    if (showAddWalletDialog) {
        AddWallet(
            { showAddWalletDialog = false },
            {
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
                        if (!isIncome) MaterialTheme.colorScheme.primary else Color.Transparent,
                        RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
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
    Spacer(Modifier.height(24.dp))
}

@Composable
private fun DateField(date: String, onShowPicker: () -> Unit) {
    Text("Date", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = date,
        onValueChange = {},
        readOnly = true,
        modifier = Modifier.fillMaxWidth(),
        placeholder = { Text("Select date") },
        leadingIcon = {
            Icon(
                Icons.Default.DateRange,
                contentDescription = null,
                modifier = Modifier.clickable { onShowPicker() }
            )
        },
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(Modifier.height(16.dp))
}

@Composable
private fun NoteField(value: String, onValueChange: (String) -> Unit) {
    Text("Note", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier.fillMaxWidth(),
        placeholder = { Text("Enter note") },
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(Modifier.height(16.dp))
}

@Composable
private fun AmountField(value: String, isIncome: Boolean, onValueChange: (String) -> Unit) {
    Text("Amount", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = value,
        onValueChange = { it.filter { ch -> ch.isDigit() || ch == '.' }.let(onValueChange) },
        modifier = Modifier.fillMaxWidth(),
        placeholder = { Text("Enter amount") },
        leadingIcon = {
            Icon(
                Icons.Default.AttachMoney,
                contentDescription = null,
                tint = if (isIncome) Color(0xFF4CAF50) else Color(0xFFF44336)
            )
        },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(Modifier.height(24.dp))
}

@Composable
private fun CategoryField(selected: Category?, onClick: () -> Unit) {
    Text("Category", style = MaterialTheme.typography.labelLarge)
    val border = selected?.color?.toColorInt()?.let { Color(it) }
        ?: MaterialTheme.colorScheme.outline
    OutlinedButton(
        onClick = onClick,
        border = BorderStroke(2.dp, border),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
    ) {
        selected?.let {
            Icon(getIcon(it.iconName), contentDescription = null, tint = Color(it.color.toColorInt()), modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(selected?.name ?: "Select Category", style = MaterialTheme.typography.bodyLarge)
    }
    Spacer(Modifier.height(24.dp))
}

@Composable
private fun WalletCarousel(
    wallets: List<Wallet>,
    selectedId: String?,
    onSelect: (String) -> Unit,
    onAdd: () -> Unit,
    onLongPress: (Wallet) -> Unit
) {
    Text("Wallet", style = MaterialTheme.typography.labelLarge)
    Spacer(Modifier.height(8.dp))
    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
        items(wallets) { w ->
            WalletItem(
                wallet = w,
                isSelected = w.id == selectedId,
                onSelect = { onSelect(w.id) },
                onLongPress = { onLongPress(w) },
                modifier = Modifier.size(width = 140.dp, height = 110.dp)
            )
        }
        item {
            Card(
                modifier = Modifier
                    .size(width = 140.dp, height = 110.dp)
                    .clickable(onClick = onAdd),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                shape = RoundedCornerShape(12.dp)
            ) {
                Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
                    Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(32.dp))
                }
            }
        }
    }
    Spacer(Modifier.height(32.dp))
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun WalletItem(
    wallet: Wallet,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onLongPress: (Wallet) -> Unit,
    modifier: Modifier = Modifier
) {
    val color = Color(wallet.color.toColorInt())
    Card(
        modifier = modifier
            .border(2.dp, if (isSelected) color else MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
            .combinedClickable(onClick = onSelect, onLongClick = { onLongPress(wallet) }),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Column(
            modifier = Modifier
                .padding(12.dp)
                .fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(getIcon(wallet.iconName), contentDescription = null, tint = color, modifier = Modifier.size(32.dp))
            Spacer(Modifier.height(6.dp))
            Text(wallet.name, style = MaterialTheme.typography.bodyLarge)
            Text(
                "${wallet.currencyCode} ${"%.2f".format(wallet.balance)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}