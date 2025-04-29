// Repositories.kt
package com.thebase.moneybase.firebase

import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

class Repositories {
    private val db = Firebase.firestore
    private val auth = Firebase.auth

    // --- User Operations ---
    suspend fun createUser(user: User) {
        try {
            db.collection("users").document(user.id).set(user).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    fun getCurrentUser() = auth.currentUser

    suspend fun getUser(userId: String): User? {
        return try {
            db.collection("users").document(userId).get().await().toObject(User::class.java)
        } catch (e: Exception) {
            null
        }
    }

    // --- Transactions ---
    fun getTransactionsFlow(userId: String): Flow<List<Transaction>> = callbackFlow {
        val listener = db.collection("users").document(userId)
            .collection("transactions").addSnapshotListener { snap, err ->
                if (err != null) {
                    close(err); return@addSnapshotListener
                }
                val list = snap?.toObjects(Transaction::class.java) ?: emptyList()
                trySend(list)
            }
        awaitClose { listener.remove() }
    }

    suspend fun addTransaction(userId: String, transaction: Transaction) {
        try {
            val doc = db.collection("users").document(userId).collection("transactions").document()
            val txWithId = transaction.copy(id = doc.id)
            doc.set(txWithId).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    suspend fun updateTransaction(userId: String, transaction: Transaction) {
        try {
            db.collection("users").document(userId).collection("transactions")
                .document(transaction.id).set(transaction).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    suspend fun deleteTransaction(userId: String, transactionId: String) {
        try {
            db.collection("users").document(userId).collection("transactions")
                .document(transactionId).delete().await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    // --- Wallets ---
    fun getWalletsFlow(userId: String): Flow<List<Wallet>> = callbackFlow {
        val listener = db.collection("users").document(userId).collection("wallets")
            .addSnapshotListener { snap, err ->
                if (err != null) {
                    close(err); return@addSnapshotListener
                }
                val list = snap?.toObjects(Wallet::class.java) ?: emptyList()
                trySend(list)
            }
        awaitClose { listener.remove() }
    }

    suspend fun addWallet(userId: String, wallet: Wallet): String {
        return try {
            val doc = db.collection("users").document(userId).collection("wallets").document()
            val wWithId = wallet.copy(id = doc.id)
            doc.set(wWithId).await()
            doc.id
        } catch (e: Exception) {
            ""
        }
    }

    suspend fun updateWallet(userId: String, wallet: Wallet) {
        try {
            db.collection("users").document(userId).collection("wallets")
                .document(wallet.id).set(wallet).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    suspend fun deleteWallet(userId: String, walletId: String) {
        try {
            db.collection("users").document(userId).collection("wallets")
                .document(walletId).delete().await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    // --- Categories ---
    fun getCategoriesFlow(userId: String): Flow<List<Category>> = callbackFlow {
        val listener = db.collection("users").document(userId).collection("categories")
            .addSnapshotListener { snap, err ->
                if (err != null) {
                    close(err); return@addSnapshotListener
                }
                val list = snap?.toObjects(Category::class.java) ?: emptyList()
                trySend(list)
            }
        awaitClose { listener.remove() }
    }

    suspend fun addCategory(userId: String, category: Category): String {
        return try {
            val doc = db.collection("users").document(userId).collection("categories").document()
            val cWithId = category.copy(id = doc.id)
            doc.set(cWithId).await()
            doc.id
        } catch (e: Exception) {
            ""
        }
    }

    suspend fun updateCategory(userId: String, category: Category) {
        try {
            db.collection("users").document(userId).collection("categories")
                .document(category.id).set(category).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    suspend fun deleteCategory(userId: String, categoryId: String) {
        try {
            db.collection("users").document(userId).collection("categories")
                .document(categoryId).delete().await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }
}