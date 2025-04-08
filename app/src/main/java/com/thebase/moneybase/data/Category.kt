package com.thebase.moneybase.data

import androidx.compose.ui.graphics.vector.ImageVector

data class Category(
    var id: String = "",
    val name: String = "",
    val icon: ImageVector,
    val color: String = "",
    val isDefault: Boolean = false,
    val userId: String = "",
    var isSynced: Boolean = false,
    val isDeleted: Boolean = false
) {
    fun toMap() = mapOf(
        "name" to name,
        "color" to color,
        "isDefault" to isDefault,
        "userId" to userId,
        "isSynced" to isSynced,
        "isDeleted" to isDeleted
    )
}