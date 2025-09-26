package com.thebase.moneybase.screens.home.charts

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.ui.toResolvedColor
import io.github.dautovicharis.charts.PieChart
import io.github.dautovicharis.charts.model.toChartDataSet
import io.github.dautovicharis.charts.style.PieChartDefaults

@Composable
fun ExpensePieChart(
    expenses: List<Transaction>,
    sortedCategories: List<Triple<String, Float, String>>,
    showAllLegends: Boolean = false // Optional param for full legend
) {
    if (expenses.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("No expenses found", style = MaterialTheme.typography.bodyMedium)
        }
        return
    }

    val names = sortedCategories.map { it.first }
    val amounts = sortedCategories.map { it.second }
    val colors = sortedCategories.map {
        it.third.toResolvedColor() ?: MaterialTheme.colorScheme.primary
    }
    val total = amounts.sum().takeIf { it > 0f } ?: 1f

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

    Row(Modifier.fillMaxSize()) {
        Box(
            Modifier
                .width(200.dp)
                .fillMaxHeight(),
            contentAlignment = Alignment.Center
        ) {
            PieChart(dataSet = dataSet, style = style)
        }

        Spacer(
            Modifier
                .width(1.dp)
                .fillMaxHeight()
                .background(Color.White.copy(alpha = 0.3f))
        )

        Column(
            Modifier
                .weight(1f)
                .fillMaxHeight()
                .padding(start = 8.dp),
            verticalArrangement = Arrangement.Top
        ) {
            val visibleCategories = if (showAllLegends) sortedCategories else sortedCategories.take(3)

            visibleCategories.forEachIndexed { index, (label, value, _) ->
                val percent = ((value / total) * 100).toInt()
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        Modifier
                            .size(12.dp)
                            .background(colors[index], shape = CircleShape)
                    )
                    Spacer(Modifier.width(4.dp))
                    Text(
                        "$label - $${"%.2f".format(value)} ($percent%)",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }

            if (!showAllLegends && sortedCategories.size > 3) {
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