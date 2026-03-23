package com.thebase.moneybase.screens.settings

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Download
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.utils.CSVExporter
import kotlinx.coroutines.launch

@Composable
fun ExportDataButton(
    userId: String,
    repo: FirebaseRepositories,
    snackbarHostState: SnackbarHostState,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()
    var isExporting by remember { mutableStateOf(false) }

    val exportDirectoryPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocumentTree()
    ) { uri: Uri? ->
        coroutineScope.launch {
            if (uri == null) {
                snackbarHostState.showSnackbar(
                    message = "No directory selected",
                    duration = SnackbarDuration.Short
                )
                return@launch
            }

            context.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )

            isExporting = true
            snackbarHostState.showSnackbar(
                message = "Exporting transactions...",
                duration = SnackbarDuration.Short
            )

            try {
                val transactions = repo.getAllTransactions(userId)
                val categories = repo.getAllCategories(userId)
                val wallets = repo.getAllWallets(userId)

                if (transactions.isEmpty()) {
                    snackbarHostState.showSnackbar(
                        message = "No transactions to export",
                        duration = SnackbarDuration.Short
                    )
                    return@launch
                }

                val fileUri = CSVExporter.exportTransactions(
                    context = context,
                    transactions = transactions,
                    categories = categories,
                    wallets = wallets,
                    uri = uri
                )

                snackbarHostState.showSnackbar(
                    message = if (fileUri != null) "Transactions exported successfully"
                    else "Failed to export transactions",
                    duration = SnackbarDuration.Short
                )
            } catch (e: Exception) {
                snackbarHostState.showSnackbar(
                    message = "Export failed: ${e.localizedMessage}",
                    duration = SnackbarDuration.Long
                )
            } finally {
                isExporting = false
            }
        }
    }

    OutlinedButton(
        onClick = { exportDirectoryPicker.launch(null) },
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        enabled = !isExporting
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (isExporting) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "Exporting...",
                    style = MaterialTheme.typography.labelLarge,
                    modifier = Modifier.padding(start = 12.dp),
                    textAlign = TextAlign.Center
                )
            } else {
                Icon(
                    imageVector = Icons.Default.Download,
                    contentDescription = "Export to CSV",
                    modifier = Modifier.size(24.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = "Export Transactions to CSV",
                    style = MaterialTheme.typography.labelLarge,
                    modifier = Modifier.padding(start = 12.dp),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}