package com.thebase.moneybase.firebase

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.tasks.await
import javax.inject.Inject

/**
 * CRUD operations on /users/{userId}
 */
class UserRepository @Inject constructor() {
    private val db: FirebaseFirestore = Firebase.firestore

    /** Create or overwrite the user document. */
    suspend fun createUser(user: User) {
        db.collection("users")
            .document(user.id)
            .set(user)
            .await()
    }

    /** Fetches the user document or returns null if absent. */
    suspend fun getUser(userId: String): User? =
        db.collection("users")
            .document(userId)
            .get()
            .await()
            .toObject(User::class.java)
}

/**
 * Wallets under /users/{userId}/wallets
 */
class WalletRepository @Inject constructor() {
    private val db: FirebaseFirestore = Firebase.firestore

    /** Returns all non-deleted wallets for a user. */
    suspend fun getWallets(userId: String): List<Wallet> = try {
        db.collection("users")
            .document(userId)
            .collection("wallets")
            .whereEqualTo("isDeleted", false)
            .get()
            .await()
            .toObjects(Wallet::class.java)
    } catch (e: Exception) {
        emptyList()
    }

    /** Creates a new wallet or updates an existing one. */
    suspend fun saveWallet(userId: String, wallet: Wallet) {
        val ref = if (wallet.id.isBlank()) {
            db.collection("users")
                .document(userId)
                .collection("wallets")
                .document()
        } else {
            db.collection("users")
                .document(userId)
                .collection("wallets")
                .document(wallet.id)
        }

        wallet.id = ref.id
        ref.set(wallet).await()
    }

    /** Deletes the given wallet document. */
    suspend fun deleteWallet(userId: String, walletId: String) {
        db.collection("users")
            .document(userId)
            .collection("wallets")
            .document(walletId)
            .delete()
            .await()
    }
}

/**
 * Categories under /users/{userId}/categories
 */
class CategoryRepository @Inject constructor() {
    private val db: FirebaseFirestore = Firebase.firestore

    /** Returns all non-deleted categories for a user. */
    suspend fun getCategories(userId: String): List<Category> = try {
        db.collection("users")
            .document(userId)
            .collection("categories")
            .whereEqualTo("isDeleted", false)
            .get()
            .await()
            .toObjects(Category::class.java)
    } catch (e: Exception) {
        emptyList()
    }

    /** Creates a new category or updates an existing one. */
    suspend fun saveCategory(userId: String, category: Category) {
        val ref = if (category.id.isBlank()) {
            db.collection("users")
                .document(userId)
                .collection("categories")
                .document()
        } else {
            db.collection("users")
                .document(userId)
                .collection("categories")
                .document(category.id)
        }

        category.id = ref.id
        ref.set(category).await()
    }

    /** Deletes the given category document. */
    suspend fun deleteCategory(userId: String, categoryId: String) {
        db.collection("users")
            .document(userId)
            .collection("categories")
            .document(categoryId)
            .delete()
            .await()
    }
}

/**
 * Transactions under /users/{userId}/transactions
 */
class TransactionRepository @Inject constructor() {
    private val db: FirebaseFirestore = Firebase.firestore

    /**
     * Returns all transactions ordered by `createdAt` descending.
     * Make sure your Transaction model has a `createdAt` field in Firestore.
     */
    suspend fun getTransactions(userId: String): List<Transaction> = try {
        db.collection("users")
            .document(userId)
            .collection("transactions")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .get()
            .await()
            .toObjects(Transaction::class.java)
    } catch (e: Exception) {
        emptyList()
    }

    /** Creates a new transaction or updates an existing one. */
    suspend fun saveTransaction(userId: String, transaction: Transaction) {
        val ref = if (transaction.id.isBlank()) {
            db.collection("users")
                .document(userId)
                .collection("transactions")
                .document()
        } else {
            db.collection("users")
                .document(userId)
                .collection("transactions")
                .document(transaction.id)
        }

        transaction.id = ref.id
        ref.set(transaction).await()
    }

    /** Deletes the given transaction document. */
    suspend fun deleteTransaction(userId: String, transactionId: String) {
        db.collection("users")
            .document(userId)
            .collection("transactions")
            .document(transactionId)
            .delete()
            .await()
    }
}