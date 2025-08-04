@file:Suppress("unused")

package com.thebase.moneybase.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Today
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.google.accompanist.pager.HorizontalPager
import com.google.accompanist.pager.HorizontalPagerIndicator
import com.google.accompanist.pager.rememberPagerState
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import com.thebase.moneybase.screens.home.charts.ExpensePieChart
import com.thebase.moneybase.screens.home.charts.IncomeExpenseBarChart
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReportScreen(
    userId: String,
    navController: NavController?
) {
    val repo = remember { FirebaseRepositories() }

    // State management
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<List<Category>>(emptyList()) }
    var wallets by remember { mutableStateOf<List<Wallet>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var selectedPeriod by remember { mutableStateOf(ChartPeriodType.MONTH) }
    var selectedDate by remember { mutableStateOf(Calendar.getInstance()) }
    var showCustomDatePicker by remember { mutableStateOf(false) }
    var customStartDate by remember { mutableStateOf<Date?>(null) }
    var customEndDate by remember { mutableStateOf<Date?>(null) }

    // Fetch data from Firebase
    LaunchedEffect(userId) {
        if (userId.isBlank()) return@LaunchedEffect
        isLoading = true
        try {
            transactions = repo.getAllTransactions(userId)
            categories = repo.getAllCategories(userId)
            wallets = repo.getAllWallets(userId)
            errorMessage = null
        } catch (e: Exception) {
            errorMessage = "Failed to load data: ${e.message}"
        } finally {
            isLoading = false
        }
    }

    // Handle empty userId
    if (userId.isBlank()) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Please log in to view reports",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.error
            )
        }
        return
    }

    // Calculate date range for selected period
    val (startDate, endDate) = remember(selectedPeriod, selectedDate, customStartDate, customEndDate, transactions) {
        val start = Calendar.getInstance()
        val end = Calendar.getInstance().apply { time = selectedDate.time }
        when (selectedPeriod) {
            ChartPeriodType.DAY -> start.time = end.time
            ChartPeriodType.WEEK -> {
                start.time = end.time
                start.set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
                if (start.time.after(end.time)) start.add(Calendar.WEEK_OF_YEAR, -1)
                end.time = start.time
                end.add(Calendar.DAY_OF_YEAR, 6)
            }
            ChartPeriodType.MONTH -> {
                start.time = end.time
                start.set(Calendar.DAY_OF_MONTH, 1)
                end.set(Calendar.DAY_OF_MONTH, end.getActualMaximum(Calendar.DAY_OF_MONTH))
            }
            ChartPeriodType.YEAR -> {
                start.time = end.time
                start.set(Calendar.MONTH, Calendar.JANUARY)
                start.set(Calendar.DAY_OF_MONTH, 1)
                end.set(Calendar.MONTH, Calendar.DECEMBER)
                end.set(Calendar.DAY_OF_MONTH, 31)
            }
            ChartPeriodType.CUSTOM -> {
                start.time = customStartDate ?: end.time
                end.time = customEndDate ?: start.time
            }
            ChartPeriodType.ALL -> {
                val df = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())
                val allDates = transactions.mapNotNull {
                    runCatching { df.parse(it.date) }.getOrNull()
                }
                val min = allDates.minOrNull() ?: Date()
                val max = allDates.maxOrNull() ?: Date()
                start.time = min
                end.time = max
            }
        }
        start.apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        end.apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        start.time to end.time
    }

    // Format display date
    val displayDate = remember(selectedPeriod, startDate, endDate) {
        val df = when (selectedPeriod) {
            ChartPeriodType.DAY -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
            ChartPeriodType.WEEK, ChartPeriodType.CUSTOM -> SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
            ChartPeriodType.MONTH -> SimpleDateFormat("MMMM yyyy", Locale.getDefault())
            ChartPeriodType.YEAR -> SimpleDateFormat("yyyy", Locale.getDefault())
            ChartPeriodType.ALL -> null
        }
        when (selectedPeriod) {
            ChartPeriodType.WEEK, ChartPeriodType.CUSTOM -> "${df?.format(startDate)} - ${df?.format(endDate)}"
            ChartPeriodType.ALL -> "All Time"
            else -> df?.format(selectedDate.time) ?: ""
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Financial Reports",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Medium
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController?.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = {
                        val today = Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        selectedDate = today
                        if (selectedPeriod == ChartPeriodType.CUSTOM) {
                            customStartDate = today.time
                            customEndDate = today.time
                        }
                    }) {
                        Icon(Icons.Filled.Today, contentDescription = "Reset to Today")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 8.dp)
        ) {
            // Date navigation card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    IconButton(
                        onClick = {
                            selectedDate = Calendar.getInstance().apply {
                                time = selectedDate.time
                                when (selectedPeriod) {
                                    ChartPeriodType.DAY -> add(Calendar.DAY_OF_YEAR, -1)
                                    ChartPeriodType.WEEK -> add(Calendar.WEEK_OF_YEAR, -1)
                                    ChartPeriodType.MONTH -> add(Calendar.MONTH, -1)
                                    ChartPeriodType.YEAR -> add(Calendar.YEAR, -1)
                                    ChartPeriodType.CUSTOM -> add(Calendar.DAY_OF_YEAR, -1)
                                    ChartPeriodType.ALL -> {}
                                }
                            }
                        },
                        enabled = selectedPeriod != ChartPeriodType.ALL
                    ) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous Period")
                    }

                    Text(
                        text = displayDate,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.weight(1f)
                    )

                    IconButton(
                        onClick = {
                            selectedDate = Calendar.getInstance().apply {
                                time = selectedDate.time
                                when (selectedPeriod) {
                                    ChartPeriodType.DAY -> add(Calendar.DAY_OF_YEAR, 1)
                                    ChartPeriodType.WEEK -> add(Calendar.WEEK_OF_YEAR, 1)
                                    ChartPeriodType.MONTH -> add(Calendar.MONTH, 1)
                                    ChartPeriodType.YEAR -> add(Calendar.YEAR, 1)
                                    ChartPeriodType.CUSTOM -> add(Calendar.DAY_OF_YEAR, 1)
                                    ChartPeriodType.ALL -> {}
                                }
                            }
                        },
                        enabled = selectedPeriod != ChartPeriodType.ALL
                    ) {
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next Period")
                    }
                }
            }

            // Content area
            when {
                isLoading -> {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                errorMessage != null -> {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = errorMessage!!,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge
                        )
                    }
                }
                transactions.isEmpty() -> {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxWidth(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No transactions available",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
                else -> {
                    val df = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())
                    val periodTxns = remember(transactions, startDate, endDate) {
                        transactions.filter {
                            runCatching { df.parse(it.date) }.getOrNull()?.let { d ->
                                !d.before(startDate) && !d.after(endDate)
                            } ?: false
                        }
                    }

                    val sortedCategories = remember(periodTxns, categories) {
                        val categoryMap = categories.associateBy { it.id }
                        val amountByCat = mutableMapOf<String, Triple<String, Float, String>>()
                        periodTxns.filter { !it.isIncome }.forEach { expense ->
                            categoryMap[expense.categoryId]?.let { cat ->
                                val amt = abs(expense.amount.toFloat())
                                val prev = amountByCat[cat.id]?.second ?: 0f
                                amountByCat[cat.id] = Triple(cat.name, prev + amt, cat.color)
                            }
                        }
                        amountByCat.values.sortedByDescending { it.second }
                    }

                    val pagerState = rememberPagerState(initialPage = 0)

                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f)
                            .padding(vertical = 8.dp)
                    ) {
                        HorizontalPager(
                            count = 2,
                            state = pagerState,
                            modifier = Modifier.weight(1f)
                        ) { page ->
                            Card(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .padding(horizontal = 8.dp, vertical = 4.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                                ),
                                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .padding(16.dp)
                                ) {
                                    when (page) {
                                        0 -> ExpensePieChart(
                                            expenses = periodTxns.filter { !it.isIncome },
                                            sortedCategories = sortedCategories
                                        )
                                        1 -> IncomeExpenseBarChart(
                                            transactions = periodTxns
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        HorizontalPagerIndicator(
                            pagerState = pagerState,
                            modifier = Modifier.align(Alignment.CenterHorizontally),
                            activeColor = MaterialTheme.colorScheme.primary,
                            inactiveColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                        )
                    }
                }
            }

            // Period selection card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    // Display all periods except ALL first
                    ChartPeriodType.values().filter { it != ChartPeriodType.ALL }.forEach { period ->
                        FilterChip(
                            selected = selectedPeriod == period,
                            onClick = {
                                if (period == ChartPeriodType.CUSTOM) {
                                    showCustomDatePicker = true
                                } else {
                                    selectedPeriod = period
                                    customStartDate = null
                                    customEndDate = null
                                }
                            },
                            label = {
                                Text(
                                    text = period.name.lowercase().replaceFirstChar { it.uppercase() },
                                    style = MaterialTheme.typography.labelLarge
                                )
                            },
                            modifier = Modifier.padding(horizontal = 4.dp)
                        )
                    }
                    // Display ALL period last
                    FilterChip(
                        selected = selectedPeriod == ChartPeriodType.ALL,
                        onClick = {
                            selectedPeriod = ChartPeriodType.ALL
                            customStartDate = null
                            customEndDate = null
                        },
                        label = {
                            Text(
                                text = "All",
                                style = MaterialTheme.typography.labelLarge
                            )
                        },
                        modifier = Modifier.padding(horizontal = 4.dp)
                    )
                }
            }
        }

        // Custom date picker dialog
        if (showCustomDatePicker) {
            CustomDateRangePickerDialog(
                initialStartDate = customStartDate ?: Date(),
                initialEndDate = customEndDate ?: Date(),
                onConfirm = { start, end ->
                    selectedPeriod = ChartPeriodType.CUSTOM
                    customStartDate = start
                    customEndDate = end
                    selectedDate = Calendar.getInstance().apply { time = end }
                    showCustomDatePicker = false
                },
                onDismiss = { showCustomDatePicker = false }
            )
        }
    }
}

enum class ChartPeriodType {
    DAY, WEEK, MONTH, YEAR, CUSTOM, ALL
}