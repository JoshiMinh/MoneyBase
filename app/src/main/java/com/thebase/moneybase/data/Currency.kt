package com.thebase.moneybase.data

data class Currency(
    val code: String, // e.g. "USD", "JPY", "EUR"
    val symbol: String, // e.g. "$", "¥", "€"
    val name: String // e.g. "US Dollar", "Japanese Yen"
)