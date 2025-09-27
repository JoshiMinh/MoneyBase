package com.thebase.moneybase.database.extensions

import com.google.firebase.firestore.DocumentSnapshot
import com.thebase.moneybase.database.Category
import com.thebase.moneybase.database.Transaction
import com.thebase.moneybase.database.Wallet
import java.util.Locale

fun List<Wallet>.sortedForDisplay(): List<Wallet> {
    return sortedWith(
        compareBy<Wallet> { it.position }
            .thenBy { it.name.lowercase(Locale.getDefault()) }
    )
}

fun DocumentSnapshot.toWalletOrNull(): Wallet? {
    val payload = data ?: return null
    val userId = (payload["userId"] as? String)
        ?.takeIf { it.isNotBlank() }
        ?: reference?.parent?.parent?.id.orEmpty()
    val typeRaw = payload["type"] as? String
    val type = typeRaw?.let { raw ->
        Wallet.WalletType.values().firstOrNull { it.name.equals(raw, ignoreCase = true) }
    } ?: Wallet.WalletType.PHYSICAL
    val balance = (payload["balance"] as? Number)?.toDouble() ?: 0.0
    val position = (payload["position"] as? Number)?.toLong() ?: 0L
    return Wallet(
        id = id,
        userId = userId,
        name = (payload["name"] as? String).orEmpty(),
        balance = balance,
        iconName = (payload["iconName"] as? String) ?: "account_balance_wallet",
        color = (payload["color"] as? String).orEmpty(),
        type = type,
        currencyCode = (payload["currencyCode"] as? String) ?: "USD",
        position = position
    )
}

fun DocumentSnapshot.toCategoryOrNull(): Category? {
    val payload = data ?: return null

    val userId = (payload["userId"] as? String)
        ?.takeIf { it.isNotBlank() }
        ?: reference?.parent?.parent?.id.orEmpty()

    val parentCategoryId = (payload["parentCategoryId"] as? String)
        ?.takeIf { it.isNotBlank() }

    return Category(
        id = id,
        userId = userId,
        name = (payload["name"] as? String).orEmpty(),
        iconName = (payload["iconName"] as? String).orEmpty(),
        color = (payload["color"] as? String).orEmpty(),
        parentCategoryId = parentCategoryId
    )
}

fun Category.toFirestoreMap(userIdOverride: String? = null): Map<String, Any?> {
    val resolvedUserId = when {
        !userIdOverride.isNullOrBlank() -> userIdOverride
        userId.isNotBlank() -> userId
        else -> ""
    }

    return mapOf(
        "userId" to resolvedUserId,
        "name" to name,
        "iconName" to iconName,
        "color" to color,
        "parentCategoryId" to parentCategoryId
    )
}

fun Wallet.toFirestoreMap(
    userIdOverride: String? = null,
    positionOverride: Long? = null
): Map<String, Any?> {
    val resolvedUserId = when {
        !userIdOverride.isNullOrBlank() -> userIdOverride
        userId.isNotBlank() -> userId
        else -> ""
    }
    val resolvedPosition = positionOverride ?: position

    return mapOf(
        "userId" to resolvedUserId,
        "name" to name,
        "balance" to balance,
        "iconName" to iconName,
        "color" to color,
        "type" to type.name,
        "currencyCode" to currencyCode,
        "position" to resolvedPosition
    )
}

fun Transaction.toFirestoreMap(userIdOverride: String? = null): Map<String, Any?> {
    val resolvedUserId = when {
        !userIdOverride.isNullOrBlank() -> userIdOverride
        userId.isNotBlank() -> userId
        else -> ""
    }

    return mapOf(
        "userId" to resolvedUserId,
        "description" to description,
        "amount" to amount,
        "currencyCode" to currencyCode,
        "isIncome" to isIncome,
        "categoryId" to categoryId,
        "walletId" to walletId,
        "date" to date,
        "createdAt" to createdAt
    )
}
