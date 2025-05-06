package com.thebase.moneybase.database

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.compose.material3.SnackbarHostState
import com.cloudinary.android.MediaManager
import com.cloudinary.android.callback.ErrorInfo
import com.cloudinary.android.callback.UploadCallback
import com.thebase.moneybase.R
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.InputStream

class CloudinaryManager {
    companion object {
        private const val TAG = "CloudinaryManager"
        private var isInitialized = false

        // ----------------------------
        // Initialization
        // ----------------------------
        /**
         * Initialize Cloudinary with your configuration.
         */
        fun init(context: Context) {
            if (!isInitialized) {
                try {
                    val config = mapOf(
                        "cloud_name" to context.getString(R.string.cloudinary_cloud_name),
                        "api_key" to context.getString(R.string.cloudinary_api_key),
                        "api_secret" to context.getString(R.string.cloudinary_api_secret)
                    )
                    MediaManager.init(context, config)
                    isInitialized = true
                } catch (e: Exception) {
                    Log.e(TAG, "Error initializing Cloudinary", e)
                }
            }
        }

        // ----------------------------
        // Upload from URI
        // ----------------------------
        /**
         * Upload an image from a URI to Cloudinary and return the secure URL.
         */
        suspend fun uploadImage(context: Context, imageUri: Uri, userId: String): String? {
            return withContext(Dispatchers.IO) {
                if (!isInitialized) {
                    init(context)
                }

                val deferred = CompletableDeferred<String?>()

                try {
                    MediaManager.get()
                        .upload(imageUri)
                        .option("folder", context.getString(R.string.cloudinary_folder))
                        .option("public_id", "profile_$userId")
                        .option("overwrite", true)
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

        // ----------------------------
        // Upload from InputStream
        // ----------------------------
        /**
         * Upload an image from an InputStream (e.g., from the camera) to Cloudinary and return the secure URL.
         */
        suspend fun uploadImageFromStream(context: Context, inputStream: InputStream, userId: String): String? {
            return withContext(Dispatchers.IO) {
                if (!isInitialized) {
                    init(context)
                }

                try {
                    val bytes = inputStream.readBytes()

                    val uploadResult = com.cloudinary.Cloudinary(
                        mapOf(
                            "cloud_name" to context.getString(R.string.cloudinary_cloud_name),
                            "api_key" to context.getString(R.string.cloudinary_api_key),
                            "api_secret" to context.getString(R.string.cloudinary_api_secret)
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

// ----------------------------
// Utility Function
// ----------------------------
/**
 * Upload an image to Cloudinary and update the user's profile picture in Firebase.
 */
fun uploadImageToCloudinary(
    context: Context,
    imageUri: Uri,
    userId: String,
    repo: FirebaseRepositories,
    coroutineScope: CoroutineScope,
    snackbarHostState: SnackbarHostState,
    onSuccess: () -> Unit
) {
    Log.d("MoneyBase", "Starting image upload to Cloudinary for user: $userId")

    coroutineScope.launch {
        try {
            snackbarHostState.showSnackbar("Uploading image...")

            // Upload image to Cloudinary
            Log.d("MoneyBase", "Calling CloudinaryManager.uploadImage")
            val imageUrl = CloudinaryManager.uploadImage(
                context = context,
                imageUri = imageUri,
                userId = userId
            )

            if (imageUrl != null) {
                Log.d("MoneyBase", "Cloudinary upload successful, received URL: $imageUrl")

                // Update profile picture URL in Firebase
                val success = repo.updateProfilePicture(userId, imageUrl)
                if (success) {
                    Log.d("MoneyBase", "Profile picture updated successfully")
                    snackbarHostState.showSnackbar("Profile picture updated successfully")
                    onSuccess()
                } else {
                    Log.e("MoneyBase", "Failed to update profile picture")
                    snackbarHostState.showSnackbar("Failed to update profile picture")
                }
            } else {
                Log.e("MoneyBase", "Cloudinary upload failed, no URL returned")
                snackbarHostState.showSnackbar("Failed to upload image")
            }
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error during image upload", e)
            snackbarHostState.showSnackbar("Error: ${e.message}")
        }
    }
}