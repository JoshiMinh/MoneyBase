@file:Suppress("unused", "DEPRECATION")

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
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.navigation.NavController
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.pager.HorizontalPager
import com.thebase.moneybase.utils.components.HorizontalPagerIndicator
import androidx.compose.foundation.pager.rememberPagerState
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import com.thebase.moneybase.screens.home.TransactionItem
import com.thebase.moneybase.ui.toResolvedColor
import io.github.dautovicharis.charts.PieChart
import io.github.dautovicharis.charts.model.toChartDataSet
import io.github.dautovicharis.charts.style.PieChartDefaults
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max

@Composable
fun HomeScreen(userId: String, navController: NavController) {
    val repo = remember { FirebaseRepositories() }

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

    val transactions by repo.getTransactionsFlow(userId).collectAsState(initial = emptyList())
    val categories by repo.getCategoriesFlow(userId).collectAsState(initial = emptyList())
    val wallets by repo.getWalletsFlow(userId).collectAsState(initial = emptyList())
    var selectedMonth by rememberSaveable { mutableStateOf(Calendar.getInstance()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp)
    ) {
        GraphsCard(
            transactions = transactions,
            categories = categories,
            selectedMonth = selectedMonth,
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
            onClick = { navController.navigate("all_transaction") },
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun GraphsCard(
    transactions: List<Transaction>,
    categories: List<Category>,
    selectedMonth: Calendar,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val monthlyTransactions = remember(transactions, selectedMonth) {
        val start = Calendar.getInstance().apply {
            time = selectedMonth.time
            set(Calendar.DAY_OF_MONTH, 1)
        }
        val end = Calendar.getInstance().apply {
            time = selectedMonth.time
            set(Calendar.DAY_OF_MONTH, getActualMaximum(Calendar.DAY_OF_MONTH))
        }
        transactions.filter {
            val d = it.date.toDate()
            d >= start.time && d <= end.time
        }
    }

    val monthlyExpenses = remember(monthlyTransactions) {
        monthlyTransactions.filter { !it.isIncome }
    }

    val sortedCategories = remember(monthlyExpenses, categories) {
        val categoryMap = categories.associateBy { it.id }
        val amountByCat = mutableMapOf<String, Triple<String, Float, String>>()
        monthlyExpenses.forEach { expense ->
            categoryMap[expense.categoryId]?.let { cat ->
                val amt = abs(expense.amount).toFloat()
                val prev = amountByCat[cat.id]?.second ?: 0f
                amountByCat[cat.id] = Triple(cat.name, prev + amt, cat.color)
            }
        }
        amountByCat.values.sortedByDescending { it.second }
    }

    val pagerState = rememberPagerState(initialPage = 0) { 2 }

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
                .fillMaxSize()
                .padding(16.dp)
        ) {
            Text(
                text = SimpleDateFormat("MMM yyyy", Locale.getDefault()).format(selectedMonth.time),
                style = MaterialTheme.typography.bodyLarge
            )

            Spacer(modifier = Modifier.height(12.dp))

            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(1f)
            ) { page ->
                when (page) {
                    0 -> ExpensePieChart(monthlyExpenses, sortedCategories)
                    1 -> IncomeExpenseBarChart(monthlyTransactions)
                }
            }

            HorizontalPagerIndicator(
                pagerState = pagerState,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            )
        }
    }
}

@Composable
fun ExpensePieChart(
    expenses: List<Transaction>,
    sortedCategories: List<Triple<String, Float, String>>
) {
    if (expenses.isEmpty()) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "No expenses found for this month",
                style = MaterialTheme.typography.bodyMedium
            )
        }
    } else {
        Row(modifier = Modifier.fillMaxSize()) {
            val names = sortedCategories.map { it.first }
            val amounts = sortedCategories.map { it.second }
            val colors = sortedCategories.map {
                it.third.toResolvedColor() ?: MaterialTheme.colorScheme.primary
            }
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

            Spacer(modifier = Modifier.width(1.dp).background(Color.Gray))

            Box(
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
                verticalArrangement = Arrangement.Top
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

@Composable
fun IncomeExpenseBarChart(transactions: List<Transaction>) {
    if (transactions.isEmpty()) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "No transactions found for this month",
                style = MaterialTheme.typography.bodyMedium
            )
        }
    } else {
        val income = transactions.filter { it.isIncome }.sumOf { it.amount }.toFloat()
        val expense = transactions.filter { !it.isIncome }.sumOf { -it.amount }.toFloat()

        val minBarHeight = 20.dp

        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(150.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.Bottom
            ) {
                val barData = listOf(
                    Triple("Income", income, Color.Green),
                    Triple("Expenses", expense, Color.Red)
                )

                barData.forEach { (label, value, color) ->
                    val maxVal = max(income, expense).coerceAtLeast(1f)
                    val calculatedHeight = if (value > 0) (value / maxVal * 150) else 0f
                    val height = calculatedHeight.dp.coerceAtLeast(minBarHeight)

                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Bottom,
                        modifier = Modifier.weight(1f)
                    ) {
                        Box(
                            modifier = Modifier
                                .width(60.dp)
                                .height(height)
                                .background(color)
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(label, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(horizontalAlignment = Alignment.Start) {
                    Text("Income", style = MaterialTheme.typography.bodyMedium)
                    Text("$${income.toInt()}", style = MaterialTheme.typography.bodyLarge, color = Color.Green)
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text("Expenses", style = MaterialTheme.typography.bodyMedium)
                    Text("$${expense.toInt()}", style = MaterialTheme.typography.bodyLarge, color = Color.Red)
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
        transactions.sortedByDescending { it.date.toDate() }.take(3)
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
                contentAlignment = Alignment.TopStart
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