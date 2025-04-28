// Repositories.kt
package com.thebase.moneybase.firebase

import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.FirebaseFirestore
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
    /** Create or overwrite a User document */
    suspend fun createUser(user: User) {
        try {
            db.collection("users")
                .document(user.id)
                .set(user)
                .await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    /** Currently signed-in Firebase Auth user (if any) */
    fun getCurrentUser(): FirebaseUser? = auth.currentUser

    /** Fetch User data by ID */
    suspend fun getUser(userId: String): User? {
        return try {
            db.collection("users")
                .document(userId)
                .get()
                .await()
                .toObject(User::class.java)
        } catch (e: Exception) {
            // Handle the exception
            null
        }
    }

    // --- Transactions ---
    /** Stream all (non-deleted) transactions for a user */
    fun getTransactionsFlow(userId: String): Flow<List<Transaction>> = callbackFlow {
        val listener = db.collection("users")
            .document(userId)
            .collection("transactions")
            .addSnapshotListener { snap, err ->
                if (err != null) {
                    close(err); return@addSnapshotListener
                }
                val list = snap?.toObjects(Transaction::class.java) ?: emptyList()
                trySend(list)
            }
        awaitClose { listener.remove() }
    }

    /** Add a new transaction, auto-assigning its ID */
    suspend fun addTransaction(userId: String, transaction: Transaction) {
        try {
            val doc = db.collection("users")
                .document(userId)
                .collection("transactions")
                .document()
            val txWithId = transaction.copy(id = doc.id)
            doc.set(txWithId).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    /** Update an existing transaction (overwrites by ID) */
    suspend fun updateTransaction(userId: String, transaction: Transaction) {
        try {
            db.collection("users")
                .document(userId)
                .collection("transactions")
                .document(transaction.id)
                .set(transaction)
                .await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    /** Delete a transaction by its ID */
    suspend fun deleteTransaction(userId: String, transactionId: String) {
        try {
            db.collection("users")
                .document(userId)
                .collection("transactions")
                .document(transactionId)
                .delete()
                .await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    // --- Wallets ---
    /** Stream all (non-deleted) wallets for a user */
    fun getWalletsFlow(userId: String): Flow<List<Wallet>> = callbackFlow {
        val listener = db.collection("users")
            .document(userId)
            .collection("wallets")
            .addSnapshotListener { snap, err ->
                if (err != null) {
                    close(err); return@addSnapshotListener
                }
                val list = snap?.toObjects(Wallet::class.java) ?: emptyList()
                trySend(list)
            }
        awaitClose { listener.remove() }
    }

    /** Add a new wallet, returning its generated ID */
    suspend fun addWallet(userId: String, wallet: Wallet): String {
        return try {
            val doc = db.collection("users")
                .document(userId)
                .collection("wallets")
                .document()
            val wWithId = wallet.copy(id = doc.id)
            doc.set(wWithId).await()
            doc.id
        } catch (e: Exception) {
            // Handle the exception
            ""
        }
    }

    /** Update an existing wallet (overwrites by ID) */
    suspend fun updateWallet(userId: String, wallet: Wallet) {
        try {
            db.collection("users")
                .document(userId)
                .collection("wallets")
                .document(wallet.id)
                .set(wallet)
                .await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    /** Soft-delete or hard-delete a wallet by ID */
    suspend fun deleteWallet(userId: String, walletId: String) {
        try {
            // Hard delete:
            db.collection("users")
                .document(userId)
                .collection("wallets")
                .document(walletId)
                .delete()
                .await()
            // Or, to soft-delete instead, replace the above with:
            // db.collection("users").document(userId).collection("wallets")
            //   .document(walletId).update("isDeleted", true).await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    // --- Categories ---
    /** Stream all categories for a user */
    fun getCategoriesFlow(userId: String): Flow<List<Category>> = callbackFlow {
        val listener = db.collection("users")
            .document(userId)
            .collection("categories")
            .addSnapshotListener { snap, err ->
                if (err != null) {
                    close(err); return@addSnapshotListener
                }
                val list = snap?.toObjects(Category::class.java) ?: emptyList()
                trySend(list)
            }
        awaitClose { listener.remove() }
    }

    /** Add a new category, returning its generated ID */
    suspend fun addCategory(userId: String, category: Category): String {
        return try {
            val doc = db.collection("users")
                .document(userId)
                .collection("categories")
                .document()
            val cWithId = category.copy(id = doc.id)
            doc.set(cWithId).await()
            doc.id
        } catch (e: Exception) {
            // Handle the exception
            ""
        }
    }

    /** Update an existing category (overwrites by ID) */
    suspend fun updateCategory(userId: String, category: Category) {
        try {
            db.collection("users")
                .document(userId)
                .collection("categories")
                .document(category.id)
                .set(category)
                .await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }

    /** Hard-delete a category by ID */
    suspend fun deleteCategory(userId: String, categoryId: String) {
        try {
            db.collection("users")
                .document(userId)
                .collection("categories")
                .document(categoryId)
                .delete()
                .await()
        } catch (e: Exception) {
            // Handle the exception
        }
    }
}