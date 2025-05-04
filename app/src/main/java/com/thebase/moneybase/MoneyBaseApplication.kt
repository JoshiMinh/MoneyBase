package com.thebase.moneybase

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.thebase.moneybase.firebase.CloudinaryManager
import com.thebase.moneybase.notifications.NotificationHelper

@Suppress("DEPRECATION")
class MoneyBaseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        setupFirestore()
        
        // Khởi tạo Cloudinary
        initCloudinary()
        
        // Khởi tạo kênh thông báo
        initNotifications()
    }

    private fun setupFirestore() {
        val db = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
            .setPersistenceEnabled(true)
            .setCacheSizeBytes(100L * 1024L * 1024L)
            .build()
        db.firestoreSettings = settings
    }
    
    private fun initCloudinary() {
        try {
            CloudinaryManager.init(this)
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Error initializing Cloudinary", e)
        }
    }
    
    private fun initNotifications() {
        val notificationHelper = NotificationHelper(this)
        notificationHelper.createNotificationChannel()
    }
}