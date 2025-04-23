package com.thebase.moneybase.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "wallets")
data class Wallet(
    @PrimaryKey(autoGenerate = false)
    var id: String = UUID.randomUUID().toString(),
    var name: String = "",
    var type: WalletType = WalletType.OTHER,
    var currencyCode: String = "USD",
    var balance: Double = 0.0,
    var userId: String = "",
    var isSynced: Boolean = false,
    var isDeleted: Boolean = false,
    var iconName: String = "account_balance_wallet", // Default icon
    var color: String = "#9C27B0", // Matches "purple" in ColorPalette
    var isDefault: Boolean = false
) {
    enum class WalletType { PHYSICAL, BANK_ACCOUNT, CRYPTO, INVESTMENT, OTHER }
}