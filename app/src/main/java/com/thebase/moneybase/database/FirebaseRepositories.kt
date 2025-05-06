package com.thebase.moneybase.database

import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

@Suppress("unused")
class FirebaseRepositories {
    private val db = Firebase.firestore
    private val auth = Firebase.auth

    // ----------------------------
    // Authentication Functions
    // ----------------------------
    suspend fun registerUser(email: String, password: String, username: String): Boolean {
        return try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            val user = User(
                id = result.user?.uid ?: "",
                displayName = username,
                email = email,
                createdAt = System.currentTimeMillis().toString(),
                lastLoginAt = System.currentTimeMillis().toString()
            )
            db.collection("users").document(user.id).set(user).await()

            result.user?.updateProfile(
                com.google.firebase.auth.UserProfileChangeRequest.Builder()
                    .setDisplayName(username)
                    .build()
            )?.await()

            true
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Registration failed", e)
            false
        }
    }

    suspend fun loginUser(email: String, password: String): Boolean {
        return try {
            auth.signInWithEmailAndPassword(email, password).await()
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun updateUserPassword(userId: String, currentPassword: String, newPassword: String): Boolean {
        return try {
            val currentUser = auth.currentUser
            if (currentUser != null && currentUser.uid == userId) {
                val email = currentUser.email ?: return false
                val credential = com.google.firebase.auth.EmailAuthProvider.getCredential(email, currentPassword)
                currentUser.reauthenticate(credential).await()
                currentUser.updatePassword(newPassword).await()
                return true
            }
            false
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Password change failed", e)
            false
        }
    }

    fun getCurrentUser() = auth.currentUser

    // ----------------------------
    // User Management Functions
    // ----------------------------
    suspend fun getUser(userId: String): User? {
        return try {
            db.collection("users").document(userId).get().await().toObject(User::class.java)
        } catch (e: Exception) {
            null
        }
    }

    suspend fun updateUserProfile(userId: String, displayName: String, email: String): Boolean {
        return try {
            val userRef = db.collection("users").document(userId)
            val userData = hashMapOf<String, Any>(
                "displayName" to displayName,
                "email" to email
            )
            userRef.update(userData).await()

            val currentUser = auth.currentUser
            if (currentUser != null && currentUser.uid == userId) {
                currentUser.updateProfile(
                    com.google.firebase.auth.UserProfileChangeRequest.Builder()
                        .setDisplayName(displayName)
                        .build()
                ).await()

                if (currentUser.email != email) {
                    currentUser.updateEmail(email).await()
                }
            }

            true
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Update profile failed", e)
            false
        }
    }

    suspend fun updateProfilePicture(userId: String, profilePictureUrl: String): Boolean {
        return try {
            db.collection("users").document(userId)
                .update("profilePictureUrl", profilePictureUrl).await()

            val currentUser = auth.currentUser
            if (currentUser != null && currentUser.uid == userId) {
                currentUser.updateProfile(
                    com.google.firebase.auth.UserProfileChangeRequest.Builder()
                        .setPhotoUri(android.net.Uri.parse(profilePictureUrl))
                        .build()
                ).await()
            }

            true
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Profile picture update failed", e)
            false
        }
    }

    suspend fun ensureGoogleUserInDatabase(user: com.google.firebase.auth.FirebaseUser): Boolean {
        return try {
            val userDoc = db.collection("users").document(user.uid).get().await()

            if (!userDoc.exists()) {
                val newUser = User(
                    id = user.uid,
                    displayName = user.displayName ?: "Google User",
                    email = user.email ?: "",
                    createdAt = System.currentTimeMillis().toString(),
                    lastLoginAt = System.currentTimeMillis().toString(),
                    photoUrl = user.photoUrl?.toString()
                )
                db.collection("users").document(user.uid).set(newUser).await()
            } else {
                db.collection("users").document(user.uid)
                    .update("lastLoginAt", System.currentTimeMillis().toString())
                    .await()
            }
            true
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Failed to save Google user data", e)
            false
        }
    }

    // ----------------------------
    // Transaction Management Functions
    // ----------------------------
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
        }
    }

    suspend fun updateTransaction(userId: String, transaction: Transaction) {
        try {
            db.collection("users").document(userId).collection("transactions")
                .document(transaction.id).set(transaction).await()
        } catch (e: Exception) {
        }
    }

    suspend fun deleteTransaction(userId: String, transactionId: String) {
        try {
            db.collection("users").document(userId).collection("transactions")
                .document(transactionId).delete().await()
        } catch (e: Exception) {
        }
    }

    suspend fun getAllTransactions(userId: String): List<Transaction> {
        return try {
            val snapshot = db.collection("users").document(userId)
                .collection("transactions")
                .get()
                .await()

            snapshot.toObjects(Transaction::class.java)
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Failed to get all transactions", e)
            emptyList()
        }
    }

    // ----------------------------
    // Wallet Management Functions
    // ----------------------------
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
        }
    }

    suspend fun deleteWallet(userId: String, walletId: String) {
        try {
            db.collection("users").document(userId).collection("wallets")
                .document(walletId).delete().await()
        } catch (e: Exception) {
        }
    }

    suspend fun getAllWallets(userId: String): List<Wallet> {
        return try {
            val snapshot = db.collection("users").document(userId)
                .collection("wallets")
                .get()
                .await()

            snapshot.toObjects(Wallet::class.java)
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Failed to get all wallets", e)
            emptyList()
        }
    }

    // ----------------------------
    // Category Management Functions
    // ----------------------------
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
        }
    }

    suspend fun deleteCategory(userId: String, categoryId: String) {
        try {
            db.collection("users").document(userId).collection("categories")
                .document(categoryId).delete().await()
        } catch (e: Exception) {
        }
    }

    suspend fun getAllCategories(userId: String): List<Category> {
        return try {
            val snapshot = db.collection("users").document(userId)
                .collection("categories")
                .get()
                .await()

            snapshot.toObjects(Category::class.java)
        } catch (e: Exception) {
            android.util.Log.e("MoneyBase", "Failed to get all categories", e)
            emptyList()
        }
    }
}