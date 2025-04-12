package com.thebase.moneybase.database

import androidx.room.*
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Transaction
import com.thebase.moneybase.data.Wallet

@Dao
interface CategoryDao {
    @Insert
    suspend fun insert(category: Category)

    @Update
    suspend fun update(category: Category)

    @Delete
    suspend fun delete(category: Category)

    @Query("SELECT * FROM categories WHERE userId = :userId AND isDeleted = 0")
    suspend fun getCategoriesByUser(userId: String): List<Category>
}

@Dao
interface WalletDao {
    @Insert
    suspend fun insert(wallet: Wallet)

    @Update
    suspend fun update(wallet: Wallet)

    @Delete
    suspend fun delete(wallet: Wallet)

    @Query("SELECT * FROM wallets WHERE userId = :userId AND isDeleted = 0")
    suspend fun getWalletsByUser(userId: String): List<Wallet>
}

@Dao
interface TransactionDao {
    @Insert
    suspend fun insert(transaction: Transaction)

    @Update
    suspend fun update(transaction: Transaction)

    @Delete
    suspend fun delete(transaction: Transaction)

    @Query("SELECT * FROM transactions WHERE userId = :userId ORDER BY createdAt DESC LIMIT 10")
    suspend fun getTop5Transactions(userId: String): List<Transaction>
}