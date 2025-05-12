package com.thebase.moneybase.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.thebase.moneybase.database.*
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs
import kotlin.math.max

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    userId: String,
    navController: NavController? = null
) {
    val repo = remember { FirebaseRepositories() }
    var selectedMonth by remember { mutableStateOf(Calendar.getInstance()) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Transaction History") },
                navigationIcon = {
                    IconButton(onClick = { navController?.popBackStack() }) {
                        Icon(imageVector = Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black,
                    titleContentColor = Color.White
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 8.dp)
        ) {
            MonthYearPicker(selectedMonth) { selectedMonth = it }

            Spacer(modifier = Modifier.height(16.dp))

            IncomeExpenseChart(userId, repo, selectedMonth)

            Spacer(modifier = Modifier.height(16.dp))

            TransactionList(userId, repo, selectedMonth, navController)
        }
    }
}

@Composable
fun MonthYearPicker(selectedMonth: Calendar, onMonthChanged: (Calendar) -> Unit) {
    Card(modifier = Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(Color(0xFF1C1C1C))) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = {
                val newMonth = selectedMonth.clone() as Calendar
                newMonth.add(Calendar.MONTH, -1)
                onMonthChanged(newMonth)
            }) {
                Icon(Icons.Default.ChevronLeft, "Previous Month", tint = Color.White)
            }

            Text(
                text = SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(selectedMonth.time),
                style = MaterialTheme.typography.titleMedium,
                color = Color.White
            )

            IconButton(onClick = {
                val newMonth = selectedMonth.clone() as Calendar
                newMonth.add(Calendar.MONTH, 1)
                val currentMonth = Calendar.getInstance().apply { set(Calendar.DAY_OF_MONTH, 1) }
                if (newMonth.timeInMillis <= currentMonth.timeInMillis) onMonthChanged(newMonth)
            }) {
                Icon(Icons.Default.ChevronRight, "Next Month", tint = Color.White)
            }
        }
    }
}

@Composable
fun IncomeExpenseChart(userId: String, repo: FirebaseRepositories, selectedMonth: Calendar) {
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(userId, selectedMonth) {
        isLoading = true
        transactions = try { repo.getAllTransactions(userId) } catch (e: Exception) { emptyList() }
        isLoading = false
    }

    Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(Color(0xFF1C1C1C))) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            Text("Income vs Expenses", style = MaterialTheme.typography.titleMedium, color = Color.White)

            if (isLoading) {
                Box(Modifier.fillMaxWidth().height(200.dp), Alignment.Center) {
                    CircularProgressIndicator(color = Color.White)
                }
            } else {
                val start = Calendar.getInstance().apply { time = selectedMonth.time; set(Calendar.DAY_OF_MONTH, 1) }
                val end = Calendar.getInstance().apply { time = selectedMonth.time; set(Calendar.DAY_OF_MONTH, getActualMaximum(Calendar.DAY_OF_MONTH)) }
                val df = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())

                val filtered = transactions.filter {
                    runCatching { df.parse(it.date) }.getOrNull()?.let { d -> d >= start.time && d <= end.time } ?: false
                }

                val income = filtered.filter { it.isIncome }.sumOf { abs(it.amount) }.toFloat()
                val expense = filtered.filter { !it.isIncome }.sumOf { abs(it.amount) }.toFloat()

                if (filtered.isEmpty()) {
                    Box(Modifier.fillMaxWidth().height(200.dp), Alignment.Center) {
                        Text("No transactions found for this month", color = Color.White.copy(0.7f), textAlign = TextAlign.Center)
                    }
                } else {
                    Row(Modifier.fillMaxWidth().height(200.dp), Arrangement.SpaceEvenly, Alignment.Bottom) {
                        listOf("Income" to income to Color.Green, "Expenses" to expense to Color.Red).forEach { (labelValue, color) ->
                            val (label, value) = labelValue
                            val maxVal = max(income, expense)
                            val height = if (maxVal > 0) (value / maxVal * 150).dp else 0.dp
                            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Bottom, modifier = Modifier.weight(1f)) {
                                Box(Modifier.width(60.dp).height(height).background(color))
                                Spacer(Modifier.height(8.dp))
                                Text(label, style = MaterialTheme.typography.bodyMedium, color = Color.White)
                            }
                        }
                    }
                    Row(Modifier.fillMaxWidth().padding(top = 16.dp), Arrangement.SpaceBetween) {
                        listOf("Income" to income to Color.Green, "Expenses" to expense to Color.Red).forEach { (labelValue, color) ->
                            val (label, value) = labelValue
                            Column(horizontalAlignment = if (label == "Income") Alignment.Start else Alignment.End) {
                                Text(label, style = MaterialTheme.typography.bodyMedium, color = Color.White)
                                Text("$${value.toInt()}", style = MaterialTheme.typography.bodyLarge, color = color)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun TransactionList(userId: String, repo: FirebaseRepositories, selectedMonth: Calendar, navController: NavController?) {
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<Map<String, Category>>(emptyMap()) }
    var wallets by remember { mutableStateOf<Map<String, Wallet>>(emptyMap()) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(userId, selectedMonth) {
        isLoading = true
        try {
            transactions = repo.getAllTransactions(userId)
            categories = repo.getAllCategories(userId).associateBy { it.id }
            wallets = repo.getAllWallets(userId).associateBy { it.id }
            val start = Calendar.getInstance().apply { time = selectedMonth.time; set(Calendar.DAY_OF_MONTH, 1) }
            val end = Calendar.getInstance().apply { time = selectedMonth.time; set(Calendar.DAY_OF_MONTH, getActualMaximum(Calendar.DAY_OF_MONTH)) }
            val df = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())
            transactions = transactions.filter {
                runCatching { df.parse(it.date) }.getOrNull()?.let { d -> d >= start.time && d <= end.time } ?: false
            }.sortedByDescending { runCatching { df.parse(it.date)?.time }.getOrNull() ?: 0L }
        } catch (e: Exception) { transactions = emptyList() }
        isLoading = false
    }

    Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(Color(0xFF1C1C1C))) {
        Column(Modifier.fillMaxWidth().padding(16.dp)) {
            Row(Modifier.fillMaxWidth().padding(bottom = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                Text("All Transactions", style = MaterialTheme.typography.titleMedium, color = Color.White, modifier = Modifier.weight(1f))
                IconButton(onClick = { navController?.navigate("all_transaction") }) {
                    Icon(Icons.Default.ChevronRight, "View All", tint = Color.White)
                }
            }
            if (isLoading) {
                Box(Modifier.fillMaxWidth().height(200.dp), Alignment.Center) { CircularProgressIndicator(color = Color.White) }
            } else if (transactions.isEmpty()) {
                Box(Modifier.fillMaxWidth().height(200.dp), Alignment.Center) {
                    Text("No transactions found for this month", color = Color.White.copy(0.7f), textAlign = TextAlign.Center)
                }
            } else {
                LazyColumn(Modifier.fillMaxWidth().heightIn(max = 400.dp)) {
                    items(transactions) { t ->
                        TransactionItem(transaction = t, category = categories[t.categoryId], wallet = wallets[t.walletId])
                        if (t != transactions.last()) Divider(Modifier.padding(vertical = 4.dp), color = Color.White.copy(0.2f))
                    }
                }
            }
        }
    }
}