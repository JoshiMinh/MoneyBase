package com.thebase.moneybase

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.PersistentCacheSettings

class MoneyBaseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        configureFirestore()
    }

    private fun configureFirestore() {
        val db = FirebaseFirestore.getInstance()
        val settings = FirebaseFirestoreSettings.Builder()
            .setLocalCacheSettings(
                PersistentCacheSettings.newBuilder()
                    .setSizeBytes(50 * 1024 * 1024) // 50MB local cache
                    .build()
            )
            .build()

        db.firestoreSettings = settings
    }

    companion object {
        fun getFirestore(): FirebaseFirestore = FirebaseFirestore.getInstance()
    }
}