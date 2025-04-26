package com.thebase.moneybase.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.firebase.*
import com.thebase.moneybase.functionalities.customizability.Icon.getIcon
import com.thebase.moneybase.functionalities.agents.EditTransaction
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

/**
 * The main Home screen, showing a spending pie chart and recent transactions.
 *
 * @param userId The authenticated user's ID.
 */
@Composable
fun HomeScreen(userId: String) {
    // Firestore repositories (with offline persistence enabled in MoneyBaseApplication)
    val txRepo = remember { TransactionRepository() }
    val catRepo = remember { CategoryRepository() }
    val wlRepo = remember { WalletRepository() }

    // UI state
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<List<Category>>(emptyList()) }
    var wallets by remember { mutableStateOf<List<Wallet>>(emptyList()) }
    var categorySpending by remember { mutableStateOf<List<CategorySpending>>(emptyList()) }

    // Load data once per userId
    LaunchedEffect(userId) {
        runCatching {
            // Fetch concurrently on the IO dispatcher
            val txs = withContext(Dispatchers.IO) { txRepo.getTransactions(userId) }
            val cats = withContext(Dispatchers.IO) { catRepo.getCategories(userId) }
            val wls = withContext(Dispatchers.IO) { wlRepo.getWallets(userId) }
            Triple(txs, cats, wls)
        }.onSuccess { (txs, cats, wls) ->
            // Keep only the last 10 transactions
            transactions = txs.takeLast(10)
            categories = cats
            wallets = wls
            categorySpending = calculateCategorySpending(transactions)
        }.onFailure {
            // TODO: show an error indicator (e.g., Snackbar) on failure
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Pie chart of spending by category
        SpendingPieChart(
            data = categorySpending,
            categories = categories,
            modifier = Modifier
                .fillMaxWidth()
                .height(240.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Recent transaction history
        Text(
            text = "Transaction History",
            style = MaterialTheme.typography.titleLarge
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(transactions) { tx ->
                TransactionItem(
                    transaction = tx,
                    category = categories.firstOrNull { it.id == tx.categoryId },
                    wallet = wallets.firstOrNull { it.id == tx.walletId }
                )
            }
        }
    }
}

/**
 * Displays a pie chart of spending, with a legend.
 *
 * @param data List of CategorySpending entries.
 * @param categories All categories to lookup names/colors.
 */
@Composable
private fun SpendingPieChart(
    data: List<CategorySpending>,
    categories: List<Category>,
    modifier: Modifier = Modifier
) {
    val total = remember(data) { data.sumOf { it.totalAmount } }
    if (total <= 0.0) {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            Text("No expenses in the last 30 days")
        }
        return
    }

    // Map spending to chart entries
    val entries = remember(data, categories) {
        data.mapNotNull { cs ->
            categories.find { it.id == cs.categoryId }?.let { cat ->
                PieChartEntry(
                    label = cat.name,
                    value = cs.totalAmount.toFloat(),
                    color = Color(android.graphics.Color.parseColor(cat.color))
                )
            }
        }
    }

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        PieChart(entries = entries, size = 200.dp)
        Spacer(Modifier.height(8.dp))
        PieChartLegend(entries = entries)
    }
}

/** Draws the pie chart arcs. */
@Composable
private fun PieChart(entries: List<PieChartEntry>, size: Dp) {
    Canvas(modifier = Modifier.size(size)) {
        val sum = entries.sumOf { it.value.toDouble() }.toFloat()
        var startAngle = -90f
        entries.forEach { e ->
            val sweep = (e.value / sum) * 360f
            drawArc(
                color = e.color,
                startAngle = startAngle,
                sweepAngle = sweep,
                useCenter = true
            )
            startAngle += sweep
        }
    }
}

/** Displays a legend for the pie chart. */
@Composable
private fun PieChartLegend(entries: List<PieChartEntry>) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        entries.forEach { e ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .background(e.color, shape = CircleShape)
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "${e.label}: ${"%.2f".format(e.value)}",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}

/**
 * A single transaction row with click-to-edit dialog.
 */
@Composable
fun TransactionItem(
    transaction: Transaction,
    category: Category?,
    wallet: Wallet?
) {
    var showDialog by remember { mutableStateOf(false) }

    if (showDialog) {
        EditTransaction(
            transaction = transaction,
            onDismiss = { showDialog = false }
        )
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showDialog = true }
            .padding(vertical = 4.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Category icon circle
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(
                        color = category?.color?.let { Color(android.graphics.Color.parseColor(it)) }
                            ?: MaterialTheme.colorScheme.primary,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getIcon(category?.iconName ?: ""),
                    contentDescription = null,
                    tint = Color.White
                )
            }

            Spacer(Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(transaction.description, style = MaterialTheme.typography.bodyMedium)

                // Show "Category • Wallet"
                Text(
                    listOfNotNull(category?.name, wallet?.name).joinToString(" • "),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )

                // Format timestamp
                val dateText = remember(transaction.date) {
                    SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
                        .format(transaction.date.toDate())
                }
                Text(
                    dateText,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }

            // Amount with sign and coloring
            val amount = abs(transaction.amount)
            val sign = if (transaction.amount < 0) "-" else "+"
            val formatted = "%.2f".format(amount)
            val color = if (transaction.amount < 0) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary

            Text(
                text = "$sign${transaction.currencyCode} $formatted",
                color = color,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

/** Aggregate spending per category over the last `days` days. */
private fun calculateCategorySpending(
    transactions: List<Transaction>,
    days: Int = 30
): List<CategorySpending> {
    val threshold = Calendar.getInstance().apply {
        add(Calendar.DAY_OF_YEAR, -days)
    }.timeInMillis

    return transactions
        .filter { !it.isIncome && it.date.toDate().time >= threshold }
        .groupBy { it.categoryId }
        .map { (categoryId, list) ->
            CategorySpending(categoryId, list.sumOf { it.amount })
        }
}

/** Data class for pie chart entries. */
data class PieChartEntry(
    val label: String,
    val value: Float,
    val color: Color
)

/** Data class for holding spending totals. */
data class CategorySpending(
    val categoryId: String,
    val totalAmount: Double
)