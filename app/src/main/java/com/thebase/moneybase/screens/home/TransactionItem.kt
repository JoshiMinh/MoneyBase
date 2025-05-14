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
        elevation = CardDefaults.cardElevation(4.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val bgColor = category?.color?.toColorInt()?.let { Color(it) }
                ?: MaterialTheme.colorScheme.onPrimary

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
                    text = transaction.description,
                    style = MaterialTheme.typography.bodyMedium
                )

                Text(
                    text = listOfNotNull(category?.name, wallet?.name).joinToString(" • "),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )

                val dateText = runCatching {
                    SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()).format(
                        SimpleDateFormat("MM/dd/yyyy", Locale.getDefault()).parse(transaction.date)!!
                    )
                }.getOrElse { "Invalid Date" }

                Text(
                    text = dateText,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }

            val amount = abs(transaction.amount)
            val sign = if (transaction.amount < 0) "-" else "+"
            val formattedAmount = String.format(Locale.getDefault(), "%.2f", amount)
            val amountColor = if (transaction.amount < 0)
                MaterialTheme.colorScheme.error
            else
                MaterialTheme.colorScheme.primary

            Text(
                text = "$sign${transaction.currencyCode} $formattedAmount",
                style = MaterialTheme.typography.bodyLarge,
                color = amountColor
            )
        }
    }
}