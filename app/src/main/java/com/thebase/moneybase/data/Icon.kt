package com.thebase.moneybase.data

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.vector.ImageVector

object Icon {

    val iconMap: Map<String, ImageVector> = mapOf(
        "fastfood" to Icons.Default.Fastfood,
        "directions_car" to Icons.Default.DirectionsCar,
        "shopping_cart" to Icons.Default.ShoppingCart,
        "receipt" to Icons.Default.Receipt,
        "local_activity" to Icons.Default.LocalActivity,
        "more_horiz" to Icons.Default.MoreHoriz,
        "account_balance_wallet" to Icons.Default.AccountBalanceWallet,
        "account_balance" to Icons.Default.AccountBalance,
        "currency_bitcoin" to Icons.Default.AttachMoney,

        // 10 new ones
        "flight" to Icons.Default.Flight,
        "home" to Icons.Default.Home,
        "phone_android" to Icons.Default.PhoneAndroid,
        "savings" to Icons.Default.Savings,
        "subscriptions" to Icons.Default.Subscriptions,
        "medical_services" to Icons.Default.MedicalServices,
        "sports_soccer" to Icons.Default.SportsSoccer,
        "local_cafe" to Icons.Default.LocalCafe,
        "directions_bus" to Icons.Default.DirectionsBus,
        "emoji_events" to Icons.Default.EmojiEvents
    )

    fun getIcon(iconName: String): ImageVector {
        return iconMap[iconName] ?: Icons.Default.Category
    }
}