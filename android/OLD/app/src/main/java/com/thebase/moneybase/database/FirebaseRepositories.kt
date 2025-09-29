@file:Suppress("DEPRECATION")
package com.thebase.moneybase.database

import android.util.Log
import androidx.core.net.toUri
import com.google.firebase.Timestamp
import com.google.firebase.auth.EmailAuthProvider
import com.google.firebase.auth.UserProfileChangeRequest
import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.util.Date
import java.util.Locale
import kotlin.math.abs

@Suppress("unused")
class FirebaseRepositories {

    private val db = Firebase.firestore
    private val auth = Firebase.auth

    private fun List<Wallet>.sortedForDisplay(): List<Wallet> {
        return this.sortedWith(
            compareBy<Wallet> { it.position }
                .thenBy { it.name.lowercase(Locale.getDefault()) }
        )
    }

    private fun DocumentSnapshot.toWalletOrNull(): Wallet? {
        val payload = data ?: return null
        val userId = (payload["userId"] as? String)
            ?.takeIf { it.isNotBlank() }
            ?: reference?.parent?.parent?.id.orEmpty()
        val typeRaw = payload["type"] as? String
        val type = typeRaw?.let { raw ->
            Wallet.WalletType.values().firstOrNull { it.name.equals(raw, ignoreCase = true) }
        } ?: Wallet.WalletType.PHYSICAL
        val balance = (payload["balance"] as? Number)?.toDouble() ?: 0.0
        val position = (payload["position"] as? Number)?.toLong() ?: 0L
        return Wallet(
            id = id,
            userId = userId,
            name = (payload["name"] as? String).orEmpty(),
            balance = balance,
            iconName = (payload["iconName"] as? String) ?: "account_balance_wallet",
            color = (payload["color"] as? String).orEmpty(),
            type = type,
            currencyCode = (payload["currencyCode"] as? String) ?: "USD",
            position = position
        )
    }

    private fun DocumentSnapshot.toCategoryOrNull(): Category? {
        val payload = data ?: return null
        val userId = (payload["userId"] as? String)
            ?.takeIf { it.isNotBlank() }
            ?: reference?.parent?.parent?.id.orEmpty()
        val storedId = (payload["id"] as? String)?.takeIf { it.isNotBlank() }
        val parentId = (payload["parentCategoryId"] as? String)
            ?.takeIf { it.isNotBlank() }
        return Category(
            id = storedId ?: id,
            userId = userId,
            name = (payload["name"] as? String).orEmpty(),
            iconName = (payload["iconName"] as? String).orEmpty(),
            color = (payload["color"] as? String).orEmpty(),
            parentCategoryId = parentId
        )
    }

    // ----------------------------
    // Authentication Functions
    // ----------------------------

    suspend fun registerUser(email: String, password: String, username: String): Boolean {
        return try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            val user = result.user ?: return false
            val userId = user.uid
            val timestamp = Timestamp.now()
            val newUser = User(
                id = userId,
                displayName = username,
                email = email,
                createdAt = timestamp,
                lastLoginAt = timestamp
            )
            db.collection("users").document(userId).set(newUser).await()

            user.updateProfile(
                UserProfileChangeRequest.Builder()
                    .setDisplayName(username)
                    .build()
            )?.await()

            addDefaultCategories(userId)
            addDefaultWallets(userId)

            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "Registration failed", e)
            false
        }
    }

    private suspend fun addDefaultCategories(userId: String) {
        val defaults = listOf(
            Category(name = "Food", userId = userId, iconName = "fastfood", color = "#FF5733"),
            Category(name = "Transport", userId = userId, iconName = "directions_car", color = "#2196F3"),
            Category(name = "Entertainment", userId = userId, iconName = "local_activity", color = "#9C27B0")
        )
        defaults.forEach { cat ->
            val doc = db
                .collection("users").document(userId)
                .collection("categories").document()
            doc.set(cat.copy(id = doc.id)).await()
        }
    }

    private suspend fun addDefaultWallets(userId: String) {
        val defaults = listOf(
            Wallet(name = "Cash", userId = userId, balance = 0.0, iconName = "account_balance_wallet", color = "#4CAF50"),
            Wallet(name = "Bank Account", userId = userId, balance = 0.0, iconName = "account_balance", color = "#1976D2")
        )
        defaults.forEachIndexed { index, wallet ->
            val doc = db
                .collection("users").document(userId)
                .collection("wallets").document()
            val position = if (wallet.position != 0L) wallet.position else (index + 1).toLong()
            doc.set(wallet.copy(id = doc.id, position = position)).await()
        }
    }

    suspend fun loginUser(email: String, password: String): Boolean = try {
        auth.signInWithEmailAndPassword(email, password).await()
        true
    } catch (_: Exception) {
        false
    }

    suspend fun updateUserPassword(userId: String, currentPassword: String, newPassword: String): Boolean {
        return try {
            val user = auth.currentUser ?: return false
            if (user.uid != userId) return false
            val email = user.email ?: return false
            val credential = EmailAuthProvider.getCredential(email, currentPassword)
            user.reauthenticate(credential).await()
            user.updatePassword(newPassword).await()
            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "Password change failed", e)
            false
        }
    }

    fun getCurrentUser() = auth.currentUser

    // ----------------------------
    // User Management Functions
    // ----------------------------

    suspend fun getUser(userId: String): User? = try {
        val snap = db.collection("users").document(userId).get().await()
        if (snap.exists()) snap.toUserSafe() else null
    } catch (_: Exception) {
        null
    }

    suspend fun updateUserProfile(userId: String, displayName: String, email: String): Boolean {
        return try {
            val userRef = db.collection("users").document(userId)
            userRef.update(mapOf(
                "displayName" to displayName,
                "email" to email
            )).await()

            auth.currentUser?.takeIf { it.uid == userId }?.also { usr ->
                usr.updateProfile(
                    UserProfileChangeRequest.Builder()
                        .setDisplayName(displayName)
                        .build()
                )?.await()
                if (usr.email != email) usr.updateEmail(email).await()
            }
            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "Update profile failed", e)
            false
        }
    }

    suspend fun updateProfilePicture(userId: String, profilePictureUrl: String): Boolean {
        return try {
            db.collection("users").document(userId)
                .update("profilePictureUrl", profilePictureUrl).await()
            auth.currentUser?.takeIf { it.uid == userId }?.updateProfile(
                UserProfileChangeRequest.Builder()
                    .setPhotoUri(profilePictureUrl.toUri())
                    .build()
            )?.await()
            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "Profile picture update failed", e)
            false
        }
    }

    suspend fun ensureGoogleUserInDatabase(user: com.google.firebase.auth.FirebaseUser): Boolean {
        return try {
            val docRef = db.collection("users").document(user.uid)
            val snapshot = docRef.get().await()
            val timestamp = Timestamp.now()
            if (!snapshot.exists()) {
                val newUser = User(
                    id = user.uid,
                    displayName = user.displayName.orEmpty(),
                    email = user.email.orEmpty(),
                    createdAt = timestamp,
                    lastLoginAt = timestamp,
                    photoUrl = user.photoUrl?.toString()
                )
                docRef.set(newUser).await()
            } else {
                docRef.update("lastLoginAt", timestamp).await()
            }
            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "Failed to save Google user data", e)
            false
        }
    }

    // ----------------------------
    // Transaction Management Functions
    // ----------------------------

    fun getTransactionsFlow(userId: String): Flow<List<Transaction>> = callbackFlow {
        if (userId.isBlank()) {
            trySend(emptyList())
            return@callbackFlow
        }

        val listener = try {
            db.collection("users").document(userId)
                .collection("transactions")
                .orderBy("date")
                .addSnapshotListener { snap, err ->
                    if (err != null) { close(err); return@addSnapshotListener }
                    val list = snap?.documents?.map { it.toTransactionSafe() }.orEmpty()
                    trySend(list)
                }
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error in getTransactionsFlow: ${e.message}", e)
            trySend(emptyList())
            null
        }

        awaitClose {
            listener?.remove()
        }
    }

    suspend fun addTransaction(userId: String, transaction: Transaction): Boolean {
        return try {
            db.runTransaction { tx ->
                val normalized = transaction.normalized()
                val wallets = db.collection("users").document(userId).collection("wallets")
                val walletRef = wallets.document(normalized.walletId)
                val wallet = tx.get(walletRef).toWalletOrNull()
                    ?: throw IllegalStateException("Wallet not found")
                val delta = normalized.flowDelta()
                tx.update(walletRef, "balance", wallet.balance + delta)
                val txRef = db.collection("users").document(userId)
                    .collection("transactions").document()
                val payload = normalized.copy(
                    id = txRef.id,
                    userId = normalized.userId.ifBlank { userId }
                )
                tx.set(txRef, payload)
            }.await()
            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "addTransaction failed", e)
            false
        }
    }

    suspend fun updateTransaction(userId: String, transaction: Transaction): Boolean {
        return try {
            db.runTransaction { tx ->
                val normalized = transaction.normalized()
                val userRef = db.collection("users").document(userId)
                val txRef = userRef.collection("transactions").document(normalized.id)
                val originalSnap = tx.get(txRef)
                if (!originalSnap.exists()) throw IllegalStateException("Transaction not found")
                val original = originalSnap.toTransactionSafe()

                val oldWalletRef = userRef.collection("wallets").document(original.walletId)
                val oldWallet = tx.get(oldWalletRef).toWalletOrNull()
                    ?: throw IllegalStateException("Wallet not found")
                val originalDelta = original.flowDelta()
                tx.update(oldWalletRef, "balance", oldWallet.balance - originalDelta)

                val newWalletRef = userRef.collection("wallets").document(normalized.walletId)
                val newWallet = tx.get(newWalletRef).toWalletOrNull()
                    ?: throw IllegalStateException("Wallet not found")
                val newDelta = normalized.flowDelta()
                tx.update(newWalletRef, "balance", newWallet.balance + newDelta)

                val payload = normalized.copy(userId = normalized.userId.ifBlank { userId })
                tx.set(txRef, payload)
            }.await()
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun deleteTransaction(userId: String, transactionId: String): Boolean {
        return try {
            db.runTransaction { tx ->
                val userRef = db.collection("users").document(userId)
                val txRef = userRef.collection("transactions").document(transactionId)
                val originalSnap = tx.get(txRef)
                if (!originalSnap.exists()) throw IllegalStateException("Transaction not found")
                val original = originalSnap.toTransactionSafe()

                val walletRef = userRef.collection("wallets").document(original.walletId)
                val wallet = tx.get(walletRef).toWalletOrNull()
                    ?: throw IllegalStateException("Wallet not found")
                val originalDelta = original.flowDelta()
                tx.update(walletRef, "balance", wallet.balance - originalDelta)

                tx.delete(txRef)
            }.await()
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun getAllTransactions(userId: String): List<Transaction> = try {
        db.collection("users").document(userId)
            .collection("transactions").get().await().documents
            .map { it.toTransactionSafe() }
    } catch (e: Exception) {
        Log.e("MoneyBase", "Failed to get all transactions", e)
        emptyList()
    }

    // ----------------------------
    // Wallet Management Functions
    // ----------------------------

    fun getWalletsFlow(userId: String): Flow<List<Wallet>> = callbackFlow {
        if (userId.isBlank()) {
            trySend(emptyList())
            return@callbackFlow
        }
        
        val listener = try {
            db.collection("users").document(userId).collection("wallets")
                .addSnapshotListener { snap, err ->
                    if (err != null) { close(err); return@addSnapshotListener }
                    val wallets = snap?.documents
                        ?.mapNotNull { it.toWalletOrNull() }
                        .orEmpty()
                    trySend(wallets.sortedForDisplay())
                }
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error in getWalletsFlow: ${e.message}", e)
            trySend(emptyList())
            null
        }
        
        awaitClose { 
            listener?.remove() 
        }
    }

    suspend fun transferBalance(userId: String, sourceWalletId: String, amount: Double, targetWalletId: String): Boolean {
        return try {
            db.runTransaction { tx ->
                val base = db.collection("users").document(userId)
                val srcRef = base.collection("wallets").document(sourceWalletId)
                val tgtRef = base.collection("wallets").document(targetWalletId)
                val src = tx.get(srcRef).toWalletOrNull()
                    ?: throw IllegalStateException("Source wallet not found")
                val tgt = tx.get(tgtRef).toWalletOrNull()
                    ?: throw IllegalStateException("Target wallet not found")
                if (src.balance < amount) throw FirebaseFirestoreException("Insufficient funds", FirebaseFirestoreException.Code.ABORTED)
                tx.update(srcRef, "balance", src.balance - amount)
                tx.update(tgtRef, "balance", tgt.balance + amount)
            }.await()
            true
        } catch (e: Exception) {
            Log.e("MoneyBase", "transferBalance failed", e)
            false
        }
    }

    suspend fun addWallet(userId: String, wallet: Wallet): String {
        return try {
            val doc = db.collection("users").document(userId)
                .collection("wallets").document()
            val position = if (wallet.position != 0L) {
                wallet.position
            } else {
                System.currentTimeMillis() * 1000
            }
            val payload = wallet.copy(
                id = doc.id,
                userId = wallet.userId.ifBlank { userId },
                position = position
            )
            doc.set(payload).await()
            doc.id
        } catch (_: Exception) {
            ""
        }
    }

    suspend fun updateWallet(userId: String, wallet: Wallet): Boolean {
        return try {
            db.collection("users").document(userId)
                .collection("wallets").document(wallet.id)
                .set(
                    wallet.copy(
                        userId = wallet.userId.ifBlank { userId },
                        position = if (wallet.position != 0L) {
                            wallet.position
                        } else {
                            System.currentTimeMillis() * 1000
                        }
                    )
                ).await()
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun deleteWallet(userId: String, walletId: String): Boolean {
        return try {
            db.collection("users").document(userId)
                .collection("wallets").document(walletId)
                .delete().await()
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun getAllWallets(userId: String): List<Wallet> = try {
        db.collection("users").document(userId)
            .collection("wallets").get().await()
            .documents
            .mapNotNull { it.toWalletOrNull() }
            .sortedForDisplay()
    } catch (e: Exception) {
        Log.e("MoneyBase", "Failed to get all wallets", e)
        emptyList()
    }

    // ----------------------------
    // Category Management Functions
    // ----------------------------

    fun getCategoriesFlow(userId: String): Flow<List<Category>> = callbackFlow {
        if (userId.isBlank()) {
            trySend(emptyList())
            return@callbackFlow
        }
        
        val listener = try {
            db.collection("users").document(userId).collection("categories")
                .addSnapshotListener { snap, err ->
                    if (err != null) { close(err); return@addSnapshotListener }
                    val categories = snap?.documents
                        ?.mapNotNull { it.toCategoryOrNull() }
                        .orEmpty()
                    trySend(categories)
                }
        } catch (e: Exception) {
            Log.e("MoneyBase", "Error in getCategoriesFlow: ${e.message}", e)
            trySend(emptyList())
            null
        }
        
        awaitClose { 
            listener?.remove() 
        }
    }

    suspend fun addCategory(userId: String, category: Category): String {
        return try {
            val doc = db.collection("users").document(userId)
                .collection("categories").document()
            doc.set(category.copy(id = doc.id)).await()
            doc.id
        } catch (_: Exception) {
            ""
        }
    }

    suspend fun updateCategory(userId: String, category: Category): Boolean {
        return try {
            db.collection("users").document(userId)
                .collection("categories").document(category.id)
                .set(category).await()
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun deleteCategory(userId: String, categoryId: String): Boolean {
        return try {
            db.collection("users").document(userId)
                .collection("categories").document(categoryId)
                .delete().await()
            true
        } catch (_: Exception) {
            false
        }
    }

    suspend fun getAllCategories(userId: String): List<Category> = try {
        db.collection("users").document(userId)
            .collection("categories").get().await()
            .documents
            .mapNotNull { it.toCategoryOrNull() }
    } catch (e: Exception) {
        Log.e("MoneyBase", "Failed to get all categories", e)
        emptyList()
    }

    // ----------------------------
    // Parsing Helpers
    // ----------------------------

    private fun DocumentSnapshot.getTimestampField(name: String): Timestamp {
        val raw = get(name)
        return when (raw) {
            is Timestamp -> raw
            is String -> raw.toLongOrNull()?.let {
                Timestamp(Date(it)).also { ts -> reference.update(name, ts) }
            } ?: Timestamp.now()
            is Number -> Timestamp(Date(raw.toLong())).also { ts -> reference.update(name, ts) }
            else -> Timestamp.now()
        }
    }

    private fun DocumentSnapshot.toUserSafe(): User {
        val createdAtTs = getTimestampField("createdAt")
        val lastLoginTs = getTimestampField("lastLoginAt")
        return User(
            id = id,
            displayName = getString("displayName").orEmpty(),
            email = getString("email").orEmpty(),
            createdAt = createdAtTs,
            lastLoginAt = lastLoginTs,
            premium = getBoolean("premium") ?: false,
            profilePictureUrl = getString("profilePictureUrl").orEmpty(),
            photoUrl = getString("photoUrl")
        )
    }

    private fun DocumentSnapshot.toTransactionSafe(): Transaction {
        val amountAny = get("amount")
        val amount = when (amountAny) {
            is Number -> amountAny.toDouble()
            is String -> amountAny.toDoubleOrNull() ?: 0.0
            else -> 0.0
        }
        val isIncome = getBoolean("isIncome") ?: false
        return Transaction(
            id = id,
            userId = getString("userId").orEmpty(),
            description = getString("description").orEmpty(),
            amount = abs(amount),
            currencyCode = getString("currencyCode") ?: "USD",
            isIncome = isIncome,
            categoryId = getString("categoryId") ?: "",
            walletId = getString("walletId") ?: "",
            date = getTimestampField("date"),
            createdAt = getTimestampField("createdAt")
        )
    }
}

private fun Transaction.normalized(): Transaction {
    val normalizedAmount = abs(amount)
    return if (amount == normalizedAmount) this else copy(amount = normalizedAmount)
}

private fun Transaction.flowDelta(): Double {
    val value = abs(amount)
    return if (isIncome) value else -value
}
