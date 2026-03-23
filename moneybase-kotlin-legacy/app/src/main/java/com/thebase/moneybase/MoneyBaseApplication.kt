@file:Suppress("DEPRECATION")

package com.thebase.moneybase

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.ktx.Firebase
import com.thebase.moneybase.database.CloudinaryManager
import com.thebase.moneybase.utils.notifications.NotificationHelper

class MoneyBaseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            initFirebase()
            setupFirestore()
            initCloudinary()
            initNotifications()
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error initializing application", e)
        }
    }

    private fun initFirebase() {
        try {
            if (FirebaseApp.getApps(this).isEmpty()) {
                FirebaseApp.initializeApp(this)
            }
            // Pre-initialize auth to avoid potential timing issues
            Firebase.auth
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error initializing Firebase", e)
        }
    }

    private fun setupFirestore() {
        try {
            val db = FirebaseFirestore.getInstance()
            val settings = FirebaseFirestoreSettings.Builder()
                .setPersistenceEnabled(true)
                .setCacheSizeBytes(100L * 1024L * 1024L) // 100 MB cache size
                .build()
            db.firestoreSettings = settings
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error setting up Firestore", e)
        }
    }

    private fun initCloudinary() {
        try {
            CloudinaryManager.init(this)
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error initializing Cloudinary", e)
        }
    }

    private fun initNotifications() {
        try {
            NotificationHelper(this).createNotificationChannel()
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error initializing notifications", e)
        }
    }
}