// MoneyBaseApplication.kt
package com.thebase.moneybase

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings

@Suppress("DEPRECATION")
class MoneyBaseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Must be called before any Firestore usage
        FirebaseApp.initializeApp(this)
        setupFirestore()
    }

    private fun setupFirestore() {
        val db = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
            .setPersistenceEnabled(true)
            .setCacheSizeBytes(100L * 1024L * 1024L) // 100 MB offline cache
            .build()
        db.firestoreSettings = settings
    }
}