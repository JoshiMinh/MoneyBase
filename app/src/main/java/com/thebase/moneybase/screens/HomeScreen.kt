package com.thebase.moneybase.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Transaction
import com.thebase.moneybase.data.Wallet
import com.thebase.moneybase.data.Icon.getIcon
import com.thebase.moneybase.database.AppDatabase
import com.thebase.moneybase.database.CategorySpending
import com.thebase.moneybase.functionalities.transaction.EditTransaction
import java.time.Instant
import java.time.temporal.ChronoUnit
import kotlin.math.abs

@Composable
fun HomeScreen(userId: String) {
    val context = LocalContext.current
    val db = remember(userId) { AppDatabase.getInstance(context, userId) }
    var transactions by remember { mutableStateOf(emptyList<Transaction>()) }
    var categories by remember { mutableStateOf(emptyList<Category>()) }
    var wallets by remember { mutableStateOf(emptyList<Wallet>()) }
    var categorySpending by remember { mutableStateOf(emptyList<CategorySpending>()) }

    LaunchedEffect(userId) {
        with(db) {
            transactions = transactionDao().getTop10Transactions(userId)
            categories = categoryDao().getCategoriesByUser(userId)
            wallets = walletDao().getWalletsByUser(userId)
            val cutoff = Instant.now().minus(30, ChronoUnit.DAYS)
            categorySpending = transactionDao()
                .getSpendingByCategoryLast30Days(userId, cutoff)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .background(Color.Gray) // Grey background for the entire screen
    ) {
        // Container for the pie chart and transaction history
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.LightGray) // Light grey background for the box
                .padding(16.dp)
        ) {
            // Pie Chart Section
            SpendingPieChart(
                data = categorySpending,
                categories = categories,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(240.dp)
            )
            Spacer(Modifier.height(16.dp))

            // Transaction History Section
            Text(
                text = "Transaction History",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.fillMaxWidth()
            )
            IconButton(
                onClick = { /* TODO: Add functionality here */ },
                modifier = Modifier
                    .align(Alignment.End)
                    .size(48.dp)
                    .background(Color.Cyan, shape = CircleShape) // Sky blue color for the button
            ) {
                Icon(Icons.Default.ExpandMore, contentDescription = "Extend", tint = Color.White)
            }
            Spacer(Modifier.height(8.dp))

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
}
@Composable
private fun SpendingPieChart(
    data: List<CategorySpending>,
    categories: List<Category>,
    modifier: Modifier = Modifier
) {
    val totalAmount = remember(data) { data.sumOf { it.totalAmount } }
    if (totalAmount <= 0.0) {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            Text("No expenses in the last 30 days")
        }
        return
    }

    val entries = remember(data, categories) {
        data.mapNotNull { cs ->
            categories.find { it.id == cs.categoryId }?.let { cat ->
                PieChartEntry(cat.name, cs.totalAmount.toFloat(), Color(android.graphics.Color.parseColor(cat.color)))
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

@Composable
private fun PieChart(entries: List<PieChartEntry>, size: Dp) {
    Canvas(modifier = Modifier.size(size)) {
        val sum = entries.sumOf { it.value.toDouble() }.toFloat()
        var startAngle = -90f
        entries.forEach { entry ->
            val sweep = (entry.value / sum) * 360f
            drawArc(entry.color, startAngle, sweep, useCenter = true)
            startAngle += sweep
        }
    }
}

@Composable
private fun PieChartLegend(entries: List<PieChartEntry>) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        entries.forEach { entry ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .background(entry.color, CircleShape)
                )
                Spacer(Modifier.width(8.dp))
                Text("${entry.label}: ${"%.2f".format(entry.value)}", style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
fun TransactionItem(
    transaction: Transaction,
    category: Category?,
    wallet: Wallet?
) {
    var showDialog by remember { mutableStateOf(false) }

    if (showDialog) {
        EditTransaction(transaction = transaction, onDismiss = { showDialog = false })
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showDialog = true }
            .padding(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(Color(android.graphics.Color.parseColor(category?.color ?: "#6200EE")), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(getIcon(category?.iconName ?: "shopping_cart"), contentDescription = null, tint = Color.White)
            }
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(transaction.description, style = MaterialTheme.typography.bodyMedium)
                Text(
                    "${category?.name.orEmpty()} • ${wallet?.name.orEmpty()}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    transaction.date,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }
            val absAmount = abs(transaction.amount)
            val signText = if (transaction.amount < 0) "-" else "+"
            val formattedAmount = "%.2f".format(absAmount)
            val amountColor = if (transaction.amount < 0) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
            Text(
                text = "$signText${transaction.currencyCode} $formattedAmount",
                color = amountColor,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

data class PieChartEntry(val label: String, val value: Float, val color: Color)