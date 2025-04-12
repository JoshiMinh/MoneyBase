package com.thebase.moneybase.data

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.vector.ImageVector

object Icon {
    fun getIcon(iconName: String): ImageVector {
        return when (iconName) {
            "fastfood" -> Icons.Default.Fastfood
            "directions_car" -> Icons.Default.DirectionsCar
            "shopping_cart" -> Icons.Default.ShoppingCart
            "receipt" -> Icons.Default.Receipt
            "local_activity" -> Icons.Default.LocalActivity
            "more_horiz" -> Icons.Default.MoreHoriz
            "account_balance_wallet" -> Icons.Default.AccountBalanceWallet
            "account_balance" -> Icons.Default.AccountBalance
            "currency_bitcoin" -> Icons.Default.AttachMoney
            else -> Icons.Default.ShoppingCart // default icon
        }
    }
}