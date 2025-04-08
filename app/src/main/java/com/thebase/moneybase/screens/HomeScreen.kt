package com.thebase.moneybase.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.data.Transaction

@Composable
fun HomeScreen() {
    var transactions by remember { mutableStateOf(emptyList<Transaction>()) }

    LaunchedEffect(Unit) {
        transactions = listOf(
            Transaction(description = "Grocery", date = "2025-04-01", amount = 45.99),
            Transaction(description = "Salary", date = "2025-04-01", amount = 2500.00, isIncome = true),
        )
    }

    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Box(
            Modifier
                .fillMaxWidth()
                .weight(0.4f)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                "Chart/Analysis Area",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(Modifier.height(16.dp))

        Box(
            Modifier
                .fillMaxWidth()
                .weight(0.6f)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .padding(16.dp)
        ) {
            Column(Modifier.fillMaxSize()) {
                Text(
                    "Transaction History",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(8.dp))
                transactions.forEach {
                    TransactionItem(it)
                    Spacer(Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
fun TransactionItem(transaction: Transaction) {
    Card(
        Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(transaction.description, style = MaterialTheme.typography.bodyLarge)
                Text(
                    transaction.date,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            Text(
                text = "${if (transaction.isIncome) "+" else "-"}${transaction.currencyCode} ${"%.2f".format(transaction.amount)}",
                color = if (transaction.isIncome) Color(0xFF4CAF50) else Color(0xFFF44336),
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}