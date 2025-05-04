package com.thebase.moneybase.firebase

import android.content.Context
import android.net.Uri
import android.util.Log
import com.cloudinary.android.MediaManager
import com.cloudinary.android.callback.ErrorInfo
import com.cloudinary.android.callback.UploadCallback
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.InputStream

class CloudinaryManager {
    companion object {
        private const val TAG = "CloudinaryManager"
        private var isInitialized = false

        // Khởi tạo Cloudinary với config của bạn
        fun init(context: Context) {
            if (!isInitialized) {
                try {
                    val config = mapOf(
                        "cloud_name" to "dzepzbiec", // Thay bằng cloud name của bạn
                        "api_key" to "265685784776223",       // Thay bằng API key của bạn
                        "api_secret" to "HAIzrk1Bzy7lQjqU6CKPUfNWgk8"  // Thay bằng API secret của bạn
                    )
                    MediaManager.init(context, config)
                    isInitialized = true
                } catch (e: Exception) {
                    Log.e(TAG, "Error initializing Cloudinary", e)
                }
            }
        }

        // Upload ảnh từ Uri và trả về URL
        suspend fun uploadImage(context: Context, imageUri: Uri, userId: String): String? {
            return withContext(Dispatchers.IO) {
                if (!isInitialized) {
                    init(context)
                }

                val deferred = CompletableDeferred<String?>()
                
                try {
                    // Tạo tên file duy nhất dựa trên userId
                    val requestId = MediaManager.get()
                        .upload(imageUri)
                        .option("folder", "moneybase/profiles") // Folder trên Cloudinary
                        .option("public_id", "profile_$userId") // Dùng userId để tạo tên file
                        .option("overwrite", true)              // Ghi đè nếu file đã tồn tại
                        .callback(object : UploadCallback {
                            override fun onStart(requestId: String) {
                                Log.d(TAG, "Upload started: $requestId")
                            }

                            override fun onProgress(requestId: String, bytes: Long, totalBytes: Long) {
                                val progress = (bytes * 100) / totalBytes
                                Log.d(TAG, "Upload progress: $progress%")
                            }

                            override fun onSuccess(requestId: String, resultData: Map<*, *>) {
                                Log.d(TAG, "Upload successful: $requestId")
                                val secureUrl = resultData["secure_url"] as? String
                                deferred.complete(secureUrl)
                            }

                            override fun onError(requestId: String, error: ErrorInfo) {
                                Log.e(TAG, "Upload error: ${error.description}")
                                deferred.complete(null)
                            }

                            override fun onReschedule(requestId: String, error: ErrorInfo) {
                                Log.d(TAG, "Upload rescheduled: $requestId")
                            }
                        })
                        .dispatch()

                    deferred.await()
                } catch (e: Exception) {
                    Log.e(TAG, "Error during upload", e)
                    null
                }
            }
        }

        // Upload ảnh từ InputStream (nếu bạn lấy ảnh từ camera)
        suspend fun uploadImageFromStream(context: Context, inputStream: InputStream, userId: String): String? {
            return withContext(Dispatchers.IO) {
                if (!isInitialized) {
                    init(context)
                }

                try {
                    // Đọc dữ liệu từ InputStream
                    val bytes = inputStream.readBytes()
                    
                    // Upload dữ liệu lên Cloudinary qua API
                    val uploadResult = com.cloudinary.Cloudinary(
                        mapOf(
                            "cloud_name" to "your_cloud_name",
                            "api_key" to "your_api_key",
                            "api_secret" to "your_api_secret"
                        )
                    ).uploader().upload(
                        bytes,
                        mapOf(
                            "folder" to "moneybase/profiles",
                            "public_id" to "profile_$userId",
                            "overwrite" to true
                        )
                    )
                    
                    uploadResult["secure_url"] as? String
                } catch (e: Exception) {
                    Log.e(TAG, "Error uploading from stream", e)
                    null
                }
            }
        }
    }
} 