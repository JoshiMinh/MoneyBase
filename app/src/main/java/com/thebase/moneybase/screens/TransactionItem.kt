package com.thebase.moneybase.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.core.graphics.toColorInt
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import com.thebase.moneybase.ui.Icon.getIcon
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

@Suppress("NULLABILITY_MISMATCH_BASED_ON_JAVA_ANNOTATIONS")
@Composable
fun TransactionItem(
    transaction: Transaction,
    category: Category?,
    wallet: Wallet?,
    onEditComplete: () -> Unit = {}
) {
    var showDialog by remember { mutableStateOf(false) }

    if (showDialog) {
        EditTransaction(
            transaction = transaction,
            userId = transaction.userId,
            onDismiss = { showDialog = false },
            onEditComplete = {
                showDialog = false
                onEditComplete()
            }
        )
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { showDialog = true }
            .padding(vertical = 4.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(
                        color = category
                            ?.let { Color(it.color.toColorInt()) }
                            ?: MaterialTheme.colorScheme.primary,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getIcon(category?.iconName ?: ""),
                    contentDescription = null,
                    tint = Color.White
                )
            }

            Spacer(Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    transaction.description,
                    style = MaterialTheme.typography.bodyMedium
                )

                Text(
                    listOfNotNull(category?.name, wallet?.name)
                        .joinToString(" • "),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )

                val dateText = try {
                    SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()).format(
                        SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(transaction.date)
                    )
                } catch (_: Exception) {
                    "Invalid Date"
                }
                Text(
                    dateText,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }

            val sign = if (transaction.amount < 0) "-" else "+"
            val formatted = "%.2f".format(abs(transaction.amount))
            val color = if (transaction.amount < 0)
                MaterialTheme.colorScheme.error
            else
                MaterialTheme.colorScheme.primary

            Text(
                text = "$sign${transaction.currencyCode} $formatted",
                color = color,
                style = MaterialTheme.typography.bodyLarge
            )
        }
    }
}