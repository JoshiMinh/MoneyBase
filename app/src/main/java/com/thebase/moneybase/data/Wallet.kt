package com.thebase.moneybase.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "wallets")
data class Wallet(
    @PrimaryKey var id: String = "",
    var name: String = "",
    var type: WalletType = WalletType.OTHER,
    var currencyCode: String = "USD",
    var balance: Double = 0.0,
    var userId: String = "",
    var isSynced: Boolean = false,
    var isDeleted: Boolean = false,
    var iconName: String = "account_balance_wallet", // Default icon
    var color: String = "#6200EE", // Default color
    var isDefault: Boolean = false
) {
    enum class WalletType { PHYSICAL, BANK_ACCOUNT, CRYPTO, INVESTMENT, OTHER }
}