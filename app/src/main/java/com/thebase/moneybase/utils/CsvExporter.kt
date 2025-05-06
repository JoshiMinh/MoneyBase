package com.thebase.moneybase.utils

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.Wallet
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStreamWriter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.*

class CsvExporter {
    companion object {
        private const val TAG = "CsvExporter"
        
        /**
         * Export danh sách giao dịch ra file CSV
         * @param context Context ứng dụng
         * @param transactions Danh sách giao dịch cần xuất
         * @param categories Danh sách category để mapping tên
         * @param wallets Danh sách ví để mapping tên
         * @param uri Uri đích để lưu file (null nếu lưu vào Downloads)
         * @return Uri của file đã tạo hoặc null nếu thất bại
         */
        suspend fun exportTransactions(
            context: Context,
            transactions: List<Transaction>,
            categories: List<Category>,
            wallets: List<Wallet>,
            uri: Uri? = null
        ): Uri? = withContext(Dispatchers.IO) {
            try {
                // Tạo tên file với timestamp
                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
                    .format(Date())
                val fileName = "moneybase_transactions_$timestamp.csv"
                
                // Header của file CSV
                val header = "ID,Ngày,Mô tả,Số tiền,Loại tiền tệ,Ví,Danh mục,Thu/Chi\n"
                
                // Nội dung của file CSV
                val csvContent = StringBuilder().apply {
                    append(header)
                    
                    transactions.forEach { transaction ->
                        // Tìm thông tin category và wallet
                        val category = categories.find { it.id == transaction.categoryId }?.name ?: ""
                        val wallet = wallets.find { it.id == transaction.walletId }?.name ?: ""
                        
                        // Xác định thu hay chi
                        val type = if (transaction.isIncome) "Thu" else "Chi"
                        
                        // Format số tiền
                        val amount = "%.2f".format(Locale.getDefault(), Math.abs(transaction.amount))
                        
                        // Thêm dòng dữ liệu
                        append("\"${transaction.id}\",")
                        append("\"${transaction.date}\",")
                        append("\"${transaction.description.replace("\"", "\"\"")}\",")
                        append("\"$amount\",")
                        append("\"${transaction.currencyCode}\",")
                        append("\"${wallet.replace("\"", "\"\"")}\",")
                        append("\"${category.replace("\"", "\"\"")}\",")
                        append("\"$type\"")
                        append("\n")
                    }
                }.toString()
                
                return@withContext if (uri != null) {
                    // Ghi vào URI được cung cấp (thường từ SAF - Storage Access Framework)
                    writeToUri(context, uri, csvContent, fileName)
                } else {
                    // Lưu vào thư mục Downloads
                    writeToDownloads(context, csvContent, fileName)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Export failed: ${e.message}", e)
                null
            }
        }
        
        /**
         * Ghi nội dung vào Uri được chỉ định (thường từ SAF)
         */
        private fun writeToUri(
            context: Context,
            uri: Uri,
            content: String,
            fileName: String
        ): Uri? {
            return try {
                // Tạo document con trong thư mục được chọn
                val docUri = DocumentFile.fromTreeUri(context, uri)
                    ?.createFile("text/csv", fileName)
                    ?.uri
                
                if (docUri != null) {
                    context.contentResolver.openOutputStream(docUri)?.use { outputStream ->
                        OutputStreamWriter(outputStream).use { writer ->
                            writer.write(content)
                        }
                    }
                    docUri
                } else {
                    Log.e(TAG, "Could not create document in the selected directory")
                    null
                }
            } catch (e: IOException) {
                Log.e(TAG, "Failed to write to Uri: ${e.message}", e)
                null
            } catch (e: IllegalArgumentException) {
                // Thử sử dụng thư mục Downloads nếu URI không hợp lệ
                Log.e(TAG, "Invalid URI, trying to save to Downloads: ${e.message}", e)
                writeToDownloads(context, content, fileName)
            }
        }
        
        /**
         * Ghi nội dung vào thư mục Downloads
         */
        private fun writeToDownloads(
            context: Context,
            content: String,
            fileName: String
        ): Uri? {
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    // Sử dụng MediaStore API cho Android 10 trở lên
                    val contentValues = ContentValues().apply {
                        put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                        put(MediaStore.MediaColumns.MIME_TYPE, "text/csv")
                        put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                    }
                    
                    val resolver = context.contentResolver
                    val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                    
                    if (uri != null) {
                        resolver.openOutputStream(uri)?.use { outputStream ->
                            OutputStreamWriter(outputStream).use { writer ->
                                writer.write(content)
                            }
                        }
                        uri
                    } else {
                        Log.e(TAG, "Failed to create MediaStore entry")
                        null
                    }
                } else {
                    // Phương pháp cũ cho Android 9 trở xuống
                    val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                    if (!downloadsDir.exists()) {
                        downloadsDir.mkdirs()
                    }
                    
                    val file = File(downloadsDir, fileName)
                    
                    FileOutputStream(file).use { outputStream ->
                        OutputStreamWriter(outputStream).use { writer ->
                            writer.write(content)
                        }
                    }
                    
                    Uri.fromFile(file)
                }
            } catch (e: IOException) {
                Log.e(TAG, "Failed to write to Downloads: ${e.message}", e)
                null
            } catch (e: SecurityException) {
                Log.e(TAG, "Security exception: ${e.message}", e)
                null
            }
        }
    }
} 