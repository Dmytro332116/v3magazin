package com.glyanec.shop.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.glyanec.shop.MainActivity
import com.glyanec.shop.R
import com.glyanec.shop.data.CartManager
import com.glyanec.shop.data.ItemBasketModel

class BasketFragment : Fragment() {
    
    private lateinit var cartManager: CartManager
    private lateinit var recyclerView: RecyclerView
    private lateinit var emptyTextView: TextView
    private lateinit var totalPriceTextView: TextView
    private lateinit var checkoutButton: Button
    private lateinit var adapter: BasketAdapter
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_basket, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        cartManager = CartManager(requireContext())
        
        recyclerView = view.findViewById(R.id.recyclerView)
        emptyTextView = view.findViewById(R.id.emptyTextView)
        totalPriceTextView = view.findViewById(R.id.totalPriceTextView)
        checkoutButton = view.findViewById(R.id.checkoutButton)
        
        setupRecyclerView()
        updateUI()
        
        checkoutButton.setOnClickListener {
            android.util.Log.d("BasketFragment", "🛒 Checkout button clicked!")
            val items = cartManager.getCartItems()
            android.util.Log.d("BasketFragment", "📦 Items count: ${items.size}")
            
            if (items.isEmpty()) {
                // Показуємо повідомлення що кошик порожній
                android.util.Log.d("BasketFragment", "⚠️ Cart is empty")
                android.widget.Toast.makeText(
                    requireContext(),
                    "Кошик порожній. Додайте товари перед оформленням замовлення.",
                    android.widget.Toast.LENGTH_SHORT
                ).show()
            } else {
                // Відкриваємо WebView з оформленням замовлення
                android.util.Log.d("BasketFragment", "✅ Opening order page...")
                openOrderPage()
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Оновлюємо UI при поверненні на вкладку
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            updateUI()
        }, 100)
    }
    
    private fun setupRecyclerView() {
        adapter = BasketAdapter(
            onQuantityChanged = { item, newQty ->
                cartManager.updateQuantity(item.id, newQty)
                updateUI()
                // Оновлюємо в WebView через Drupal API
                updateQuantityInWebView(item.id, newQty)
            },
            onItemDeleted = { item ->
                cartManager.removeItem(item.id)
                updateUI()
                // Видаляємо з WebView через Drupal API
                deleteItemFromWebView(item.id)
            }
        )
        
        recyclerView.layoutManager = LinearLayoutManager(requireContext())
        recyclerView.adapter = adapter
    }
    
    private fun updateUI() {
        val items = cartManager.getCartItems()
        
        if (items.isEmpty()) {
            recyclerView.visibility = View.GONE
            emptyTextView.visibility = View.VISIBLE
            checkoutButton.isEnabled = false
        } else {
            recyclerView.visibility = View.VISIBLE
            emptyTextView.visibility = View.GONE
            checkoutButton.isEnabled = true
        }
        
        adapter.submitList(items)
        
        val totalPrice = cartManager.getTotalPrice()
        totalPriceTextView.text = "${totalPrice.toInt()} грн"
        
        // Оновлюємо текст кнопки з сумою як в iOS
        checkoutButton.text = "Оформити ${totalPrice.toInt()} ₴"
    }
    
    private fun deleteItemFromWebView(itemId: Int) {
        // Викликаємо функцію видалення через MainActivity
        (activity as? MainActivity)?.deleteCartItem(itemId)
    }
    
    private fun updateQuantityInWebView(itemId: Int, quantity: Int) {
        // Викликаємо функцію оновлення через MainActivity
        (activity as? MainActivity)?.updateCartQuantity(itemId, quantity)
    }
    
    private fun openOrderPage() {
        // Створюємо WebViewFragment з URL оформлення замовлення
        val orderWebViewFragment = WebViewFragment.newInstance("https://v3magazin.glyanec.net/basket/order")
        
        // Відкриваємо його замінивши поточний фрагмент
        parentFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, orderWebViewFragment)
            .addToBackStack(null) // Додаємо в back stack щоб можна було повернутися
            .commit()
    }
}

