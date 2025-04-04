package com.example.moneybase

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.*

@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun AddScreen() {
    // Date handling
    val context = LocalContext.current
    val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
    var date by remember { mutableStateOf(LocalDate.now().format(formatter)) }
    var showDatePicker by remember { mutableStateOf(false) }

    // Other state variables
    var note by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf<Category?>(null) }
    var isIncome by remember { mutableStateOf(false) }
    var rawAmount by remember { mutableStateOf("") }

    // Sample categories
    val categories = listOf(
        Category(1, "Food", Icons.Default.Fastfood, Color(0xFFFF9800)),
        Category(2, "Transport", Icons.Default.DirectionsCar, Color(0xFF2196F3)),
        Category(3, "Shopping", Icons.Default.ShoppingCart, Color(0xFFE91E63)),
        Category(4, "Bills", Icons.Default.Receipt, Color(0xFF9C27B0)),
        Category(5, "Entertainment", Icons.Default.Movie, Color(0xFF009688)),
        Category(6, "Health", Icons.Default.LocalHospital, Color(0xFFF44336))
    )

    // DatePicker Dialog
    if (showDatePicker) {
        val calendar = Calendar.getInstance()
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val day = calendar.get(Calendar.DAY_OF_MONTH)

        android.app.DatePickerDialog(
            context,
            { _, selectedYear, selectedMonth, selectedDay ->
                val selectedDate = LocalDate.of(selectedYear, selectedMonth + 1, selectedDay)
                date = selectedDate.format(formatter)
                showDatePicker = false
            },
            year,
            month,
            day
        ).show()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Surface(
            color = MaterialTheme.colorScheme.surfaceVariant,
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Row {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .background(
                            if (!isIncome) MaterialTheme.colorScheme.primary
                            else Color.Transparent,
                            RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                        )
                        .clickable { isIncome = false }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Expense",
                        color = if (!isIncome) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Box(
                    modifier = Modifier
                        .weight(1f)
                        .background(
                            if (isIncome) MaterialTheme.colorScheme.primary
                            else Color.Transparent,
                            RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp)
                        )
                        .clickable { isIncome = true }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Income",
                        color = if (isIncome) MaterialTheme.colorScheme.onPrimary
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Date input with clickable icon
        Text("Date", style = MaterialTheme.typography.labelLarge)
        OutlinedTextField(
            value = date,
            onValueChange = { date = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Select date") },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Default.DateRange,
                    contentDescription = "Date picker",
                    modifier = Modifier.clickable { showDatePicker = true }
                )
            },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            shape = RoundedCornerShape(12.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Note input
        Text("Note", style = MaterialTheme.typography.labelLarge)
        OutlinedTextField(
            value = note,
            onValueChange = { note = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Enter note") },
            shape = RoundedCornerShape(12.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Amount input
        Text("Amount", style = MaterialTheme.typography.labelLarge)
        OutlinedTextField(
            value = formatAmount(rawAmount),
            onValueChange = { newValue ->
                rawAmount = newValue.replace(Regex("[^\\d]"), "")
            },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Enter amount") },
            leadingIcon = {
                Icon(
                    Icons.Default.AttachMoney,
                    contentDescription = "Amount",
                    tint = if (isIncome) Color(0xFF4CAF50) else Color(0xFFF44336)
                )
            },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            shape = RoundedCornerShape(12.dp),
            prefix = {
                Text(if (isIncome) "+" else "-")
            }
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Category selection
        Text("Category", style = MaterialTheme.typography.labelLarge)
        Spacer(modifier = Modifier.height(8.dp))

        // Category grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(categories) { category ->
                CategoryItem(
                    category = category,
                    isSelected = selectedCategory?.id == category.id,
                    onSelect = { selectedCategory = category }
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Submit button
        Button(
            onClick = { /* Handle submit */ },
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            shape = RoundedCornerShape(12.dp)
        ) {
            Text("Submit", style = MaterialTheme.typography.labelLarge)
        }
    }
}

@Composable
fun CategoryItem(
    category: Category,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = if (isSelected) category.color else MaterialTheme.colorScheme.outline,
                shape = RoundedCornerShape(12.dp)
            )
            .clickable { onSelect() }
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = category.icon,
            contentDescription = category.name,
            tint = category.color,
            modifier = Modifier.size(32.dp)
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(category.name, style = MaterialTheme.typography.labelSmall)
    }
}

fun formatAmount(input: String): String {
    return try {
        val cleanString = input.replace(Regex("[^\\d]"), "")
        if (cleanString.isNotEmpty()) {
            val parsed = cleanString.toDouble() / 100
            "%,.2f".format(parsed)
        } else {
            ""
        }
    } catch (e: Exception) {
        ""
    }
}

data class Category(
    val id: Int,
    val name: String,
    val icon: ImageVector,
    val color: Color
)