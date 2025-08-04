package com.thebase.moneybase.screens.home.charts

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
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.database.Transaction
import kotlin.math.abs
import kotlin.math.max

@Composable
fun IncomeExpenseBarChart(transactions: List<Transaction>) {
    val income  = transactions.filter { it.isIncome  }.sumOf { abs(it.amount.toDouble()) }.toFloat()
    val expense = transactions.filter { !it.isIncome }.sumOf { abs(it.amount.toDouble()) }.toFloat()
    val maxVal  = max(income, expense).coerceAtLeast(1f)
    val minBarH = 20.dp

    Column(
        Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .height(150.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment   = Alignment.Bottom
        ) {
            listOf(
                Triple("Income",  income,  Color(0xFF4CAF50)),
                Triple("Expense", expense, Color(0xFFF44336))
            ).forEach { (_, value, color) ->
                val heightDp = ((value / maxVal) * 150).dp.coerceAtLeast(minBarH)
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Bottom,
                    modifier = Modifier.weight(1f)
                ) {
                    Box(
                        Modifier
                            .width(60.dp)
                            .height(heightDp)
                            .background(color)
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = when {
                            value == income -> "Income"
                            else             -> "Expenses"
                        },
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text("Income", style = MaterialTheme.typography.bodyMedium)
                Text("$${income.toInt()}", style = MaterialTheme.typography.bodyLarge, color = Color(0xFF4CAF50))
            }
            Column {
                Text("Expenses", style = MaterialTheme.typography.bodyMedium)
                Text("$${expense.toInt()}", style = MaterialTheme.typography.bodyLarge, color = Color(0xFFF44336))
            }
        }
    }
}