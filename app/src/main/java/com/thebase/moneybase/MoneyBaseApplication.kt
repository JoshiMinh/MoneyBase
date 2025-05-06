@file:Suppress("DEPRECATION")

package com.thebase.moneybase

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.thebase.moneybase.database.CloudinaryManager
import com.thebase.moneybase.notifications.NotificationHelper

class MoneyBaseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        setupFirestore()
        initCloudinary()
        initNotifications()
    }

    private fun setupFirestore() {
        val db = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
            .setPersistenceEnabled(true)
            .setCacheSizeBytes(100L * 1024L * 1024L) // 100 MB cache size
            .build()
        db.firestoreSettings = settings
    }

    private fun initCloudinary() {
        try {
            CloudinaryManager.init(this)
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error initializing Cloudinary", e)
        }
    }

    private fun initNotifications() {
        NotificationHelper(this).createNotificationChannel()
    }
}