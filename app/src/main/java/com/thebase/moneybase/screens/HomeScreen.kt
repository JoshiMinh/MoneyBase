@file:Suppress("unused")

package com.thebase.moneybase.screens

import android.annotation.SuppressLint
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.InsertChart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import io.github.dautovicharis.charts.PieChart
import io.github.dautovicharis.charts.model.toChartDataSet
import io.github.dautovicharis.charts.style.PieChartDefaults
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs
import androidx.navigation.NavController
import com.thebase.moneybase.screens.home.TransactionItem

@Composable
fun HomeScreen(userId: String, navController: NavController) {
    val repo = remember { FirebaseRepositories() }

    val transactions by repo.getTransactionsFlow(userId).collectAsState(initial = emptyList())
    val categories by repo.getCategoriesFlow(userId).collectAsState(initial = emptyList())
    val wallets by repo.getWalletsFlow(userId).collectAsState(initial = emptyList())

    Column(modifier = Modifier.fillMaxSize().fillMaxHeight()) {
        AddCustomPieChart(
            transactions = transactions,
            categories = categories,
            onClick = { navController.navigate("report") },
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.49f)
        )

        Spacer(modifier = Modifier.height(8.dp))

        RecentTransactionWidget(
            transactions = transactions,
            categories = categories,
            wallets = wallets,
            onClick = { navController.navigate("history")},
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.49f)
        )
    }
}

@Composable
fun AddCustomPieChart(
    transactions: List<Transaction>,
    categories: List<Category>,
    onClick: () -> Unit,
    modifier: Modifier
) {
    val calendar = remember { Calendar.getInstance() }
    val currentMonth = calendar.get(Calendar.MONTH)
    val currentYear = calendar.get(Calendar.YEAR)

    val (currentMonthExpense, sortedCategories) = remember(transactions to categories) {
        val expenses = transactions.filter { it.isIncome == false && it.amount < 0 }
        val filtered = expenses.filter {
            try {
                val date = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(it.date)
                val cal = Calendar.getInstance().apply {
                    if (date != null) {
                        time = date
                    }
                }
                cal.get(Calendar.MONTH) == currentMonth && cal.get(Calendar.YEAR) == currentYear
            } catch (e: Exception) {
                false
            }
        }

        val categoryLookUpMap = categories.associateBy { it.id }
        val categoryAmountMap = mutableMapOf<String, Triple<String, Float, String>>()

        filtered.forEach { expense ->
            val categoryId = expense.categoryId
            val category = categoryLookUpMap[categoryId]

            if (category != null) {
                val amount = abs(expense.amount).toFloat()
                val currentAmount = categoryAmountMap[categoryId]?.second ?: 0f
                categoryAmountMap[categoryId] = Triple(
                    category.name,
                    currentAmount + amount,
                    category.color
                )
            }
        }

        filtered to categoryAmountMap.values.sortedByDescending { it.second }
    }

    if (currentMonthExpense.isEmpty()) {
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            Text(
                text = "No expenses found for this month",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White
            )
        }
        return
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .fillMaxHeight(0.5f)
            .padding(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Expense Report",
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            if (sortedCategories.size < 2) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .fillMaxHeight(0.5f),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "At least 2 categories are required to display the chart.",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
                return@Column
            }

            val categoryNames = sortedCategories.map { it.first }
            val categoryAmounts = sortedCategories.map { it.second }
            val categoryColors = sortedCategories.map { Color(it.third.toColorInt()) }

            val totalAmount = categoryAmounts.sum()
            val monthFormatter = SimpleDateFormat("MMM yyyy", Locale.getDefault())
            val title = monthFormatter.format(Date())

            val dataSet = categoryAmounts.toChartDataSet(
                title = title,
                postfix = "$",
                labels = categoryNames
            )

            val style = PieChartDefaults.style(
                borderColor = Color.White,
                donutPercentage = 40f,
                borderWidth = 6f,
                pieColors = categoryColors
            )

            Box(modifier = Modifier.fillMaxWidth()) {
                IconButton(
                    onClick = onClick,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(4.dp)
                        .size(32.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primary,
                            shape = CircleShape
                        )
                        .zIndex(1f)
                ) {
                    Icon(
                        imageVector = Icons.Default.InsertChart,
                        contentDescription = "View detailed Report",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(modifier = Modifier.weight(0.6f)) {
                        PieChart(
                            dataSet = dataSet,
                            style = style
                        )
                    }

                    Column(
                        modifier = Modifier
                            .weight(0.4f)
                            .padding(start = 8.dp)
                    ) {
                        sortedCategories.take(3).forEachIndexed { index, eachCategory ->
                            val percentage = (eachCategory.second / totalAmount * 100).toInt()
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(12.dp)
                                        .background(categoryColors[index], CircleShape)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Column {
                                    Text(
                                        text = eachCategory.first,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.White
                                    )
                                    Row(
                                        modifier = Modifier.fillMaxWidth(),
                                        horizontalArrangement = Arrangement.SpaceBetween
                                    ) {
                                        Text(
                                            text = "$${eachCategory.second.toInt()}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                        Text(
                                            text = "$percentage%",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = Color.White.copy(alpha = 0.7f)
                                        )
                                    }
                                }
                            }
                        }

                        if (sortedCategories.size > 3) {
                            Text(
                                text = "+${sortedCategories.size - 3} more",
                                style = MaterialTheme.typography.bodySmall,
                                color = Color.White.copy(alpha = 0.7f),
                                modifier = Modifier.padding(start = 16.dp, top = 4.dp)
                            )
                        }
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
            try {
                SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(it.date)
            } catch (e: Exception) {
                Date(0)
            }
        }.take(3)
    }

    Card(
        modifier = modifier
            .padding(horizontal = 8.dp)
            .padding(bottom = 4.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary)
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
                modifier = Modifier
                    .fillMaxSize(),
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