package com.thebase.moneybase.firebase

import com.google.firebase.Timestamp
import com.google.firebase.firestore.IgnoreExtraProperties

/**
 * Represents a financial transaction for a user.
 */
@IgnoreExtraProperties
data class Transaction(
    var id: String = "",
    var walletId: String = "",
    var description: String = "",
    var date: Timestamp = Timestamp.now(),
    var amount: Double = 0.0,
    var currencyCode: String = "USD",
    var isIncome: Boolean = false,
    var categoryId: String = "",
    var isSynced: Boolean = false,
    var createdAt: Timestamp = Timestamp.now(),
    var updatedAt: Timestamp = Timestamp.now()
)

/**
 * A user-defined category (e.g. “Groceries”, “Salary”).
 */
@IgnoreExtraProperties
data class Category(
    var id: String = "",
    var name: String = "",
    var iconName: String = "",
    var color: String = "#6200EE",
    var userId: String = "",
    var isSynced: Boolean = false,
    var isDeleted: Boolean = false
)

/**
 * Currency info for conversion/display.
 */
@IgnoreExtraProperties
data class Currency(
    var code: String = "USD",
    var symbol: String = "$",
    var name: String = "US Dollar",
    var usdValue: Double = 1.0
)

/**
 * A user wallet (cash, bank account, crypto, etc.).
 */
@IgnoreExtraProperties
data class Wallet(
    var id: String = "",
    var name: String = "",
    var type: WalletType = WalletType.OTHER,
    var currencyCode: String = "USD",
    var balance: Double = 0.0,
    var userId: String = "",
    var isSynced: Boolean = false,
    var isDeleted: Boolean = false,
    var iconName: String = "account_balance_wallet",
    var color: String = "#9C27B0"
) {
    enum class WalletType { PHYSICAL, BANK_ACCOUNT, CRYPTO, INVESTMENT, OTHER }
}