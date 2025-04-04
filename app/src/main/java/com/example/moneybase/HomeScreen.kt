package com.example.moneybase

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun HomeScreen() {
    // Sample data for demonstration
    val sampleTransactions = listOf(
        Transaction("Groceries", "2023-05-15", 45.67, false),
        Transaction("Salary", "2023-05-10", 1200.00, true),
        Transaction("Dinner", "2023-05-08", 32.50, false),
        Transaction("Gas", "2023-05-05", 40.00, false),
        Transaction("Freelance", "2023-05-01", 350.00, true)
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Chart/Stats Section (top - takes 40% of space)
        Box(
            modifier = Modifier
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

        Spacer(modifier = Modifier.height(16.dp))

        // Transaction History Section (bottom - takes 60% of space)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.6f)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .padding(16.dp)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                Text(
                    "Transaction History",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Sample transaction list
                sampleTransactions.forEach { transaction ->
                    TransactionItem(transaction)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
fun TransactionItem(transaction: Transaction) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(
                    text = transaction.description,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = transaction.date,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
            Text(
                text = "${if (transaction.isIncome) "+" else "-"}$${"%.2f".format(transaction.amount)}",
                color = if (transaction.isIncome) Color(0xFF4CAF50) else Color(0xFFF44336),
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}

// Add this data class to your project
data class Transaction(
    val description: String,
    val date: String,
    val amount: Double,
    val isIncome: Boolean
)