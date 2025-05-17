package com.thebase.moneybase.screens.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import com.thebase.moneybase.utils.dialogs.EditTransaction
import java.text.SimpleDateFormat
import java.util.*

private val inputFormatter = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())
private val outputFormatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())

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
            .padding(vertical = 4.dp)
            .clickable { showDialog = true },
        elevation = CardDefaults.cardElevation(4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.background
        )
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val bgColor = category?.color
                ?.toColorInt()
                ?.let { Color(it) }
                ?: MaterialTheme.colorScheme.primary

            Box(
                modifier = Modifier
                    .size(40.dp)
                    .background(bgColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = getIcon(category?.iconName.orEmpty()),
                    contentDescription = null,
                    tint = Color.White
                )
            }

            Spacer(Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = listOfNotNull(category?.name, wallet?.name).joinToString(" • "),
                    style = MaterialTheme.typography.bodyMedium
                )

                val dateText = runCatching {
                    transaction.date
                        .let(inputFormatter::parse)
                        ?.let(outputFormatter::format)
                }.getOrNull() ?: "Invalid Date"

                Text(
                    text = dateText,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )

                Text(
                    text = transaction.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }

            val amount = kotlin.math.abs(transaction.amount)
            val sign = if (transaction.amount < 0) "-" else "+"
            val formatted = String.format(Locale.getDefault(), "%.2f", amount)
            val amountColor = if (transaction.amount < 0)
                Color(0xFFFF6666)
            else
                Color(0xFF66FF66)

            Text(
                text = "$sign${transaction.currencyCode} $formatted",
                style = MaterialTheme.typography.bodyLarge,
                color = amountColor
            )
        }
    }
}