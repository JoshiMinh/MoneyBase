package com.thebase.moneybase.data

import androidx.compose.ui.graphics.vector.ImageVector

data class Wallet(
    var id: String = "",
    val name: String,
    val type: WalletType,
    val currencyCode: String,
    val balance: Double,
    val userId: String = "",
    val isSynced: Boolean = false,
    val isDeleted: Boolean = false,
    val icon: ImageVector,
    val color: String
) {
    enum class WalletType {
        PHYSICAL, BANK_ACCOUNT, CRYPTO, INVESTMENT, OTHER
    }

    fun toMap() = mapOf(
        "name" to name,
        "type" to type.name,
        "currencyCode" to currencyCode,
        "balance" to balance,
        "userId" to userId,
        "isSynced" to isSynced,
        "isDeleted" to isDeleted
    )
}