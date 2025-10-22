package com.glyanec.shop.fragments

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.fragment.app.Fragment
import com.glyanec.shop.data.CartManager
import com.glyanec.shop.data.ItemBasketModel
import org.json.JSONArray
import org.json.JSONObject

class WebViewFragment : Fragment() {
    
    private lateinit var webView: WebView
    private lateinit var cartManager: CartManager
    
    companion object {
        private const val TAG = "WebViewFragment"
        private const val ARG_URL = "url"
        
        fun newInstance(url: String): WebViewFragment {
            return WebViewFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_URL, url)
                }
            }
        }
    }
    
    private fun getUrl(): String {
        return requireArguments().getString(ARG_URL)!!
    }
    
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        cartManager = CartManager(requireContext())
        val urlToLoad = getUrl()
        
        webView = WebView(requireContext()).apply {
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                databaseEnabled = true
                setSupportZoom(true)
                builtInZoomControls = true
                displayZoomControls = false
                useWideViewPort = true
                loadWithOverviewMode = true
            }
            
            // Додаємо JavaScript Interface
            addJavascriptInterface(CartJavascriptInterface(), "cartHandler")
            
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    // Інжектуємо JavaScript після завантаження сторінки
                    injectCartSyncScript()
                }
            }
            
            webChromeClient = WebChromeClient()
            
            // Завантажуємо URL
            loadUrl(urlToLoad)
        }
        
        return webView
    }
    
    private fun injectCartSyncScript() {
        val javascript = """
        console.log('🔧 [Drupal Cart Integration] Starting...');
        
        // ✅ 1. Перехоплення XMLHttpRequest (Drupal використовує jQuery AJAX)
        (function() {
            const originalOpen = XMLHttpRequest.prototype.open;
            const originalSend = XMLHttpRequest.prototype.send;
            
            XMLHttpRequest.prototype.open = function(method, url) {
                this._url = url;
                this._method = method;
                return originalOpen.apply(this, arguments);
            };
            
            XMLHttpRequest.prototype.send = function(data) {
                const xhr = this;
                
                xhr.addEventListener('load', function() {
                    if (xhr._url && (xhr._url.includes('/basket/api-add') || xhr._url.includes('/basket/api-load_popup'))) {
                        console.log('🛒 [Drupal Cart] API call detected:', xhr._url);
                        
                        try {
                            const responseData = JSON.parse(xhr.responseText);
                            
                            if (window.cartHandler) {
                                window.cartHandler.onCartDataReceived(JSON.stringify({
                                    type: 'xhr_call',
                                    url: xhr._url,
                                    method: xhr._method,
                                    data: responseData
                                }));
                            }
                        } catch (e) {
                            console.error('Error parsing XHR response:', e);
                        }
                    }
                });
                
                return originalSend.apply(this, arguments);
            };
        })();
        
        // ✅ 2. Перехоплення кліків на кнопку "Додати в кошик"
        function setupDrupalCartHandler() {
            console.log('🔍 [Drupal] Searching for .addto_basket_button...');
            
            const buttons = document.querySelectorAll('.addto_basket_button, a[onclick*="basket_ajax_link"]');
            
            console.log('✅ [Drupal] Found ' + buttons.length + ' cart buttons');
            
            buttons.forEach(function(button) {
                if (!button.dataset.nativeHandlerAttached) {
                    button.dataset.nativeHandlerAttached = 'true';
                    
                    button.addEventListener('click', function(event) {
                        console.log('🖱️ [Drupal] Cart button clicked');
                        
                        // Чекаємо, поки Drupal оновить кошик, і синхронізуємо
                        setTimeout(() => {
                            syncCartWithNative();
                        }, 800);
                    }, false);
                }
            });
        }
        
        // ✅ 3. Синхронізація кошика - викликає Drupal API напряму
        function syncCartWithNative() {
            console.log('🔄 [Drupal] Syncing cart with native app...');
            
            // Викликаємо Drupal endpoint для отримання кошика
            fetch('/basket/api-load_popup?_wrapper_format=drupal_ajax', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'load_popup=basket_view'
            })
            .then(response => response.json())
            .then(data => {
                console.log('✅ [Drupal] Cart data received from API');
                
                if (window.cartHandler) {
                    window.cartHandler.onCartDataReceived(JSON.stringify({
                        type: 'drupal_cart_sync',
                        data: data
                    }));
                }
            })
            .catch(err => {
                console.error('❌ [Drupal] Error syncing cart:', err);
            });
        }
        
        // ✅ 4. Експортуємо функцію для виклику з нативного коду
        window.syncCartWithNative = syncCartWithNative;
        
        // Запускаємо обробники
        setupDrupalCartHandler();
        
        // Спостерігаємо за змінами DOM (для динамічно доданих кнопок)
        const observer = new MutationObserver(() => {
            setupDrupalCartHandler();
        });
        observer.observe(document.body, { childList: true, subtree: true });
        
        // Синхронізуємо кошик при завантаженні сторінки
        setTimeout(syncCartWithNative, 1500);
        
        console.log('✅ [Drupal Cart Integration] Completed');
        """
        
        webView.evaluateJavascript(javascript) { result ->
            Log.d(TAG, "✅ JavaScript injected successfully")
        }
    }
    
    fun syncCart() {
        // Перевіряємо чи WebView вже ініціалізований
        if (!::webView.isInitialized) {
            Log.d(TAG, "⚠️ WebView not initialized yet, skipping sync")
            return
        }
        
        webView.evaluateJavascript("if (typeof syncCartWithNative === 'function') { syncCartWithNative(); }") { 
            Log.d(TAG, "🔄 Cart sync triggered")
        }
    }
    
    inner class CartJavascriptInterface {
        @JavascriptInterface
        fun onCartDataReceived(jsonData: String) {
            Log.d(TAG, "📨 Received cart data from JavaScript")
            
            try {
                val json = JSONObject(jsonData)
                val type = json.optString("type")
                
                Log.d(TAG, "📋 Message type: $type")
                
                when (type) {
                    "drupal_cart_sync", "xhr_call" -> {
                        handleDrupalCartSync(json)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error parsing cart data", e)
            }
        }
        
        private fun handleDrupalCartSync(json: JSONObject) {
            Log.d(TAG, "🔄 Handling Drupal cart sync...")
            
            try {
                val dataObj = json.optJSONObject("data")
                val commands = dataObj?.optJSONArray("commands") ?: 
                              json.optJSONArray("data") ?: return
                
                Log.d(TAG, "📦 Processing ${commands.length()} Drupal commands")
                
                // Шукаємо magnificPopup з HTML кошика
                for (i in 0 until commands.length()) {
                    val command = commands.getJSONObject(i)
                    val commandType = command.optString("command")
                    
                    Log.d(TAG, "🔧 Command: $commandType")
                    
                    if (commandType == "magnificPopup") {
                        val html = command.optString("html")
                        if (html.isNotEmpty()) {
                            Log.d(TAG, "🎪 Found cart HTML in magnificPopup")
                            parseCartHTML(html)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error handling cart sync", e)
            }
        }
        
        private fun parseCartHTML(html: String) {
            Log.d(TAG, "📄 Parsing Drupal cart HTML...")
            Log.d(TAG, "📄 HTML length: ${html.length} characters")
            
            val items = mutableListOf<ItemBasketModel>()
            
            // Regex для пошуку блоків товарів
            val rowPattern = """<div class="goods-cart-row">[\s\S]*?(?=<div class="goods-cart-row">|<div class="view-footer">|$)""".toRegex()
            val matches = rowPattern.findAll(html)
            
            matches.forEachIndexed { index, match ->
                val rowHTML = match.value
                Log.d(TAG, "📦 Processing item ${index + 1}...")
                
                try {
                    // 1. ID товару
                    val idPattern = """(?:&quot;delete_item&quot;:&quot;(\d+)&quot;|&quot;update_id&quot;:&quot;(\d+)&quot;|"delete_item":"(\d+)"|"update_id":"(\d+)")""".toRegex()
                    val idMatch = idPattern.find(rowHTML)
                    val id = (idMatch?.groups?.firstOrNull { it != null && it.value.toIntOrNull() != null }?.value?.toIntOrNull()
                        ?: index + 1000)
                    
                    // 2. Назва товару
                    val titlePattern = """goods-cart-row__title[^>]*>[\s\S]*?<a[^>]*>(.*?)</a>""".toRegex()
                    val title = titlePattern.find(rowHTML)?.groups?.get(1)?.value?.trim() ?: "Товар #$id"
                    
                    // 3. Ціна
                    val pricePattern = """<div class="sum">\s*([0-9 ]+)\s*грн""".toRegex()
                    val price = pricePattern.find(rowHTML)?.groups?.get(1)?.value?.replace(" ", "") ?: "0"
                    
                    // 4. Зображення
                    val imagePattern = """<img[^>]*src="([^"]+)"""".toRegex()
                    var image = imagePattern.find(rowHTML)?.groups?.get(1)?.value ?: ""
                    if (image.startsWith("/")) {
                        image = "https://v3magazin.glyanec.net$image"
                    }
                    
                    // 5. Кількість
                    val qtyPattern = """<input[^>]*class="count_input"[^>]*value="(\d+)"""".toRegex()
                    val qty = qtyPattern.find(rowHTML)?.groups?.get(1)?.value?.toIntOrNull() ?: 1
                    
                    val item = ItemBasketModel(
                        id = id,
                        title = title,
                        price = price,
                        image = image,
                        qty = qty
                    )
                    
                    items.add(item)
                    Log.d(TAG, "✅ Item ${index + 1} parsed: $title x$qty (id: $id)")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error parsing item ${index + 1}", e)
                }
            }
            
            // Зберігаємо в CartManager
            activity?.runOnUiThread {
                Log.d(TAG, "🔄 Replacing cart with ${items.size} items")
                cartManager.saveCartItems(items)
                Log.d(TAG, "✅ Cart saved successfully")
            }
        }
    }
    
    fun canGoBack(): Boolean {
        return if (::webView.isInitialized) webView.canGoBack() else false
    }
    
    fun goBack() {
        if (::webView.isInitialized) {
            webView.goBack()
        }
    }
    
    fun executeJavaScript(script: String) {
        if (!::webView.isInitialized) {
            Log.d(TAG, "⚠️ WebView not initialized yet, skipping JavaScript execution")
            return
        }
        
        webView.evaluateJavascript(script) { result ->
            Log.d(TAG, "JavaScript executed")
        }
    }
}
