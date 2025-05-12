package com.thebase.moneybase.screens.home

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.Wallet
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AllTransactionScreen(
    userId: String,
    navController: NavController?
) {
    val repo = remember { FirebaseRepositories() }
    var transactions by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var categories by remember { mutableStateOf<Map<String, Category>>(emptyMap()) }
    var wallets by remember { mutableStateOf<Map<String, Wallet>>(emptyMap()) }
    var isLoading by remember { mutableStateOf(true) }
    var selectedPeriod by remember { mutableStateOf(7) } // Default to 7 days

    LaunchedEffect(userId) {
        isLoading = true
        try {
            transactions = repo.getAllTransactions(userId)
            categories = repo.getAllCategories(userId).associateBy { it.id }
            wallets = repo.getAllWallets(userId).associateBy { it.id }
        } catch (e: Exception) {
            transactions = emptyList()
        }
        isLoading = false
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("All Transactions") },
                navigationIcon = {
                    IconButton(onClick = { navController?.popBackStack() }) {
                        Icon(imageVector = Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Black,
                    titleContentColor = Color.White
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 8.dp)
        ) {
            // Time period selector
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1C1C1C))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    listOf(7, 30, 60).forEach { days ->
                        FilterChip(
                            selected = selectedPeriod == days,
                            onClick = { selectedPeriod = days },
                            label = { Text("$days Days") }
                        )
                    }
                }
            }

            // Transaction list
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1C1C1C))
            ) {
                if (isLoading) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = Color.White)
                    }
                } else {
                    val filteredTransactions = remember(transactions, selectedPeriod) {
                        val calendar = Calendar.getInstance()
                        val endDate = calendar.time
                        calendar.add(Calendar.DAY_OF_YEAR, -selectedPeriod)
                        val startDate = calendar.time
                        val dateFormat = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())

                        transactions.filter { transaction ->
                            try {
                                val transactionDate = dateFormat.parse(transaction.date)
                                transactionDate != null && !transactionDate.before(startDate) && !transactionDate.after(endDate)
                            } catch (e: Exception) {
                                false
                            }
                        }.sortedByDescending { transaction ->
                            try {
                                SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(transaction.date)?.time ?: 0L
                            } catch (e: Exception) {
                                0L
                            }
                        }
                    }

                    if (filteredTransactions.isEmpty()) {
                        Box(
                            modifier = Modifier.fillMaxSize(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "No transactions found for the selected period",
                                color = Color.White.copy(alpha = 0.7f),
                                textAlign = TextAlign.Center
                            )
                        }
                    } else {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                            ) {
                            items(filteredTransactions) { transaction ->
                                TransactionItem(
                                    transaction = transaction,
                                    category = categories[transaction.categoryId],
                                    wallet = wallets[transaction.walletId]
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}