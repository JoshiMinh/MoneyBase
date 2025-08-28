@file:Suppress("unused")

package com.thebase.moneybase.screens.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

enum class PeriodType {
    DAY, WEEK, MONTH, YEAR, CUSTOM
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionsScreen(
    userId: String,
    navController: NavController?
) {
    val repo = remember { FirebaseRepositories() }
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<Map<String, Category>>(emptyMap()) }
    var wallets by remember { mutableStateOf<Map<String, Wallet>>(emptyMap()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var selectedPeriod by rememberSaveable { mutableStateOf(PeriodType.MONTH) }
    var selectedDate by rememberSaveable { mutableStateOf(Calendar.getInstance()) }
    var showCustomDatePicker by rememberSaveable { mutableStateOf(false) }
    var customStartDate by rememberSaveable { mutableStateOf<Date?>(null) }
    var customEndDate by rememberSaveable { mutableStateOf<Date?>(null) }

    // Fetch data when userId changes
    LaunchedEffect(userId) {
        isLoading = true
        try {
            transactions = repo.getAllTransactions(userId)
            categories = repo.getAllCategories(userId).associateBy { it.id }
            wallets = repo.getAllWallets(userId).associateBy { it.id }
            errorMessage = null
        } catch (e: Exception) {
            transactions = emptyList()
            errorMessage = "Failed to load data: ${e.message}"
        }
        isLoading = false
    }

    // Check for blank userId
    if (userId.isBlank()) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Please log in to view your transactions",
                style = MaterialTheme.typography.bodyLarge
            )
        }
        return
    }

    // Calculate date range for filtering
    val (startDate, endDate) = remember(selectedPeriod, selectedDate, customStartDate, customEndDate) {
        val start = Calendar.getInstance()
        val end = Calendar.getInstance().apply { time = selectedDate.time }

        when (selectedPeriod) {
            PeriodType.DAY -> start.apply { time = end.time }
            PeriodType.WEEK -> {
                start.apply {
                    time = end.time
                    set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
                    if (time.after(end.time)) add(Calendar.WEEK_OF_YEAR, -1)
                }
                end.apply {
                    time = start.time
                    add(Calendar.DAY_OF_YEAR, 6)
                }
            }
            PeriodType.MONTH -> start.apply {
                time = end.time
                set(Calendar.DAY_OF_MONTH, 1)
            }
            PeriodType.YEAR -> start.apply {
                time = end.time
                set(Calendar.MONTH, Calendar.JANUARY)
                set(Calendar.DAY_OF_MONTH, 1)
            }
            PeriodType.CUSTOM -> {
                start.apply { time = customStartDate ?: end.time }
                end.apply { time = customEndDate ?: start.time }
            }
        }
        Pair(start.time, end.time)
    }

    // Format display date based on period
    val displayDate = remember(selectedPeriod, startDate, endDate) {
        val df = when (selectedPeriod) {
            PeriodType.DAY -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
            PeriodType.WEEK -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
            PeriodType.MONTH -> SimpleDateFormat("MMMM yyyy", Locale.getDefault())
            PeriodType.YEAR -> SimpleDateFormat("yyyy", Locale.getDefault())
            PeriodType.CUSTOM -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
        }
        when (selectedPeriod) {
            PeriodType.WEEK, PeriodType.CUSTOM -> "${df.format(startDate)} - ${df.format(endDate)}"
            else -> df.format(selectedDate.time)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Transactions") },
                navigationIcon = {
                    IconButton(onClick = { navController?.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            // Set selectedDate to today at midnight
                            val todayCal = Calendar.getInstance().apply {
                                set(Calendar.HOUR_OF_DAY, 0)
                                set(Calendar.MINUTE, 0)
                                set(Calendar.SECOND, 0)
                                set(Calendar.MILLISECOND, 0)
                            }
                            selectedDate = todayCal

                            // If custom range, also reset customStartDate and customEndDate to today
                            if (selectedPeriod == PeriodType.CUSTOM) {
                                val todayDate = todayCal.time
                                customStartDate = todayDate
                                customEndDate = todayDate
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Today,
                            contentDescription = "Reset to current period"
                        )
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 8.dp)
        ) {
            // Date navigation card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = {
                            selectedDate = Calendar.getInstance().apply {
                                time = selectedDate.time
                                when (selectedPeriod) {
                                    PeriodType.DAY -> add(Calendar.DAY_OF_YEAR, -1)
                                    PeriodType.WEEK -> add(Calendar.WEEK_OF_YEAR, -1)
                                    PeriodType.MONTH -> add(Calendar.MONTH, -1)
                                    PeriodType.YEAR -> add(Calendar.YEAR, -1)
                                    PeriodType.CUSTOM -> add(Calendar.DAY_OF_YEAR, -1)
                                }
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Previous period"
                        )
                    }
                    Text(
                        text = displayDate,
                        style = MaterialTheme.typography.bodyLarge,
                        modifier = Modifier.weight(1f),
                        textAlign = TextAlign.Center
                    )
                    IconButton(
                        onClick = {
                            selectedDate = Calendar.getInstance().apply {
                                time = selectedDate.time
                                when (selectedPeriod) {
                                    PeriodType.DAY -> add(Calendar.DAY_OF_YEAR, 1)
                                    PeriodType.WEEK -> add(Calendar.WEEK_OF_YEAR, 1)
                                    PeriodType.MONTH -> add(Calendar.MONTH, 1)
                                    PeriodType.YEAR -> add(Calendar.YEAR, 1)
                                    PeriodType.CUSTOM -> add(Calendar.DAY_OF_YEAR, 1)
                                }
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                            contentDescription = "Next period"
                        )
                    }
                }
            }

            // Transaction list
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                )
            ) {
                if (isLoading) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = Color.White)
                    }
                } else {
                    val filteredTransactions = remember(transactions, startDate, endDate) {
                        transactions.filter { transaction ->
                            val transactionDate = transaction.date.toDate()
                            !transactionDate.before(startDate) && !transactionDate.after(endDate)
                        }.sortedByDescending { it.date.toDate().time }
                    }

                    if (errorMessage != null) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = errorMessage!!,
                                color = Color.Red,
                                textAlign = TextAlign.Center
                            )
                        }
                    } else if (filteredTransactions.isEmpty()) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "No transactions found for the selected period",
                                color = Color.White.copy(alpha = 0.7f),
                                textAlign = TextAlign.Center
                            )
                        }
                    } else {
                        val totalIncome = filteredTransactions.filter { it.isIncome }
                            .sumOf { it.amount.toDouble() }
                        val totalExpense = filteredTransactions.filter { !it.isIncome }
                            .sumOf { abs(it.amount.toDouble()) }

                        Column(
                            modifier = Modifier.fillMaxSize()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp, vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column {
                                    Text(
                                        "Total Income",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    Text(
                                        "$${totalIncome.toInt()}",
                                        style = MaterialTheme.typography.bodyLarge,
                                        color = Color.Green
                                    )
                                }
                                Column {
                                    Text(
                                        "Total Expenses",
                                        style = MaterialTheme.typography.bodyMedium
                                    )
                                    Text(
                                        "$${totalExpense.toInt()}",
                                        style = MaterialTheme.typography.bodyLarge,
                                        color = Color.Red
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            val listState = rememberLazyListState()

                            LaunchedEffect(filteredTransactions) {
                                listState.animateScrollToItem(0)
                            }

                            LazyColumn(
                                modifier = Modifier.fillMaxSize(),
                                contentPadding = PaddingValues(16.dp),
                                state = listState
                            ) {
                                items(filteredTransactions) { transaction ->
                                    TransactionItem(
                                        transaction = transaction,
                                        category = categories[transaction.categoryId],
                                        wallet = wallets[transaction.walletId]
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Period selector card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    PeriodType.entries.forEach { period ->
                        FilterChip(
                            selected = selectedPeriod == period,
                            onClick = {
                                if (period == PeriodType.CUSTOM) {
                                    showCustomDatePicker = true
                                } else {
                                    selectedPeriod = period
                                    customStartDate = null
                                    customEndDate = null
                                }
                            },
                            label = { Text(period.name.lowercase().replaceFirstChar { it.uppercase() }) }
                        )
                    }
                }
            }
        }
    }

    // Custom date range picker dialog
    if (showCustomDatePicker) {
        CustomDateRangePickerDialog(
            initialStartDate = customStartDate ?: Date(),
            initialEndDate = customEndDate ?: Date(),
            onConfirm = { start, end ->
                selectedPeriod = PeriodType.CUSTOM
                customStartDate = start
                customEndDate = end
                selectedDate = Calendar.getInstance().apply { time = end }
                showCustomDatePicker = false
            },
            onDismiss = { showCustomDatePicker = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CustomDateRangePickerDialog(
    initialStartDate: Date,
    initialEndDate: Date,
    onConfirm: (start: Date, end: Date) -> Unit,
    onDismiss: () -> Unit
) {
    var step by rememberSaveable { mutableStateOf(0) } // 0 = picking start, 1 = picking end
    var selectedStartMillis by rememberSaveable { mutableStateOf(initialStartDate.time) }
    var selectedEndMillis by rememberSaveable { mutableStateOf(initialEndDate.time) }

    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = if (step == 0) selectedStartMillis else selectedEndMillis
    )

    val isEndValid = selectedEndMillis >= selectedStartMillis

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(if (step == 0) "Select Start Date" else "Select End Date")
        },
        text = {
            DatePicker(state = datePickerState)
        },
        confirmButton = {
            when (step) {
                0 -> {
                    TextButton(onClick = {
                        datePickerState.selectedDateMillis?.let {
                            selectedStartMillis = it
                            step = 1 // Go to end date selection
                        }
                    }) {
                        Text("Next")
                    }
                }
                1 -> {
                    val isValid = datePickerState.selectedDateMillis != null &&
                            datePickerState.selectedDateMillis!! >= selectedStartMillis
                    TextButton(
                        onClick = {
                            datePickerState.selectedDateMillis?.let {
                                selectedEndMillis = it
                                onConfirm(Date(selectedStartMillis), Date(selectedEndMillis))
                            }
                        },
                        enabled = isValid
                    ) {
                        Text("Confirm")
                    }
                }
            }
        },
        dismissButton = {
            Row {
                if (step == 1) {
                    TextButton(onClick = { step = 0 }) {
                        Text("Back")
                    }
                }
                TextButton(onClick = onDismiss) {
                    Text("Cancel")
                }
            }
        }
    )
}