@file:Suppress("unused", "DEPRECATION")

package com.thebase.moneybase.screens.home

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.pager.HorizontalPager
import com.thebase.moneybase.utils.components.HorizontalPagerIndicator
import androidx.compose.foundation.pager.rememberPagerState
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import com.thebase.moneybase.screens.home.charts.ExpensePieChart
import com.thebase.moneybase.screens.home.charts.IncomeExpenseBarChart
import com.thebase.moneybase.screens.home.charts.LineChart
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs

@SuppressLint("ConstantLocale")
private val readableDateFormat = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
@SuppressLint("ConstantLocale")
private val monthYearFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class, ExperimentalLayoutApi::class)
@Composable
fun ReportScreen(
    userId: String,
    navController: NavController?
) {
    val repo = remember { FirebaseRepositories() }

    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<List<Category>>(emptyList()) }
    var wallets by remember { mutableStateOf<List<Wallet>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var selectedPeriod by rememberSaveable { mutableStateOf(ChartPeriodType.MONTH) }
    var selectedDate by rememberSaveable { mutableStateOf(Calendar.getInstance()) }
    var showCustomDatePicker by rememberSaveable { mutableStateOf(false) }
    var customStartDate by rememberSaveable { mutableStateOf<Date?>(null) }
    var customEndDate by rememberSaveable { mutableStateOf<Date?>(null) }

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

    if (userId.isBlank()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Please log in to view reports", color = MaterialTheme.colorScheme.error)
        }
        return
    }

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
                val dates = transactions.map { it.date.toDate() }
                val min = dates.minOrNull() ?: Date()
                val max = dates.maxOrNull() ?: Date()
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

    val displayDate = remember(selectedPeriod, startDate, endDate) {
        when (selectedPeriod) {
            ChartPeriodType.WEEK, ChartPeriodType.CUSTOM -> "${readableDateFormat.format(startDate)} - ${readableDateFormat.format(endDate)}"
            ChartPeriodType.MONTH -> monthYearFormat.format(selectedDate.time)
            ChartPeriodType.DAY -> readableDateFormat.format(selectedDate.time)
            ChartPeriodType.YEAR -> SimpleDateFormat("yyyy", Locale.getDefault()).format(selectedDate.time)
            ChartPeriodType.ALL -> "All Time"
        }
    }

    val periodTxns = remember(transactions, startDate, endDate) {
        transactions.filter {
            val d = it.date.toDate()
            !d.before(startDate) && !d.after(endDate)
        }
    }

    val sortedCategories = remember(periodTxns, categories) {
        val categoryMap = categories.associateBy { it.id }
        val amountByCat = mutableMapOf<String, Triple<String, Float, String>>()
        periodTxns.filter { !it.isIncome }.forEach { txn ->
            categoryMap[txn.categoryId]?.let { cat ->
                val amt = abs(txn.amount.toFloat())
                val prev = amountByCat[cat.id]?.second ?: 0f
                amountByCat[cat.id] = Triple(cat.name, prev + amt, cat.color)
            }
        }
        amountByCat.values.sortedByDescending { it.second }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Financial Reports", fontWeight = FontWeight.Medium) },
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
                        Icon(Icons.Filled.Today, contentDescription = "Today")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Date navigation
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f))
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
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous")
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
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next")
                    }
                }
            }

            // Charts or messages
            when {
                isLoading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }

                errorMessage != null -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(errorMessage ?: "", color = MaterialTheme.colorScheme.error)
                }

                transactions.isEmpty() -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No transactions available.")
                }

                else -> {
                    val pagerState = rememberPagerState(initialPage = 0) { 3 }

                    Column(modifier = Modifier.weight(1f)) {
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 8.dp, vertical = 4.dp),
                            colors = CardDefaults.cardColors(MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f))
                        ) {
                            HorizontalPager(
                                state = pagerState,
                                modifier = Modifier.fillMaxWidth()
                            ) { page ->
                                Box(modifier = Modifier.fillMaxSize()) {
                                    when (page) {
                                        0 -> ExpensePieChart(
                                            expenses = periodTxns.filter { !it.isIncome },
                                            sortedCategories = sortedCategories
                                        )

                                        1 -> IncomeExpenseBarChart(transactions = periodTxns)

                                        2 -> LineChart(
                                            transactions = periodTxns,
                                            startDate = startDate,
                                            endDate = endDate
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        HorizontalPagerIndicator(
                            pagerState = pagerState,
                            modifier = Modifier.align(Alignment.CenterHorizontally)
                        )
                    }
                }
            }

            // Period selection
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f))
            ) {
                FlowRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    ChartPeriodType.entries.forEach { period ->
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
                }
            }
        }

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