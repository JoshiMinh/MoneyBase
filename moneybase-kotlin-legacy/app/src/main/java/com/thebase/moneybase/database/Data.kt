package com.thebase.moneybase.database

import androidx.annotation.Keep
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId

@Keep
data class User(
    @DocumentId val id: String = "",
    val displayName: String = "",
    val email: String = "",
    val createdAt: Timestamp = Timestamp.now(),
    val lastLoginAt: Timestamp = Timestamp.now(),
    val premium: Boolean = false,
    val profilePictureUrl: String = "",
    val photoUrl: String? = null
)

@Suppress("unused")
@Keep
data class Currency(
    val code: String = "USD",
    val symbol: String = "$",
    val name: String = "US Dollar",
    val usdValue: Double = 1.0
)

@Keep
data class Category(
    val id: String = "",
    val userId: String = "",
    val name: String = "",
    val iconName: String = "",
    val color: String = "",
    val parentCategoryId: String? = null
)

@Keep
data class Wallet(
    @DocumentId val id: String = "",
    val userId: String = "",
    val name: String = "",
    val balance: Double = 0.0,
    val iconName: String = "account_balance_wallet",
    val color: String = "",
    val type: WalletType = WalletType.PHYSICAL,
    val currencyCode: String = "USD",
    val position: Long = 0
) {
    enum class WalletType { PHYSICAL, BANK_ACCOUNT, CRYPTO, INVESTMENT, OTHER }
}

@Keep
data class Transaction(
    @DocumentId val id: String = "",
    val userId: String = "",
    val description: String = "",
    val amount: Double = 0.0,
    val currencyCode: String = "USD",
    val isIncome: Boolean = false,
    val categoryId: String = "",
    val walletId: String = "",
    val date: Timestamp = Timestamp.now(),
    val createdAt: Timestamp = Timestamp.now()
)