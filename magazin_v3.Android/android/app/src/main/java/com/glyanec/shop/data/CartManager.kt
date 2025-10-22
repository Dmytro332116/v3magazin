package com.glyanec.shop.data

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class CartManager(context: Context) {
    
    private val prefs: SharedPreferences = 
        context.getSharedPreferences("cart_prefs", Context.MODE_PRIVATE)
    
    private val gson = Gson()
    
    fun getCartItems(): List<ItemBasketModel> {
        val json = prefs.getString(KEY_ITEMS, null) ?: return emptyList()
        val type = object : TypeToken<List<ItemBasketModel>>() {}.type
        return gson.fromJson(json, type) ?: emptyList()
    }
    
    fun saveCartItems(items: List<ItemBasketModel>) {
        val json = gson.toJson(items)
        prefs.edit().putString(KEY_ITEMS, json).apply()
    }
    
    fun addItem(item: ItemBasketModel) {
        val items = getCartItems().toMutableList()
        val existingIndex = items.indexOfFirst { it.id == item.id }
        
        if (existingIndex >= 0) {
            items[existingIndex] = items[existingIndex].copy(
                qty = items[existingIndex].qty + item.qty
            )
        } else {
            items.add(item)
        }
        
        saveCartItems(items)
    }
    
    fun removeItem(id: Int) {
        val items = getCartItems().filter { it.id != id }
        saveCartItems(items)
    }
    
    fun updateQuantity(id: Int, qty: Int) {
        val items = getCartItems().map { 
            if (it.id == id) it.copy(qty = qty) else it 
        }
        saveCartItems(items)
    }
    
    fun clearCart() {
        prefs.edit().remove(KEY_ITEMS).apply()
    }
    
    fun getTotalPrice(): Double {
        return getCartItems().sumOf { 
            (it.price.toDoubleOrNull() ?: 0.0) * it.qty 
        }
    }
    
    fun getTotalItemsCount(): Int {
        return getCartItems().sumOf { it.qty }
    }
    
    companion object {
        private const val KEY_ITEMS = "cart_items"
    }
}

