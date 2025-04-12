package com.thebase.moneybase.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "categories")
data class Category(
    @PrimaryKey var id: String = "",
    var name: String = "",
    var iconName: String = "",
    var color: String = "",
    var isDefault: Boolean = false,
    var userId: String = "",
    var isSynced: Boolean = false,
    var isDeleted: Boolean = false
)