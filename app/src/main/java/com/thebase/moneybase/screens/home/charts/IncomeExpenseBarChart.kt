@file:Suppress("unused")
package com.thebase.moneybase.screens.home.charts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.database.Transaction
import kotlin.math.abs
import kotlin.math.max

@Composable
fun IncomeExpenseBarChart(transactions: List<Transaction>) {
    val income = transactions.filter { it.isIncome }
        .sumOf { abs(it.amount.toDouble()) }
        .toFloat()

    val expense = transactions.filter { !it.isIncome }
        .sumOf { abs(it.amount.toDouble()) }
        .toFloat()

    val maxValue = max(income, expense).coerceAtLeast(1f)
    val barMaxHeight = 150.dp
    val barMinHeight = 20.dp

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Bars
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(barMaxHeight),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.Bottom
        ) {
            BarWithLabel(
                label = "Income",
                value = income,
                maxValue = maxValue,
                color = Color(0xFF4CAF50),
                maxHeight = barMaxHeight,
                minHeight = barMinHeight
            )
            BarWithLabel(
                label = "Expenses",
                value = expense,
                maxValue = maxValue,
                color = Color(0xFFF44336),
                maxHeight = barMaxHeight,
                minHeight = barMinHeight
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Totals
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            TotalText("Income", income, Color(0xFF4CAF50))
            TotalText("Expenses", expense, Color(0xFFF44336))
        }
    }
}

@Composable
private fun BarWithLabel(
    label: String,
    value: Float,
    maxValue: Float,
    color: Color,
    maxHeight: Dp,
    minHeight: Dp
) {
    val heightDp = ((value / maxValue) * maxHeight.value).dp.coerceAtLeast(minHeight)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Bottom
    ) {
        Box(
            modifier = Modifier
                .width(40.dp)
                .height(heightDp)
                .background(color)
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

@Composable
private fun TotalText(label: String, value: Float, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
        Text(
            text = "$${"%.2f".format(value)}", // Updated to show cents
            style = MaterialTheme.typography.bodyLarge,
            color = color
        )
    }
}