package com.glyanec.shop

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.glyanec.shop.fragments.BasketFragment
import com.glyanec.shop.fragments.WebViewFragment
import com.google.android.material.bottomnavigation.BottomNavigationView

class MainActivity : AppCompatActivity() {
    
    private lateinit var bottomNavigation: BottomNavigationView
    private var currentFragment: Fragment? = null
    private var homeFragment: WebViewFragment? = null
    private var shopFragment: WebViewFragment? = null
    private var favoritesFragment: WebViewFragment? = null
    private var basketFragment: BasketFragment? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        bottomNavigation = findViewById(R.id.bottomNavigation)
        
        // Створюємо фрагменти
        homeFragment = WebViewFragment.newInstance("https://v3magazin.glyanec.net/")
        shopFragment = WebViewFragment.newInstance("https://v3magazin.glyanec.net/catalog/all")
        favoritesFragment = WebViewFragment.newInstance("https://v3magazin.glyanec.net/user/favorites")
        basketFragment = BasketFragment()
        
        // Встановлюємо початковий фрагмент
        if (savedInstanceState == null) {
            loadFragment(homeFragment!!)
            // Додаємо тестовий товар для перевірки кошика
            addTestProduct()
        }
        
        bottomNavigation.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.nav_home -> {
                    loadFragment(homeFragment!!)
                    true
                }
                R.id.nav_shop -> {
                    loadFragment(shopFragment!!)
                    true
                }
                R.id.nav_favorites -> {
                    loadFragment(favoritesFragment!!)
                    true
                }
                R.id.nav_basket -> {
                    // Перед відкриттям кошика синхронізуємо дані з WebView
                    syncCartFromWebView()
                    
                    // Затримка для синхронізації
                    Handler(Looper.getMainLooper()).postDelayed({
                        loadFragment(basketFragment!!)
                    }, 500)
                    true
                }
                else -> false
            }
        }
    }
    
    private fun syncCartFromWebView() {
        // Викликаємо синхронізацію на всіх WebView фрагментах
        homeFragment?.syncCart()
        shopFragment?.syncCart()
        favoritesFragment?.syncCart()
    }
    
    fun deleteCartItem(itemId: Int) {
        val javascript = """
        (function() {
            fetch('/basket/api-delete_item?_wrapper_format=drupal_ajax', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'delete_item=$itemId'
            })
            .then(response => response.json())
            .then(data => {
                console.log('✅ [Drupal] Item deleted:', data);
                
                if (typeof syncCartWithNative === 'function') {
                    setTimeout(syncCartWithNative, 500);
                }
            })
            .catch(err => {
                console.error('❌ [Drupal] Error deleting item:', err);
            });
        })();
        """
        
        homeFragment?.executeJavaScript(javascript)
        shopFragment?.executeJavaScript(javascript)
        favoritesFragment?.executeJavaScript(javascript)
    }
    
    fun updateCartQuantity(itemId: Int, quantity: Int) {
        val javascript = """
        (function() {
            fetch('/basket/api-change_count?_wrapper_format=drupal_ajax', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'update_id=$itemId&count=$quantity'
            })
            .then(response => response.json())
            .then(data => {
                console.log('✅ [Drupal] Quantity updated:', data);
                
                if (typeof syncCartWithNative === 'function') {
                    setTimeout(syncCartWithNative, 500);
                }
            })
            .catch(err => {
                console.error('❌ [Drupal] Error updating quantity:', err);
            });
        })();
        """
        
        homeFragment?.executeJavaScript(javascript)
        shopFragment?.executeJavaScript(javascript)
        favoritesFragment?.executeJavaScript(javascript)
    }
    
    private fun loadFragment(fragment: Fragment) {
        currentFragment = fragment
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragmentContainer, fragment)
            .commit()
    }
    
    private fun addTestProduct() {
        val cartManager = com.glyanec.shop.data.CartManager(this)
        val testItem = com.glyanec.shop.data.ItemBasketModel(
            id = 12345,
            title = "Спортивний костюм Nike Sportswear",
            price = "2000",
            image = "https://v3magazin.glyanec.net/sites/default/files/styles/product_card/public/product/2023-09/12_1.jpg",
            qty = 1
        )
        cartManager.addItem(testItem)
    }
    
    override fun onBackPressed() {
        // Якщо це WebViewFragment і можна повернутись назад у WebView
        if (currentFragment is WebViewFragment) {
            val webViewFragment = currentFragment as WebViewFragment
            if (webViewFragment.canGoBack()) {
                webViewFragment.goBack()
                return
            }
        }
        
        // Інакше стандартна поведінка
        super.onBackPressed()
    }
}
