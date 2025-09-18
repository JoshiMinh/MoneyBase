package com.thebase.moneybase.screens.home.charts

import android.annotation.SuppressLint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.database.Transaction
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.math.max

@SuppressLint("ConstantLocale")
private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

@Composable
fun LineChart(
    transactions: List<Transaction>,
    startDate: Date,
    endDate: Date,
    modifier: Modifier = Modifier,
    chartHeight: Dp = 200.dp,
    lineColor: Color = MaterialTheme.colorScheme.primary,
    padding: Dp = 16.dp
) {
    // Aggregate daily totals
    val dailyTotals = mutableMapOf<String, Float>()
    for (tx in transactions) {
        val txDate = tx.date.toDate()
        if (!txDate.before(startDate) && !txDate.after(endDate)) {
            val key = dateFormat.format(txDate)
            val value = if (tx.isIncome) tx.amount.toFloat() else -tx.amount.toFloat()
            dailyTotals[key] = dailyTotals.getOrDefault(key, 0f) + value
        }
    }

    // Generate full range of dates from start to end
    val calendar = Calendar.getInstance().apply { time = startDate }
    val dateKeys = mutableListOf<String>()
    while (!calendar.time.after(endDate)) {
        dateKeys.add(dateFormat.format(calendar.time))
        calendar.add(Calendar.DAY_OF_YEAR, 1)
    }

    // Build values with zero-fill
    val values = dateKeys.map { dailyTotals[it] ?: 0f }
    val maxAbsValue = max(1f, values.maxOfOrNull { abs(it) } ?: 1f)

    // Draw the chart
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(chartHeight)
            .padding(padding)
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val canvasWidth = size.width
            val canvasHeight = size.height
            val pointCount = values.size
            val xStep = if (pointCount > 1) canvasWidth / (pointCount - 1) else canvasWidth

            val midY = canvasHeight / 2f

            // Zero-line
            drawLine(
                color = Color.LightGray,
                start = Offset(0f, midY),
                end = Offset(canvasWidth, midY),
                strokeWidth = 1.dp.toPx()
            )

            // Line chart path
            val path = Path()
            values.forEachIndexed { index, value ->
                val x = index * xStep
                val y = midY - (value / maxAbsValue) * (canvasHeight / 2f)
                if (index == 0) {
                    path.moveTo(x, y)
                } else {
                    path.lineTo(x, y)
                }
            }

            drawPath(
                path = path,
                color = lineColor,
                style = Stroke(
                    width = 3.dp.toPx(),
                    cap = StrokeCap.Round
                )
            )
        }
    }
}