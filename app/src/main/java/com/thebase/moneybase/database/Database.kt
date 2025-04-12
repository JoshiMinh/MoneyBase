package com.thebase.moneybase.database

import android.content.Context
import androidx.room.*
import androidx.sqlite.db.SupportSQLiteDatabase
import com.thebase.moneybase.data.Category
import com.thebase.moneybase.data.Wallet
import com.thebase.moneybase.data.Transaction
import java.time.Instant
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

// Type converter for Instant to Long (epoch millis) and vice versa.
class Converters {
    @TypeConverter
    fun fromInstant(instant: Instant?): Long? = instant?.toEpochMilli()

    @TypeConverter
    fun toInstant(millis: Long?): Instant? = millis?.let { Instant.ofEpochMilli(it) }
}

@Database(
    entities = [Category::class, Wallet::class, Transaction::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun categoryDao(): CategoryDao
    abstract fun walletDao(): WalletDao
    abstract fun transactionDao(): TransactionDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context, userId: String): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "moneybase.db" // Database file name
                )
                    .addCallback(SeedDatabaseCallback(context, userId))
                    .build()
                INSTANCE = instance
                instance
            }
        }
    }

    private class SeedDatabaseCallback(
        private val context: Context,
        private val userId: String
    ) : RoomDatabase.Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            // Seed default data in a background thread
            CoroutineScope(Dispatchers.IO).launch {
                // Retrieve the instance that was just created
                val database = getInstance(context, userId)
                val categoryDao = database.categoryDao()
                val walletDao = database.walletDao()

                // 6 Default Categories
                val defaultCategories = listOf(
                    Category("cat1", "Food", "fastfood", "#FF5733", true, userId),
                    Category("cat2", "Transport", "directions_car", "#33A5FF", true, userId),
                    Category("cat3", "Shopping", "shopping_cart", "#FF33E9", true, userId),
                    Category("cat4", "Bills", "receipt", "#33FF57", true, userId),
                    Category("cat5", "Entertainment", "local_activity", "#E933FF", true, userId),
                    Category("cat6", "Other", "more_horiz", "#808080", true, userId)
                )

                // 3 Default Wallets
                val defaultWallets = listOf(
                    Wallet("wallet1", "Cash", Wallet.WalletType.PHYSICAL, "USD", 0.0, userId, false, false, "account_balance_wallet", "#4CAF50", true),
                    Wallet("wallet2", "Bank Account", Wallet.WalletType.BANK_ACCOUNT, "USD", 0.0, userId, false, false, "account_balance", "#2196F3", false),
                    Wallet("wallet3", "Crypto Wallet", Wallet.WalletType.CRYPTO, "BTC", 0.0, userId, false, false, "currency_bitcoin", "#FF9800", false)
                )

                defaultCategories.forEach { categoryDao.insert(it) }
                defaultWallets.forEach { walletDao.insert(it) }
            }
        }
    }
}