package com.thebase.moneybase.screens.settings

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Download
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
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
        if (uri != null) {
            // persist permission for later reuse
            val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            context.contentResolver.takePersistableUriPermission(uri, takeFlags)

            coroutineScope.launch {
                isExporting = true
                snackbarHostState.showSnackbar("Preparing to export data...")

                try {
                    val transactions = repo.getAllTransactions(userId)
                    val categories = repo.getAllCategories(userId)
                    val wallets = repo.getAllWallets(userId)

                    if (transactions.isEmpty()) {
                        snackbarHostState.showSnackbar("No transactions found to export")
                        return@launch
                    }

                    val fileUri = CSVExporter.exportTransactions(
                        context = context,
                        transactions = transactions,
                        categories = categories,
                        wallets = wallets,
                        uri = uri
                    )

                    if (fileUri != null) {
                        snackbarHostState.showSnackbar("Transactions exported successfully")
                    } else {
                        snackbarHostState.showSnackbar("Failed to export transactions, please try again")
                    }

                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Error: ${e.localizedMessage}")
                } finally {
                    isExporting = false
                }
            }
        }
    }

    OutlinedButton(
        onClick = { exportDirectoryPicker.launch(null) },
        modifier = modifier.fillMaxWidth(),
        enabled = !isExporting
    ) {
        if (isExporting) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                strokeWidth = 2.dp
            )
            Spacer(Modifier.width(8.dp))
            Text("Exporting...")
        } else {
            Icon(Icons.Default.Download, contentDescription = null)
            Spacer(Modifier.width(8.dp))
            Text("Export to CSV")
        }
    }
}