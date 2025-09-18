package com.thebase.moneybase.utils

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStreamWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs

class CSVExporter {
    companion object {
        private const val TAG = "CSVExporter"

        /**
         * Export a list of transactions to a CSV file.
         * @param context App context
         * @param transactions Transactions to export
         * @param categories List of categories for name lookup
         * @param wallets List of wallets for name lookup
         * @param uri Optional target folder URI (if using SAF); defaults to Downloads
         * @return Uri of the created file, or null on failure
         */
        suspend fun exportTransactions(
            context: Context,
            transactions: List<Transaction>,
            categories: List<Category>,
            wallets: List<Wallet>,
            uri: Uri? = null
        ): Uri? = withContext(Dispatchers.IO) {
            try {
                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                val fileName = "moneybase_transactions_$timestamp.csv"

                val header = "ID,Date,Description,Amount,Currency,Wallet,Category,Type\n"
                val dateFormatter = SimpleDateFormat("MM/dd/yyyy", Locale.getDefault())
                val content = buildString {
                    append(header)
                    transactions.forEach { transaction ->
                        val categoryName = categories.find { it.id == transaction.categoryId }?.name.orEmpty()
                        val walletName = wallets.find { it.id == transaction.walletId }?.name.orEmpty()
                        val type = if (transaction.isIncome) "Income" else "Expense"
                        val formattedAmount = "%.2f".format(Locale.getDefault(), abs(transaction.amount))

                        appendLine(
                            listOf(
                                transaction.id,
                                dateFormatter.format(transaction.date.toDate()),
                                transaction.description.replace("\"", "\"\""),
                                formattedAmount,
                                transaction.currencyCode,
                                walletName.replace("\"", "\"\""),
                                categoryName.replace("\"", "\"\""),
                                type
                            ).joinToString(separator = ",") { "\"$it\"" }
                        )
                    }
                }

                return@withContext uri?.let {
                    writeToUri(context, it, content, fileName)
                } ?: writeToDownloads(context, content, fileName)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to export: ${e.message}", e)
                null
            }
        }

        private fun writeToUri(
            context: Context,
            uri: Uri,
            content: String,
            fileName: String
        ): Uri? {
            return try {
                val document = DocumentFile.fromTreeUri(context, uri)
                    ?.createFile("text/csv", fileName)
                    ?.uri

                if (document != null) {
                    context.contentResolver.openOutputStream(document)?.use { out ->
                        OutputStreamWriter(out).use { it.write(content) }
                    }
                    document
                } else {
                    Log.e(TAG, "Failed to create file in selected folder.")
                    null
                }
            } catch (e: IOException) {
                Log.e(TAG, "Write error: ${e.message}", e)
                null
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "Invalid URI, fallback to Downloads: ${e.message}", e)
                writeToDownloads(context, content, fileName)
            }
        }

        private fun writeToDownloads(
            context: Context,
            content: String,
            fileName: String
        ): Uri? {
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, "text/csv")
                        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    }

                    val resolver = context.contentResolver
                    val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)

                    uri?.let {
                        resolver.openOutputStream(it)?.use { out ->
                            OutputStreamWriter(out).use { it.write(content) }
                        }
                    }
                    uri
                } else {
                    val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    if (!dir.exists()) dir.mkdirs()
                    val file = File(dir, fileName)

                    FileOutputStream(file).use { out ->
                        OutputStreamWriter(out).use { it.write(content) }
                    }

                    Uri.fromFile(file)
                }
            } catch (e: IOException) {
                Log.e(TAG, "Failed to write to Downloads: ${e.message}", e)
                null
            } catch (e: SecurityException) {
                Log.e(TAG, "Permission error: ${e.message}", e)
                null
            }
        }
    }
}