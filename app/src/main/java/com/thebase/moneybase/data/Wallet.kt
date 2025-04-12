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
    var iconName: String = "",
    var color: String = "",
    var isDefault: Boolean = false
) {
    enum class WalletType { PHYSICAL, BANK_ACCOUNT, CRYPTO, INVESTMENT, OTHER }
}