package com.thebase.moneybase.data

data class Currency(
    var code: String = "USD",
    var symbol: String = "$",
    var name: String = "US Dollar",
    var usdValue: Double = 1.0
)