package com.glyanec.shop.data

data class ItemBasketModel(
    val id: Int,
    val title: String,
    val price: String,
    val image: String,
    var qty: Int
)

