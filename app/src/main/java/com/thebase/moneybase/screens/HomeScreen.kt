@file:OptIn(ExperimentalMaterial3Api::class)

package com.thebase.moneybase.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Transaction
import com.thebase.moneybase.data.Wallet
import com.thebase.moneybase.data.Icon.getIcon
import com.thebase.moneybase.database.AppDatabase
import kotlinx.coroutines.launch

@Composable
fun HomeScreen(userId: String) {
    val context = LocalContext.current
    val db = AppDatabase.getInstance(context, userId)
    var transactions by remember { mutableStateOf(emptyList<Transaction>()) }
    var categories by remember { mutableStateOf(emptyList<Category>()) }
    var wallets by remember { mutableStateOf(emptyList<Wallet>()) }
    val scope = rememberCoroutineScope()

    // Load transactions, categories, wallets
    LaunchedEffect(userId) {
        transactions = db.transactionDao().getTop10Transactions(userId)
        categories = db.categoryDao().getCategoriesByUser(userId)
        wallets = db.walletDao().getWalletsByUser(userId)
    }


    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Chart/Analysis Section
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.4f),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    "Chart/Analysis Area",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Transaction History Section
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .weight(0.6f),
            color = MaterialTheme.colorScheme.surfaceVariant
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
            ) {
                Text(
                    "Transaction History",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                LazyColumn {
                    items(items = transactions) { transaction ->
                        TransactionItem(
                            transaction = transaction,
                            getCategory = { categoryId -> categories.find { it.id == categoryId } },
                            getWallet = { walletId -> wallets.find { it.id == walletId } }
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }
}

@Composable
fun TransactionItem(
    transaction: Transaction,
    getCategory: (String) -> Category?,
    getWallet: (String) -> Wallet?
) {
    val category = getCategory(transaction.categoryId)
    val wallet = getWallet(transaction.walletId)

    val amountColor = if (transaction.isIncome) Color(0xFF4CAF50) else Color(0xFFF44336)
    val amountSign = if (transaction.isIncome) "+" else "-"
    val absoluteAmount = kotlin.math.abs(transaction.amount)

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Icon with background color
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(Color(android.graphics.Color.parseColor(category?.color ?: "#6200EE"))),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getIcon(category?.iconName ?: "shopping_cart"),
                    contentDescription = category?.name ?: "",
                    tint = Color.White
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Texts
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = transaction.description,
                    style = MaterialTheme.typography.bodyLarge
                )
                Text(
                    text = "${category?.name ?: ""} • ${wallet?.name ?: ""}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
                Text(
                    text = transaction.date,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }

            // Amount
            Text(
                text = "$amountSign${transaction.currencyCode} ${"%.2f".format(absoluteAmount)}",
                color = amountColor,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}
