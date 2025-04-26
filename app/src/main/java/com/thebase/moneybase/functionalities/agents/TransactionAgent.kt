package com.thebase.moneybase.functionalities.agents

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.thebase.moneybase.firebase.*

@Composable
fun EditTransaction(
    transaction: Transaction,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Transaction") },
        text = {
            Column {
                Text("This is where you would edit the transaction.")
            }
        },
        confirmButton = {
            Button(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}