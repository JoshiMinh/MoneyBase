package com.thebase.moneybase.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import java.time.Instant
import java.time.temporal.ChronoUnit

@Composable
fun HomeScreen(userId: String) {
    val context = LocalContext.current
    val db = AppDatabase.getInstance(context, userId)
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<List<Category>>(emptyList()) }
    var wallets by remember { mutableStateOf<List<Wallet>>(emptyList()) }
    var categorySpending by remember { mutableStateOf<List<CategorySpending>>(emptyList()) }

    LaunchedEffect(userId) {
        transactions = db.transactionDao().getTop10Transactions(userId)
        categories = db.categoryDao().getCategoriesByUser(userId)
        wallets = db.walletDao().getWalletsByUser(userId)
        val cutoff = Instant.now().minus(30, ChronoUnit.DAYS)
        categorySpending = db.transactionDao().getSpendingByCategoryLast30Days(userId, cutoff)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.4f),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                SpendingPieChart(categorySpending, categories)
            }
        }
        Spacer(modifier = Modifier.height(16.dp))
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.6f),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                Text(
                    text = "Transaction History",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                LazyColumn {
                    items(transactions) { tx ->
                        TransactionItem(
                            transaction = tx,
                            getCategory = { id -> categories.find { it.id == id } },
                            getWallet = { id -> wallets.find { it.id == id } }
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun SpendingPieChart(
    categorySpending: List<CategorySpending>,
    categories: List<Category>
) {
    val total = categorySpending.sumOf { it.totalAmount }
    if (total == 0.0) {
        Text(text = "No expenses in last 30 days")
        return
    }
    val entries = categorySpending.mapNotNull { cs ->
        categories.find { it.id == cs.categoryId }?.let {
            PieChartEntry(it.name, cs.totalAmount.toFloat(), Color(it.color.toColorInt()))
        }
    }
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        PieChart(entries, size = 200.dp)
        Spacer(modifier = Modifier.height(16.dp))
        PieChartLegend(entries)
    }
}

@Composable
private fun PieChart(entries: List<PieChartEntry>, size: Dp = 200.dp) {
    Canvas(modifier = Modifier.size(size)) {
        val total = entries.sumOf { it.value.toDouble() }.toFloat()
        var startAngle = -90f
        entries.forEach { entry ->
            val sweep = entry.value / total * 360f
            drawArc(entry.color, startAngle, sweep, useCenter = true)
            startAngle += sweep
        }
    }
}

@Composable
private fun PieChartLegend(entries: List<PieChartEntry>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        entries.forEach { entry ->
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(vertical = 4.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .background(entry.color, CircleShape)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(text = "${entry.label}: ${"%.2f".format(entry.value)}")
            }
        }
    }
}

@Composable
fun TransactionItem(
    transaction: Transaction,
    getCategory: (String) -> Category?,
    getWallet: (String) -> Wallet?
) {
    val category = getCategory(transaction.categoryId)
    val wallet = getWallet(transaction.walletId)
    val sign = if (transaction.isIncome) "+" else "-"
    val amount = kotlin.math.abs(transaction.amount)
    val amountColor = if (transaction.isIncome) Color(0xFF4CAF50) else Color(0xFFF44336)

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(Color((category?.color ?: "#6200EE").toColorInt())),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getIcon(category?.iconName ?: "shopping_cart"),
                    contentDescription = category?.name,
                    tint = Color.White
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(text = transaction.description, style = MaterialTheme.typography.bodyLarge)
                Text(
                    text = "${category?.name ?: ""} • ${wallet?.name ?: ""}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    text = transaction.date,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }
            Text(
                text = "$sign${transaction.currencyCode} ${"%.2f".format(amount)}",
                color = amountColor,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

data class PieChartEntry(val label: String, val value: Float, val color: Color)