package com.thebase.moneybase.functionalities.customizability

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.DirectionsBus
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Fastfood
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocalActivity
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Subscriptions
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