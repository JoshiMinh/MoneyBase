package com.thebase.moneybase.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.Instant

@Entity(tableName = "transactions")
data class Transaction(
    @PrimaryKey var id: String = "",
    var walletId: String = "",
    var description: String = "",
    var date: String = "",
    var amount: Double = 0.0,
    var currencyCode: String = "USD",
    var isIncome: Boolean = false,
    var categoryId: String = "",
    var userId: String = "",
    var isSynced: Boolean = false,
    var createdAt: Instant = Instant.now(),
    var updatedAt: Instant = Instant.now()
)