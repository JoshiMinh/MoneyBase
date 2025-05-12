package com.thebase.moneybase.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import androidx.navigation.NavController
import com.thebase.moneybase.database.*
import io.github.dautovicharis.charts.PieChart
import io.github.dautovicharis.charts.model.toChartDataSet
import io.github.dautovicharis.charts.style.PieChartDefaults
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

enum class ReportPeriod { MONTH, QUARTER, YEAR }
enum class ReportType { EXPENSE, INCOME }

@Composable
fun ReportScreen(userId: String, navController: NavController? = null) {
    val repo = remember { FirebaseRepositories() }
    var selectedPeriod by remember { mutableStateOf(ReportPeriod.MONTH) }
    var selectedDate by remember { mutableStateOf(Date()) }
    var selectedReportType by remember { mutableStateOf(ReportType.EXPENSE) }
    val categories by repo.getCategoriesFlow(userId).collectAsState(initial = emptyList())

    Column(Modifier.fillMaxSize().padding(8.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            ReportPeriod.values().forEach { period ->
                FilterChip(
                    selected = selectedPeriod == period,
                    onClick = { selectedPeriod = period },
                    label = { Text(period.name.lowercase().replaceFirstChar { it.titlecase() }) }
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        ReportTypeToggle(selectedReportType) { selectedReportType = it }

        Spacer(Modifier.height(16.dp))

        DateSelector(selectedDate, { selectedDate = it }, selectedPeriod)

        Spacer(Modifier.height(16.dp))

        ReportPieChartWidget(
            userId = userId,
            selectedPeriod = selectedPeriod,
            selectedType = selectedReportType,
            selectedDate = selectedDate,
            categories = categories
        )
    }
}

@Composable
fun DateSelector(selectedDate: Date, onDateSelected: (Date) -> Unit, period: ReportPeriod) {
    val calendar = Calendar.getInstance()
    calendar.time = selectedDate

    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = {
            calendar.add(
                when (period) {
                    ReportPeriod.MONTH -> Calendar.MONTH
                    ReportPeriod.QUARTER -> Calendar.MONTH
                    ReportPeriod.YEAR -> Calendar.YEAR
                },
                if (period == ReportPeriod.QUARTER) -3 else -1
            )
            onDateSelected(calendar.time)
        }) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous")
        }

        Text(
            when (period) {
                ReportPeriod.MONTH -> SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(selectedDate)
                ReportPeriod.QUARTER -> "Q${(calendar.get(Calendar.MONTH) / 3) + 1} ${calendar.get(Calendar.YEAR)}"
                ReportPeriod.YEAR -> calendar.get(Calendar.YEAR).toString()
            }
        )

        IconButton(onClick = {
            calendar.add(
                when (period) {
                    ReportPeriod.MONTH -> Calendar.MONTH
                    ReportPeriod.QUARTER -> Calendar.MONTH
                    ReportPeriod.YEAR -> Calendar.YEAR
                },
                if (period == ReportPeriod.QUARTER) 3 else 1
            )
            onDateSelected(calendar.time)
        }) {
            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next")
        }
    }
}

@Composable
fun ReportPieChartWidget(
    userId: String,
    selectedPeriod: ReportPeriod,
    selectedType: ReportType,
    selectedDate: Date,
    categories: List<Category>,
) {
    val repo = FirebaseRepositories()
    val transactions by repo.getTransactionsFlow(userId).collectAsState(initial = emptyList())
    var typeFilteredTransaction by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var allFilteredTransaction by remember { mutableStateOf<List<Transaction>>(emptyList()) }

    // Filter type
    typeFilteredTransaction = if (selectedType == ReportType.INCOME) {
        transactions.filter { it.isIncome == true }
    } else {
        transactions.filter { it.isIncome == false }
    }

    // Filter period
    val startCalendar = Calendar.getInstance()
    val endCalendar = Calendar.getInstance()
    startCalendar.time = selectedDate
    endCalendar.time = selectedDate

    when (selectedPeriod) {
        ReportPeriod.MONTH -> {
            startCalendar.set(Calendar.DAY_OF_MONTH, 1)
            endCalendar.set(Calendar.DAY_OF_MONTH, endCalendar.getActualMaximum(Calendar.DAY_OF_MONTH))
        }
        ReportPeriod.QUARTER -> {
            val currentMonth = startCalendar.get(Calendar.MONTH)
            val quarterStartMonth = currentMonth / 3 * 3
            startCalendar.set(Calendar.MONTH, quarterStartMonth)
            startCalendar.set(Calendar.DAY_OF_MONTH, 1)
            endCalendar.set(Calendar.MONTH, quarterStartMonth + 2)
            endCalendar.set(Calendar.DAY_OF_MONTH, endCalendar.getActualMaximum(Calendar.DAY_OF_MONTH))
        }
        ReportPeriod.YEAR -> {
            startCalendar.set(Calendar.MONTH, Calendar.JANUARY)
            startCalendar.set(Calendar.DAY_OF_MONTH, 1)
            endCalendar.set(Calendar.MONTH, Calendar.DECEMBER)
            endCalendar.set(Calendar.DAY_OF_MONTH, 31)
        }
    }

    val startPeriod = startCalendar.time
    val endPeriod = endCalendar.time

    allFilteredTransaction = typeFilteredTransaction.filter { eachTransaction ->
        val txDate = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(eachTransaction.date)
        txDate != null && !txDate.before(startPeriod) && !txDate.after(endPeriod)
    }



    // Calculate category totals
    val categoryTotals = categories.map { category ->
        val total = allFilteredTransaction
            .filter { it.categoryId == category.id }
            .sumOf { abs(it.amount) }
        Triple(category.name, total, category.color)
    }.filter { it.second > 0 }

    // Sau khi tính allFilteredTransaction
    if (allFilteredTransaction.isEmpty()) {
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            Text(
                text = "No transactions found for this period",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White
            )
        }
        return
    }

    if (categoryTotals.size < 2) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.5f),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "At least 2 categories are required to display the chart.",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White
            )
        }
        return
    }


    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        // PIE CHART
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.7f)
        ) {
            val names = categoryTotals.map { it.first }
            val amounts = categoryTotals.map { it.second }
            val colors = categoryTotals.map { Color(it.third.toColorInt()) }

            val dataSet = amounts.toChartDataSet(
                title = "${selectedPeriod.name.lowercase().replaceFirstChar { it.uppercase() }} " +
                        "${selectedType.name.lowercase().replaceFirstChar { it.uppercase() }}",
                postfix = "$",
                labels = names
            )

            val style = PieChartDefaults.style(
                borderColor = Color.White,
                donutPercentage = 40f,
                borderWidth = 6f,
                pieColors = colors
            )

            PieChart(dataSet = dataSet, style = style)
        }

        Spacer(Modifier.height(8.dp))

        // CATEGORY LIST
        Column(
            modifier = Modifier.fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val totalAmount = categoryTotals.sumOf { it.second.toDouble() }.toFloat()

            categoryTotals.forEach {
                val percentage = (it.second / totalAmount * 100).toInt()
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .background(Color(it.third.toColorInt()), CircleShape)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = it.first,
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White,
                        modifier = Modifier.weight(1f)
                    )
                    Text(
                        text = "$${it.second.toInt()}",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "$percentage%",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}

@Composable
fun ReportTypeToggle(selectedType: ReportType, onTypeSelected: (ReportType) -> Unit) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row {
            listOf(ReportType.EXPENSE to "Expense", ReportType.INCOME to "Income").forEach { (type, label) ->
                Box(
                    Modifier.weight(1f)
                        .background(
                            if (selectedType == type) MaterialTheme.colorScheme.primary else Color.Transparent,
                            if (type == ReportType.EXPENSE)
                                RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                            else RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp)
                        )
                        .clickable { onTypeSelected(type) }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        label,
                        color = if (selectedType == type) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
    Spacer(Modifier.height(24.dp))
}