package com.thebase.moneybase.screens

import android.app.DatePickerDialog
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items as lazyRowItems
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items as lazyGridItems
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.CurrencyBitcoin
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Fastfood
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Wallet
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Calendar
import androidx.core.graphics.toColorInt

val defaultCategories = listOf(
    Category("1", "Food", Icons.Default.Fastfood, "#FF9800"),
    Category("2", "Transport", Icons.Default.DirectionsCar, "#2196F3"),
    Category("3", "Shopping", Icons.Default.ShoppingCart, "#E91E63"),
    Category("4", "Bills", Icons.Default.Receipt, "#9C27B0"),
    Category("5", "Entertainment", Icons.Default.Movie, "#3F51B5"),
    Category("6", "Health", Icons.Default.LocalHospital, "#F44336")
)

val mockWallets = listOf(
    Wallet(
        id = "1",
        name = "Cash",
        type = Wallet.WalletType.PHYSICAL,
        currencyCode = "USD",
        balance = 100.0,
        icon = Icons.Default.AttachMoney,
        color = "#FF9800"
    ),
    Wallet(
        id = "2",
        name = "Bank",
        type = Wallet.WalletType.BANK_ACCOUNT,
        currencyCode = "USD",
        balance = 1500.0,
        icon = Icons.Default.AccountBalance,
        color = "#3F51B5"
    ),
    Wallet(
        id = "3",
        name = "Crypto",
        type = Wallet.WalletType.CRYPTO,
        currencyCode = "BTC",
        balance = 0.5,
        icon = Icons.Default.CurrencyBitcoin,
        color = "#4CAF50"
    )
)

@Composable
fun AddScreen(
    onBack: () -> Unit = {}
) {
    val context = LocalContext.current
    val formatter = DateTimeFormatter.ofPattern("MM/dd/yyyy")
    var date by remember { mutableStateOf(LocalDate.now().format(formatter)) }
    var showDatePicker by remember { mutableStateOf(false) }
    var note by remember { mutableStateOf("") }
    var rawAmount by remember { mutableStateOf("") }
    var selectedCategoryId by remember { mutableStateOf<String?>(null) }
    var selectedWalletId by remember { mutableStateOf<String?>(null) }
    var isIncome by remember { mutableStateOf(false) }

    if (showDatePicker) {
        val calendar = Calendar.getInstance()
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        DatePickerDialog(
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
                            if (!isIncome) MaterialTheme.colorScheme.primary else Color.Transparent,
                            RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                        )
                        .clickable { isIncome = false }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Expense",
                        color = if (!isIncome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .background(
                            if (isIncome) MaterialTheme.colorScheme.primary else Color.Transparent,
                            RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp)
                        )
                        .clickable { isIncome = true }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "Income",
                        color = if (isIncome) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
        Spacer(modifier = Modifier.height(24.dp))
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
        Text("Note", style = MaterialTheme.typography.labelLarge)
        OutlinedTextField(
            value = note,
            onValueChange = { note = it },
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Enter note") },
            shape = RoundedCornerShape(12.dp)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text("Amount", style = MaterialTheme.typography.labelLarge)
        OutlinedTextField(
            value = formatAmount(rawAmount),
            onValueChange = { newValue ->
                rawAmount = newValue.replace(Regex("\\D"), "")
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
            prefix = { Text(if (isIncome) "+" else "-") }
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text("Category", style = MaterialTheme.typography.labelLarge)
        Spacer(modifier = Modifier.height(8.dp))
        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            lazyGridItems(defaultCategories) { category ->
                CategoryItem(
                    category = category,
                    isSelected = selectedCategoryId == category.id,
                    onSelect = { selectedCategoryId = category.id }
                )
            }
        }
        Spacer(modifier = Modifier.height(24.dp))
        Text("Wallet", style = MaterialTheme.typography.labelLarge)
        Spacer(modifier = Modifier.height(8.dp))
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            lazyRowItems(mockWallets) { wallet ->
                Box(modifier = Modifier.width(120.dp)) {
                    WalletItem(
                        wallet = wallet,
                        isSelected = selectedWalletId == wallet.id,
                        onSelect = { selectedWalletId = wallet.id }
                    )
                }
            }
        }
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = {},
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
fun WalletItem(wallet: Wallet, isSelected: Boolean, onSelect: () -> Unit) {
    val borderColor = if (isSelected) Color(wallet.color.toColorInt()) else MaterialTheme.colorScheme.outline
    val iconColor = Color(wallet.color.toColorInt())
    val modifier = Modifier
        .border(
            width = if (isSelected) 2.dp else 1.dp,
            color = borderColor,
            shape = RoundedCornerShape(12.dp)
        )
        .clip(RoundedCornerShape(12.dp))
        .clickable { onSelect() }
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = Color.Transparent),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .padding(12.dp)
                .fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = wallet.icon,
                contentDescription = wallet.name,
                tint = iconColor,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(wallet.name, style = MaterialTheme.typography.bodyLarge)
            Text(
                "${wallet.currencyCode} ${"%.2f".format(wallet.balance)}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun CategoryItem(
    category: Category,
    isSelected: Boolean,
    onSelect: () -> Unit
) {
    val borderColor = if (isSelected) Color(category.color.toColorInt()) else MaterialTheme.colorScheme.outline
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(12.dp)
            )
            .clickable { onSelect() }
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = category.icon,
            contentDescription = category.name,
            tint = Color(category.color.toColorInt()),
            modifier = Modifier.size(32.dp)
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(category.name, style = MaterialTheme.typography.labelSmall)
    }
}

fun formatAmount(input: String): String {
    return try {
        val cleanString = input.replace(Regex("\\D"), "")
        if (cleanString.isNotEmpty()) {
            val parsed = cleanString.toDouble() / 100
            "%,.2f".format(parsed)
        } else ""
    } catch (e: Exception) {
        ""
    }
}