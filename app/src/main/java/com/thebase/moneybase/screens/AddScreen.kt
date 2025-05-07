package com.thebase.moneybase.screens

import android.app.DatePickerDialog
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.database.*
import com.thebase.moneybase.utils.components.AddCategoryDialog
import com.thebase.moneybase.utils.components.AddWallet
import com.thebase.moneybase.utils.components.CategorySelector
import com.thebase.moneybase.utils.components.EditCategoryDialog
import com.thebase.moneybase.utils.components.WalletAgent
import com.thebase.moneybase.ui.Icon.getIcon
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun AddScreen(
    userId: String,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    val repo = remember { FirebaseRepositories() }

    val categories by repo.getCategoriesFlow(userId).collectAsState(initial = emptyList())
    val wallets by repo.getWalletsFlow(userId).collectAsState(initial = emptyList())

    var isIncome by remember { mutableStateOf(false) }
    var calendar by remember { mutableStateOf(Calendar.getInstance()) }
    val dateText = remember(calendar) {
        SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).format(calendar.time)
    }
    var note by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }

    var selectedCategory by remember { mutableStateOf<Category?>(null) }
    var selectedWalletId by remember { mutableStateOf<String?>(null) }

    var showDatePicker by remember { mutableStateOf(false) }
    var showCategorySheet by remember { mutableStateOf(false) }
    var showAddCategory by remember { mutableStateOf(false) }
    var editingCategory by remember { mutableStateOf<Category?>(null) }
    var showAddWallet by remember { mutableStateOf(false) }
    var editingWallet by remember { mutableStateOf<Wallet?>(null) }

    LaunchedEffect(categories) {
        if (categories.isNotEmpty() && selectedCategory == null) {
            selectedCategory = categories[0]
        }
    }

    LaunchedEffect(wallets) {
        if (wallets.isNotEmpty() && selectedWalletId == null) {
            selectedWalletId = wallets[0].id
        }
    }

    // Show Date Picker only once using a side-effect
    LaunchedEffect(showDatePicker) {
        if (showDatePicker) {
            DatePickerDialog(
                context,
                { _, y, m, d ->
                    calendar = Calendar.getInstance().apply { set(y, m, d) }
                },
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH),
                calendar.get(Calendar.DAY_OF_MONTH)
            ).apply {
                setOnDismissListener { showDatePicker = false }
            }.show()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(padding)
                .padding(16.dp)
        ) {
            IncomeExpenseToggle(isIncome) { isIncome = it }
            DateField(dateText) { showDatePicker = true }
            NoteField(note) { note = it }
            AmountField(amount, isIncome) { amount = it }
            CategoryField(selectedCategory) { showCategorySheet = true }
            WalletCarousel(
                wallets = wallets,
                selectedId = selectedWalletId,
                onSelect = { selectedWalletId = it },
                onAdd = { showAddWallet = true },
                onLongPress = { editingWallet = it }
            )

            val isValid = selectedCategory != null &&
                    selectedWalletId != null &&
                    amount.isValidDecimal()

            Spacer(Modifier.height(24.dp))
            SubmitButton(isValid) {
                scope.launch {
                    try {
                        val amt = amount.toDouble()
                        val tx = Transaction(
                            walletId = selectedWalletId!!,
                            userId = userId,
                            description = note,
                            date = dateText,
                            amount = if (isIncome) amt else -amt,
                            currencyCode = wallets.first { it.id == selectedWalletId }.currencyCode,
                            isIncome = isIncome,
                            categoryId = selectedCategory!!.id
                        )
                        repo.addTransaction(userId, tx)
                        snackbarHostState.showSnackbar("Transaction added")
                        onBack()
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Error: ${e.message}")
                    }
                }
            }
        }
    }

    if (showCategorySheet) {
        CategorySelector(
            categories = categories,
            userId = userId,
            onCategorySelected = {
                selectedCategory = it
                showCategorySheet = false
            },
            onDismiss = { showCategorySheet = false },
            onAddCategory = { showAddCategory = true },
            onEditCategory = { editingCategory = it },
            onRemoveCategory = { cat ->
                scope.launch {
                    try {
                        repo.deleteCategory(userId, cat.id)
                        snackbarHostState.showSnackbar("Category deleted successfully")
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Error deleting category: ${e.message}")
                    }
                }
            }
        )
    }

    if (showAddCategory) {
        AddCategoryDialog(
            onDismiss = { showAddCategory = false },
            onCategoryAdded = { cat ->
                scope.launch {
                    repo.addCategory(userId, cat)
                }
            },
            existingCategories = categories,
            userId = userId,
            showError = { msg -> scope.launch { snackbarHostState.showSnackbar(msg) } }
        )
    }

    editingCategory?.let { cat ->
        EditCategoryDialog(
            category = cat,
            onDismiss = { editingCategory = null },
            onCategoryUpdated = { updated ->
                scope.launch {
                    try {
                        repo.updateCategory(userId, updated)
                        snackbarHostState.showSnackbar("Category updated successfully")
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Error updating category: ${e.message}")
                    }
                }
            },
            onCategoryDeleted = {
                scope.launch {
                    try {
                        repo.deleteCategory(userId, cat.id)
                        snackbarHostState.showSnackbar("Category deleted successfully")
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Error deleting category: ${e.message}")
                    }
                }
            },
            showError = { msg -> scope.launch { snackbarHostState.showSnackbar(msg) } }
        )
    }

    if (showAddWallet) {
        AddWallet(
            onDismiss = { showAddWallet = false },
            onWalletAdded = { w ->
                scope.launch {
                    repo.addWallet(userId, w)
                }
            }
        )
    }

    editingWallet?.let { w ->
        WalletAgent(
            wallet = w,
            onEditDone = { updated ->
                scope.launch {
                    repo.updateWallet(userId, updated)
                    editingWallet = null
                }
            },
            onRemove = {
                scope.launch {
                    repo.deleteWallet(userId, w.id)
                    editingWallet = null
                }
            },
            onDismiss = { editingWallet = null }
        )
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
            listOf(false to "Expense", true to "Income").forEach { (flag, label) ->
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .background(
                            color = if (isIncome == flag) MaterialTheme.colorScheme.primary else Color.Transparent,
                            shape = if (flag) RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp)
                            else RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                        )
                        .clickable { onToggle(flag) }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        label,
                        color = if (isIncome == flag)
                            MaterialTheme.colorScheme.onPrimary
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
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
        leadingIcon = {
            Icon(
                Icons.Default.DateRange,
                contentDescription = "Pick date",
                modifier = Modifier.clickable { onShowPicker() }
            )
        },
        modifier = Modifier.fillMaxWidth(),
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
        placeholder = { Text("Enter a note") },
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(Modifier.height(16.dp))
}

@Composable
private fun AmountField(
    value: String,
    isIncome: Boolean,
    onValueChange: (String) -> Unit
) {
    Text("Amount", style = MaterialTheme.typography.labelLarge)
    OutlinedTextField(
        value = value,
        onValueChange = { it.filter { ch -> ch.isDigit() || ch == '.' }.let(onValueChange) },
        placeholder = { Text("Enter amount") },
        leadingIcon = {
            Icon(
                Icons.Default.AttachMoney,
                contentDescription = null,
                tint = if (isIncome) Color(0xFF4CAF50) else Color(0xFFF44336)
            )
        },
        modifier = Modifier.fillMaxWidth(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
        shape = RoundedCornerShape(12.dp)
    )
    Spacer(Modifier.height(24.dp))
}

@Composable
private fun CategoryField(selected: Category?, onClick: () -> Unit) {
    Text("Category", style = MaterialTheme.typography.labelLarge)
    val borderColor =
        selected?.color?.toColorInt()?.let { Color(it) }
            ?: MaterialTheme.colorScheme.outline

    OutlinedButton(
        onClick = onClick,
        border = BorderStroke(2.dp, borderColor),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
    ) {
        selected?.let {
            Icon(
                getIcon(it.iconName),
                contentDescription = null,
                tint = try {
                    Color(it.color.toColorInt())
                } catch (_: Exception) {
                    MaterialTheme.colorScheme.primary
                }
            )
            Spacer(Modifier.width(8.dp))
            Text(it.name, style = MaterialTheme.typography.bodyLarge)
        } ?: Text("Select Category", style = MaterialTheme.typography.bodyLarge)
    }
    Spacer(Modifier.height(24.dp))
}

@OptIn(ExperimentalFoundationApi::class)
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
    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        items(wallets, key = { it.id }) { w ->
            val color = try {
                Color(w.color.toColorInt())
            } catch (_: Exception) {
                MaterialTheme.colorScheme.error
            }
            Card(
                modifier = Modifier
                    .size(140.dp, 110.dp)
                    .border(2.dp, if (w.id == selectedId) color else MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                    .combinedClickable(
                        onClick = { onSelect(w.id) },
                        onLongClick = { onLongPress(w) }
                    ),
                colors = CardDefaults.cardColors(containerColor = Color.Transparent),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(
                    modifier = Modifier
                        .padding(12.dp)
                        .fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(getIcon(w.iconName), contentDescription = null, tint = color, modifier = Modifier.size(32.dp))
                    Spacer(Modifier.height(6.dp))
                    Text(
                        w.name,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        style = MaterialTheme.typography.bodyLarge,
                        fontSize = when {
                            w.name.length > 15 -> 14.sp
                            w.name.length > 10 -> 16.sp
                            else -> MaterialTheme.typography.bodyLarge.fontSize
                        },
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Text(
                        "${w.currencyCode} %.2f".format(w.balance),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        item {
            Card(
                modifier = Modifier
                    .size(140.dp, 110.dp)
                    .clickable { onAdd() },
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
                shape = RoundedCornerShape(12.dp)
            ) {
                Box(Modifier.fillMaxSize(), Alignment.Center) {
                    Icon(Icons.Default.Add, contentDescription = "Add wallet", modifier = Modifier.size(32.dp))
                }
            }
        }
    }
    Spacer(Modifier.height(32.dp))
}

@Composable
private fun SubmitButton(isValid: Boolean, onSubmit: () -> Unit) {
    Button(
        onClick = onSubmit,
        enabled = isValid,
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp),
        shape = RoundedCornerShape(12.dp)
    ) {
        Text("Submit", style = MaterialTheme.typography.labelLarge)
    }
}

private fun String.isValidDecimal(): Boolean =
    matches(Regex("^\\d+(\\.\\d{0,2})?$")) && !endsWith(".")