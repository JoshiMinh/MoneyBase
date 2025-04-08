package com.thebase.moneybase.data

import java.time.Instant

data class Transaction(
    var id: String = "",
    val description: String = "",
    val date: String = "",
    val amount: Double = 0.0,
    val currencyCode: String = "USD",
    val isIncome: Boolean = false,
    val categoryId: String = "",
    val userId: String = "",
    var isSynced: Boolean = false,
    val createdAt: Instant = Instant.now(),
    val updatedAt: Instant = Instant.now()
) {
    fun toMap() = mapOf(
        "description" to description,
        "date" to date,
        "amount" to amount,
        "currencyCode" to currencyCode,
        "isIncome" to isIncome,
        "categoryId" to categoryId,
        "userId" to userId,
        "isSynced" to isSynced,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt
    )
}