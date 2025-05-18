@file:Suppress("unused")

package com.thebase.moneybase.screens

import android.annotation.SuppressLint
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.core.graphics.toColorInt
import androidx.navigation.NavController
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import com.thebase.moneybase.screens.home.TransactionItem
import io.github.dautovicharis.charts.PieChart
import io.github.dautovicharis.charts.model.toChartDataSet
import io.github.dautovicharis.charts.style.PieChartDefaults
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs

@Composable
fun HomeScreen(userId: String, navController: NavController) {
    val repo = remember { FirebaseRepositories() }

    val transactions by repo.getTransactionsFlow(userId).collectAsState(initial = emptyList())
    val categories by repo.getCategoriesFlow(userId).collectAsState(initial = emptyList())
    val wallets by repo.getWalletsFlow(userId).collectAsState(initial = emptyList())

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp)
    ) {
        AddCustomPieChart(
            transactions = transactions,
            categories = categories,
            onClick = { navController.navigate("report") },
            modifier = Modifier
                .fillMaxWidth()
                .height(320.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        RecentTransactionWidget(
            transactions = transactions,
            categories = categories,
            wallets = wallets,
            onClick = { navController.navigate("history") },
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        )
    }
}

@Suppress("DEPRECATION")
@Composable
fun AddCustomPieChart(
    transactions: List<Transaction>,
    categories: List<Category>,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val calendar = remember { Calendar.getInstance() }
    val currentMonth = calendar.get(Calendar.MONTH)
    val currentYear = calendar.get(Calendar.YEAR)

    val (currentMonthExpense, sortedCategories) = remember(transactions to categories) {
        val expenses = transactions.filter { !it.isIncome && it.amount < 0 }
        val filtered = expenses.filter {
            runCatching {
                val date = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(it.date)
                Calendar.getInstance().apply { time = date!! }.let { cal ->
                    cal.get(Calendar.MONTH) == currentMonth && cal.get(Calendar.YEAR) == currentYear
                }
            }.getOrDefault(false)
        }

        val categoryMap = categories.associateBy { it.id }
        val categoryAmountMap = mutableMapOf<String, Triple<String, Float, String>>()

        filtered.forEach { expense ->
            categoryMap[expense.categoryId]?.let { category ->
                val amount = abs(expense.amount).toFloat()
                val current = categoryAmountMap[category.id]?.second ?: 0f
                categoryAmountMap[category.id] = Triple(category.name, current + amount, category.color)
            }
        }

        filtered to categoryAmountMap.values.sortedByDescending { it.second }
    }

    if (currentMonthExpense.isEmpty()) {
        Box(
            modifier = Modifier.fillMaxWidth(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "No expenses found for this month",
                style = MaterialTheme.typography.bodyMedium
            )
        }
        return
    }

    Card(
        modifier = modifier
            .padding(6.dp)
            .clickable { onClick() },
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = SimpleDateFormat("MMM yyyy", Locale.getDefault()).format(Date()),
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(250.dp)
            ) {
                val names = sortedCategories.map { it.first }
                val amounts = sortedCategories.map { it.second }
                val colors = sortedCategories.map { Color(it.third.toColorInt()) }
                val total = amounts.sum()

                val dataSet = amounts.toChartDataSet(
                    title = "",
                    postfix = "$",
                    labels = names
                )
                val style = PieChartDefaults.style(
                    borderColor = Color.White,
                    donutPercentage = 40f,
                    borderWidth = 6f,
                    pieColors = colors
                )

                Box(
                    modifier = Modifier
                        .width(200.dp)
                        .fillMaxHeight(),
                    contentAlignment = Alignment.Center
                ) {
                    PieChart(dataSet = dataSet, style = style)
                }

                Divider(
                    modifier = Modifier
                        .fillMaxHeight()
                        .width(1.dp)
                        .background(Color.White.copy(alpha = 0.3f))
                )

                Column(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .padding(start = 8.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    sortedCategories.take(3).forEachIndexed { index, (label, value, _) ->
                        val percent = (value / total * 100).toInt()
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(12.dp)
                                    .background(colors[index], shape = CircleShape)
                            )
                            Spacer(Modifier.width(4.dp))
                            Text(
                                text = "$label - $${value.toInt()} ($percent%)",
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }

                    if (sortedCategories.size > 3) {
                        Text(
                            text = "+${sortedCategories.size - 3} more",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.7f),
                            modifier = Modifier.padding(top = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun RecentTransactionWidget(
    transactions: List<Transaction>,
    categories: List<Category>,
    wallets: List<Wallet>,
    onClick: () -> Unit = {},
    @SuppressLint("ModifierParameter") modifier: Modifier = Modifier
) {
    val categoryMap = remember(categories) { categories.associateBy { it.id } }
    val walletMap = remember(wallets) { wallets.associateBy { it.id } }

    val recentTransactions = remember(transactions) {
        transactions.sortedByDescending {
            runCatching {
                SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(it.date)
            }.getOrNull() ?: Date(0)
        }.take(3)
    }

    Card(
        modifier = modifier
            .padding(horizontal = 8.dp)
            .padding(bottom = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.8f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Recent Transactions",
                    style = MaterialTheme.typography.bodyLarge,
                    modifier = Modifier.weight(1f)
                )
                IconButton(
                    onClick = onClick,
                    modifier = Modifier
                        .size(32.dp)
                        .zIndex(1f)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                        contentDescription = "View all transactions",
                        tint = MaterialTheme.colorScheme.secondary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                if (recentTransactions.isEmpty()) {
                    Text(
                        text = "No transactions available",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )
                } else {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        recentTransactions.forEach { txn ->
                            val category = categoryMap[txn.categoryId]
                            val wallet = walletMap[txn.walletId]
                            TransactionItem(transaction = txn, category = category, wallet = wallet)
                        }
                    }
                }
            }
        }
    }
}