import UIKit
import WebKit

// ✅ Спільний process pool для всіх WebView (щоб cookies були спільні)
class WebViewProcessPool {
    static let shared = WKProcessPool()
}

class WebStoreViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    var webView: WKWebView!
    var urlString: String?
    private var isInitialLoad = true  // ✅ Прапорець для початкового завантаження
    private var progressView: UIProgressView!  // ✅ Progress bar

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupProgressBar()
        setupNavigationBar()
        loadStore()
        
        // Підписуємося на подію запиту кошика з інших контролерів
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncCartFromWebView),
            name: NSNotification.Name("RequestCartSync"),
            object: nil
        )
        
        // Підписуємося на подію видалення товару
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeleteCartItem(_:)),
            name: NSNotification.Name("DeleteCartItem"),
            object: nil
        )
        
        // Підписуємося на подію оновлення кількості
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdateQuantity(_:)),
            name: NSNotification.Name("UpdateCartQuantity"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ ВАЖЛИВО: Фіксуємо колір навігації (завжди чорний)
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.isHidden = false
    }
    
    deinit {
        // Видаляємо observer для progress
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Cart Sync
    
    @objc func syncCartFromWebView() {
        print("🔄 [Swift] Syncing cart from WebView...")
        
        // Викликаємо нову Drupal-специфічну функцію
        let javascript = "if (typeof syncCartWithNative === 'function') { syncCartWithNative(); }"
        webView.evaluateJavaScript(javascript) { (result, error) in
            if let error = error {
                print("❌ [Swift] Error syncing cart: \(error)")
            } else {
                print("✅ [Swift] Cart sync triggered")
            }
        }
    }
    
    @objc func handleDeleteCartItem(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let itemId = userInfo["itemId"] as? Int else {
            print("⚠️ [Swift] Invalid item ID for deletion")
            return
        }
        
        print("🗑️ [Swift] Deleting item from Drupal: id=\(itemId)")
        
        // Викликаємо Drupal API для видалення товару
        // ✅ Обгортаємо в IIFE, щоб повернути undefined замість Promise
        let javascript = """
        (function() {
            fetch('/basket/api-delete_item?_wrapper_format=drupal_ajax', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'delete_item=\(itemId)'
            })
            .then(response => response.json())
            .then(data => {
                console.log('✅ [Drupal] Item deleted:', data);
                
                // Синхронізуємо кошик після видалення
                if (typeof syncCartWithNative === 'function') {
                    setTimeout(syncCartWithNative, 500);
                }
            })
            .catch(err => {
                console.error('❌ [Drupal] Error deleting item:', err);
            });
        })();
        """
        
        webView.evaluateJavaScript(javascript) { (result, error) in
            if let error = error {
                print("❌ [Swift] Error executing delete: \(error)")
            } else {
                print("✅ [Swift] Delete request sent to Drupal")
            }
        }
    }
    
    @objc func handleUpdateQuantity(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let itemId = userInfo["itemId"] as? Int,
              let quantity = userInfo["quantity"] as? Int else {
            print("⚠️ [Swift] Invalid data for quantity update")
            return
        }
        
        print("🔄 [Swift] Updating quantity in Drupal: id=\(itemId), qty=\(quantity)")
        
        // Викликаємо Drupal API для оновлення кількості
        // ✅ Обгортаємо в IIFE, щоб повернути undefined замість Promise
        let javascript = """
        (function() {
            fetch('/basket/api-change_count?_wrapper_format=drupal_ajax', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'update_id=\(itemId)&count=\(quantity)'
            })
            .then(response => response.json())
            .then(data => {
                console.log('✅ [Drupal] Quantity updated:', data);
                
                // Синхронізуємо кошик після оновлення
                if (typeof syncCartWithNative === 'function') {
                    setTimeout(syncCartWithNative, 500);
                }
            })
            .catch(err => {
                console.error('❌ [Drupal] Error updating quantity:', err);
            });
        })();
        """
        
        webView.evaluateJavaScript(javascript) { (result, error) in
            if let error = error {
                print("❌ [Swift] Error executing update: \(error)")
            } else {
                print("✅ [Swift] Update request sent to Drupal")
            }
        }
    }

    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "cartHandler")
        webConfiguration.userContentController = userContentController
        
        // ✅ Використовуємо shared data store для збереження cookies між вкладками
        webConfiguration.websiteDataStore = .default()
        webConfiguration.processPool = WebViewProcessPool.shared
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // ✅ Дозволяємо cookies та JavaScript
        webView.configuration.preferences.javaScriptEnabled = true
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func loadStore() {
        let targetUrl = urlString ?? "https://v3magazin.glyanec.net/"
        print("🌐 [WebStoreVC] Loading URL: \(targetUrl)")
        if let url = URL(string: targetUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // MARK: - UI Setup
    
    private func setupProgressBar() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = UIColor.systemGreen
        progressView.trackTintColor = UIColor.systemGray5
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        // Спостерігаємо за прогресом завантаження
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    private func setupNavigationBar() {
        // Додаємо кнопку "Назад" ← як у Safari
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // Показуємо navigation bar
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc private func goBack() {
        print("🔙 [WebStoreVC] Back button tapped")
        if webView.canGoBack {
            print("   ↩️ WebView can go back - navigating")
            webView.goBack()
        } else {
            print("   ← Popping view controller")
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Progress Observer
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = progressView.progress >= 1.0
        }
    }

    // MARK: - WKNavigationDelegate
    
    // ✅ Перехоплюємо навігацію до кошика/favorites, щоб відкрити в додатку
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // ✅ ВАЖЛИВО: Дозволяємо початкове завантаження сторінки
        if isInitialLoad {
            print("🌐 [WebStoreVC] Initial load - allowing navigation")
            isInitialLoad = false
            decisionHandler(.allow)
            return
        }
        
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString
            
            print("🔍 [WebStoreVC] Navigation to: \(urlString)")
            
            // Перевіряємо, чи це посилання на кошик (тільки після початкового завантаження)
            if urlString.contains("/cart") || urlString.contains("/basket") || urlString.contains("/checkout") {
                print("🛒 [WebStoreVC] Redirecting to cart tab")
                // Переходимо на вкладку кошика замість відкриття в браузері
                if let tabBarController = self.tabBarController {
                    tabBarController.selectedIndex = 3 // Індекс вкладки кошика
                }
                decisionHandler(.cancel)
                return
            }
            
            // Перевіряємо, чи це посилання на favorites
            if urlString.contains("/favorite") || urlString.contains("/wishlist") {
                print("❤️ [WebStoreVC] Redirecting to favorites tab")
                if let tabBarController = self.tabBarController {
                    tabBarController.selectedIndex = 2 // Індекс вкладки favorites
                }
                decisionHandler(.cancel)
                return
            }
        }
        
        print("✅ [WebStoreVC] Allowing navigation")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let javascript = """
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
                            
                            if (window.webkit?.messageHandlers?.cartHandler) {
                                window.webkit.messageHandlers.cartHandler.postMessage({
                                    type: 'xhr_call',
                                    url: xhr._url,
                                    method: xhr._method,
                                    data: responseData
                                });
                            }
                        } catch (e) {
                            console.error('Error parsing XHR response:', e);
                        }
                    }
                });
                
                return originalSend.apply(this, arguments);
            };
        })();
        
        // ✅ 2. Перехоплення кліків на кнопку "Додати в кошик" (Drupal специфіка)
        function setupDrupalCartHandler() {
            console.log('🔍 [Drupal] Searching for .addto_basket_button...');
            
            // Drupal використовує класс .addto_basket_button
            const buttons = document.querySelectorAll('.addto_basket_button, a[onclick*="basket_ajax_link"]');
            
            console.log(`✅ [Drupal] Found ${buttons.length} cart buttons`);
            
            buttons.forEach(function(button) {
                if (!button.dataset.nativeHandlerAttached) {
                    button.dataset.nativeHandlerAttached = 'true';
                    
                    button.addEventListener('click', function(event) {
                        console.log('🖱️ [Drupal] Cart button clicked');
                        
                        // Витягуємо дані з кнопки (Drupal зберігає їх у data-post)
                        const dataPost = button.getAttribute('data-post');
                        const basketNode = button.getAttribute('data-basket_node');
                        
                        if (dataPost) {
                            try {
                                const postData = JSON.parse(dataPost);
                                console.log('📦 [Drupal] Button data:', postData);
                                
                                // Витягуємо інформацію про товар з DOM
                                const productCard = button.closest('.product-item, .product-card, .goods-item, .view-item');
                                let productInfo = {
                                    type: 'add_to_cart_click',
                                    nid: postData.nid || basketNode,
                                    title: '',
                                    price: '',
                                    image: '',
                                    qty: 1
                                };
                                
                                if (productCard) {
                                    // Шукаємо назву
                                    const titleElem = productCard.querySelector('.product-title, .title, h2, h3, h4, .name');
                                    if (titleElem) productInfo.title = titleElem.textContent.trim();
                                    
                                    // Шукаємо ціну
                                    const priceElem = productCard.querySelector('.price, .cost, .product-price');
                                    if (priceElem) productInfo.price = priceElem.textContent.replace(/[^0-9]/g, '');
                                    
                                    // Шукаємо зображення
                                    const imgElem = productCard.querySelector('img');
                                    if (imgElem) productInfo.image = imgElem.src;
                                }
                                
                                console.log('✅ [Drupal] Extracted product info:', productInfo);
                                
                                // Відправляємо в Swift
                                if (window.webkit?.messageHandlers?.cartHandler) {
                                    window.webkit.messageHandlers.cartHandler.postMessage(productInfo);
                                }
                            } catch (e) {
                                console.error('Error parsing button data:', e);
                            }
                        }
                        
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
                
                if (window.webkit?.messageHandlers?.cartHandler) {
                    window.webkit.messageHandlers.cartHandler.postMessage({
                        type: 'drupal_cart_sync',
                        data: data
                    });
                }
            })
            .catch(err => {
                console.error('❌ [Drupal] Error syncing cart:', err);
            });
        }
        
        // ✅ 4. Експортуємо функцію для виклику з Swift
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
        """;
        
        webView.evaluateJavaScript(javascript) { (result, error) in
            if let error = error {
                print("❌ JavaScript injection error: \(error)")
            } else {
                print("✅ JavaScript injected successfully")
            }
        }
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "cartHandler", let messageData = message.body as? [String: Any] else {
            return
        }
        
        print("📨 [Swift] Received message from JavaScript: \(messageData)")
        
        // Визначаємо тип повідомлення
        if let type = messageData["type"] as? String {
            print("📋 [Swift] Message type: \(type)")
            
            switch type {
            case "add_to_cart_click":
                handleAddToCartClick(data: messageData)
            case "xhr_call":
                handleAPICall(data: messageData)
            case "drupal_cart_sync":
                handleDrupalCartSync(data: messageData)
            case "localstorage":
                handleLocalStorageData(data: messageData)
            case "dom_cart":
                handleDOMCart(data: messageData)
            default:
                print("⚠️ [Swift] Unknown message type: \(type)")
            }
        } else {
            // Старий формат повідомлення (backwards compatibility)
            handleLegacyMessage(data: messageData)
        }
    }
    
    // MARK: - Message Handlers
    
    /// Обробка кліку на кнопку "Додати в кошик" (миттєве додавання)
    private func handleAddToCartClick(data: [String: Any]) {
        print("🛒 [Swift] Handling add to cart click...")
        print("🛒 [Swift] Data received: \(data)")
        
        // Витягуємо nid (може бути String або Int або інший формат)
        var nid: Int?
        if let nidString = data["nid"] as? String {
            nid = Int(nidString)
        } else if let nidInt = data["nid"] as? Int {
            nid = nidInt
        }
        
        guard let productId = nid else {
            print("⚠️ [Swift] Missing or invalid nid in data")
            return
        }
        
        let title = data["title"] as? String ?? ""
        let priceString = data["price"] as? String ?? "0"
        let image = data["image"] as? String ?? ""
        let qty = data["qty"] as? Int ?? 1
        
        print("✅ [Swift] Product info: id=\(productId), title='\(title)', price=\(priceString), qty=\(qty)")
        
        // Якщо немає назви, не додаємо миттєво - чекаємо на синхронізацію
        if title.isEmpty {
            print("⚠️ [Swift] Product has no title, waiting for full sync...")
            return
        }
        
        let item = ItemBasketModel(
            id: productId,
            title: title,
            price: priceString,
            image: image,
            qty: qty
        )
        
        // Додаємо через CartManager
        CartManager.shared.addItem(item)
        
        // Показуємо повідомлення користувачу
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleNotification(
                notificationType: "✅ Додано в кошик",
                body: title
            )
        }
    }
    
    /// Обробка повної синхронізації кошика з Drupal API
    private func handleDrupalCartSync(data: [String: Any]) {
        print("🔄 [Swift] Handling Drupal cart sync...")
        
        // Drupal Ajax повертає масив команд
        guard let commands = data["data"] as? [[String: Any]] else {
            print("⚠️ [Swift] No commands in Drupal response")
            return
        }
        
        print("📦 [Swift] Processing \(commands.count) Drupal commands")
        
        // Шукаємо magnificPopup з HTML кошика
        for command in commands {
            if let commandType = command["command"] as? String {
                print("🔧 [Swift] Command: \(commandType)")
                
                if commandType == "magnificPopup", let html = command["html"] as? String {
                    print("🎪 [Swift] Found cart HTML in magnificPopup")
                    parseCartHTML(html)
                }
                
                // Також обробляємо basketReplaceWith для кількості
                if commandType == "basketReplaceWith", let html = command["data"] as? String {
                    parseBasketCount(html)
                }
            }
        }
    }
    
    private func handleAPICall(data: [String: Any]) {
        print("🌐 [Swift] Handling XHR API call...")
        
        // Це той самий обробник, що і drupal_cart_sync
        handleDrupalCartSync(data: data)
    }
    
    // Парсинг HTML кошика з magnificPopup (Drupal структура)
    private func parseCartHTML(_ html: String) {
        print("📄 [Swift] Parsing Drupal cart HTML...")
        print("📄 [Swift] HTML length: \(html.count) characters")
        
        var parsedItems: [ItemBasketModel] = []
        
        // Drupal використовує структуру <div class="goods-cart-row">
        // Шукаємо всі блоки товарів
        let rowPattern = #"<div class="goods-cart-row">[\s\S]*?(?=<div class="goods-cart-row">|<div class="view-footer">|$)"#
        
        do {
            let rowRegex = try NSRegularExpression(pattern: rowPattern, options: [])
            let htmlNSString = html as NSString
            let matches = rowRegex.matches(in: html, range: NSRange(location: 0, length: htmlNSString.length))
            
            print("✅ [Swift] Found \(matches.count) .goods-cart-row blocks")
            
            for (index, match) in matches.enumerated() {
                let rowHTML = htmlNSString.substring(with: match.range)
                print("📦 [Swift] Processing item \(index + 1)...")
                
                var itemData: [String: String] = [:]
                
                // 1. ID товару - витягуємо з data-post
                // Drupal використовує HTML-entities: &quot; замість "
                var foundId = false
                
                // Спроба 1: delete_item з &quot;
                let deletePattern1 = #"&quot;delete_item&quot;:&quot;(\d+)&quot;"#
                if let idRegex = try? NSRegularExpression(pattern: deletePattern1),
                   let idMatch = idRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                    itemData["id"] = (rowHTML as NSString).substring(with: idMatch.range(at: 1))
                    print("   ✅ ID (delete_item): \(itemData["id"] ?? "N/A")")
                    foundId = true
                }
                
                // Спроба 2: update_id з &quot;
                if !foundId {
                    let updatePattern1 = #"&quot;update_id&quot;:&quot;(\d+)&quot;"#
                    if let idRegex = try? NSRegularExpression(pattern: updatePattern1),
                       let idMatch = idRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                        itemData["id"] = (rowHTML as NSString).substring(with: idMatch.range(at: 1))
                        print("   ✅ ID (update_id): \(itemData["id"] ?? "N/A")")
                        foundId = true
                    }
                }
                
                // Спроба 3: delete_item з нормальними лапками
                if !foundId {
                    let deletePattern2 = #""delete_item":"(\d+)""#
                    if let idRegex = try? NSRegularExpression(pattern: deletePattern2),
                       let idMatch = idRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                        itemData["id"] = (rowHTML as NSString).substring(with: idMatch.range(at: 1))
                        print("   ✅ ID (delete_item alt): \(itemData["id"] ?? "N/A")")
                        foundId = true
                    }
                }
                
                // Спроба 4: update_id з нормальними лапками
                if !foundId {
                    let updatePattern2 = #""update_id":"(\d+)""#
                    if let idRegex = try? NSRegularExpression(pattern: updatePattern2),
                       let idMatch = idRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                        itemData["id"] = (rowHTML as NSString).substring(with: idMatch.range(at: 1))
                        print("   ✅ ID (update_id alt): \(itemData["id"] ?? "N/A")")
                        foundId = true
                    }
                }
                
                // Fallback: генеруємо ID на базі хешу вмісту
                if !foundId {
                    print("   ⚠️ No ID found, generating from content hash")
                    let hashBase = "\(index)"
                    itemData["id"] = String(hashBase.hashValue)
                    print("   ⚠️ Generated ID: \(itemData["id"] ?? "N/A")")
                }
                
                // 2. Назва товару - всередині <div class="goods-cart-row__title"><a>...</a>
                let titlePattern = #"goods-cart-row__title[^>]*>[\s\S]*?<a[^>]*>(.*?)</a>"#
                if let titleRegex = try? NSRegularExpression(pattern: titlePattern, options: [.dotMatchesLineSeparators]),
                   let titleMatch = titleRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                    let rawTitle = (rowHTML as NSString).substring(with: titleMatch.range(at: 1))
                    itemData["title"] = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("   ✅ Title: \(itemData["title"] ?? "N/A")")
                }
                
                // 3. Ціна - всередині <div class="sum">15 000 грн</div>
                let pricePattern = #"<div class="sum">\s*([0-9 ]+)\s*грн"#
                if let priceRegex = try? NSRegularExpression(pattern: pricePattern),
                   let priceMatch = priceRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                    let rawPrice = (rowHTML as NSString).substring(with: priceMatch.range(at: 1))
                    itemData["price"] = rawPrice.replacingOccurrences(of: " ", with: "")
                    print("   ✅ Price: \(itemData["price"] ?? "N/A")")
                }
                
                // 4. Зображення - <img src="/sites/default/files/..."
                let imagePattern = #"<img[^>]*src="([^"]+)"#
                if let imageRegex = try? NSRegularExpression(pattern: imagePattern),
                   let imageMatch = imageRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                    itemData["image"] = (rowHTML as NSString).substring(with: imageMatch.range(at: 1))
                    print("   ✅ Image: \(itemData["image"] ?? "N/A")")
                }
                
                // 5. Кількість - <input type="number" ... value="1" ... class="count_input"
                let qtyPattern = #"<input[^>]*class="count_input"[^>]*value="(\d+)"#
                if let qtyRegex = try? NSRegularExpression(pattern: qtyPattern),
                   let qtyMatch = qtyRegex.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                    itemData["qty"] = (rowHTML as NSString).substring(with: qtyMatch.range(at: 1))
                    print("   ✅ Quantity: \(itemData["qty"] ?? "N/A")")
                } else {
                    // Альтернативний pattern - value може бути до class
                    let qtyPattern2 = #"<input[^>]*value="(\d+)"[^>]*class="count_input"#
                    if let qtyRegex2 = try? NSRegularExpression(pattern: qtyPattern2),
                       let qtyMatch2 = qtyRegex2.firstMatch(in: rowHTML, range: NSRange(location: 0, length: rowHTML.count)) {
                        itemData["qty"] = (rowHTML as NSString).substring(with: qtyMatch2.range(at: 1))
                        print("   ✅ Quantity (alt): \(itemData["qty"] ?? "N/A")")
                    }
                }
                
                // Створюємо ItemBasketModel - завжди, навіть якщо немає ID
                let idString = itemData["id"] ?? String(abs(index.hashValue))
                
                // Конвертуємо ID в Int
                let id: Int
                if let parsedId = Int(idString) {
                    id = parsedId
                } else {
                    // Якщо ID не число (наприклад UUID), використовуємо хеш
                    id = abs(idString.hashValue)
                    print("   ⚠️ ID is not numeric, using hash: \(id)")
                }
                
                let title = itemData["title"] ?? "Товар #\(id)"
                let price = itemData["price"] ?? "0"
                let image = itemData["image"] ?? ""
                let fullImageURL = image.hasPrefix("/") ? "https://v3magazin.glyanec.net\(image)" : image
                let qty = Int(itemData["qty"] ?? "1") ?? 1
                
                let item = ItemBasketModel(
                    id: id,
                    title: title,
                    price: price,
                    image: fullImageURL,
                    qty: qty
                )
                
                parsedItems.append(item)
                print("✅ [Swift] Item \(index + 1) parsed: \(title) x\(qty) (id: \(id))")
                print("   📊 [Swift] Added to cart: title=\(title), price=\(price), qty=\(qty)")
            }
            
            // ✅ Замінюємо весь кошик
            print("🔄 [Swift] Replacing cart with \(parsedItems.count) items")
            CartManager.shared.replaceCart(with: parsedItems)
            
            if !parsedItems.isEmpty {
                // Показуємо notification
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    let totalItems = parsedItems.reduce(0) { $0 + $1.qty }
                    appDelegate.scheduleNotification(
                        notificationType: "🛒 Кошик оновлено",
                        body: "У кошику \(totalItems) товар(ів)"
                    )
                }
            }
            
        } catch {
            print("❌ [Swift] Error parsing HTML: \(error)")
        }
    }
    
    // Парсинг кількості товарів
    private func parseBasketCount(_ html: String) {
        if let countMatch = html.range(of: #"basket-count__link--count.*?>(\d+)<"#, options: .regularExpression) {
            let countString = String(html[countMatch])
            if let countRegex = try? NSRegularExpression(pattern: #">(\d+)<"#),
               let match = countRegex.firstMatch(in: countString, range: NSRange(location: 0, length: countString.count)) {
                let count = (countString as NSString).substring(with: match.range(at: 1))
                print("🛒 Cart count: \(count) items")
            }
        }
    }
    
    private func handleLocalStorageData(data: [String: Any]) {
        print("💾 Handling localStorage data...")
        
        guard let cartData = data["data"] else {
            print("⚠️ No cart data in localStorage")
            return
        }
        
        var parsedItems: [ItemBasketModel] = []
        
        if let items = cartData as? [[String: Any]] {
            print("📦 Found \(items.count) items in localStorage")
            for item in items {
                if let converted = convertToItemBasketModel(from: item) {
                    parsedItems.append(converted)
                }
            }
        } else if let itemDict = cartData as? [String: Any] {
            if let converted = convertToItemBasketModel(from: itemDict) {
                parsedItems.append(converted)
            }
        }
        
        if !parsedItems.isEmpty {
            CartManager.shared.replaceCart(with: parsedItems)
        }
    }
    
    private func handleDOMCart(data: [String: Any]) {
        print("📄 Handling DOM cart data...")
        
        guard let items = data["items"] as? [[String: Any]] else {
            print("⚠️ No items in DOM cart")
            return
        }
        
        print("📦 Found \(items.count) items in DOM")
        
        var parsedItems: [ItemBasketModel] = []
        for item in items {
            if let converted = convertToItemBasketModel(from: item) {
                parsedItems.append(converted)
            }
        }
        
        if !parsedItems.isEmpty {
            CartManager.shared.replaceCart(with: parsedItems)
        }
    }
    
    // MARK: - Convert to ItemBasketModel
    
    private func convertToItemBasketModel(from data: [String: Any]) -> ItemBasketModel? {
        guard let id = extractID(from: data) else {
            print("⚠️ Missing ID in item data")
            return nil
        }
        
        let title = extractTitle(from: data)
        let price = extractPrice(from: data)
        let image = extractImage(from: data)
        let qty = extractQuantity(from: data)
        
        return ItemBasketModel(
            id: id,
            title: title,
            price: String(price),
            image: image,
            qty: qty
        )
    }
    
    private func handleLegacyMessage(data: [String: Any]) {
        print("🔄 Handling legacy message format...")
        // Legacy format не використовується, бо Drupal повертає magnificPopup
        print("⚠️ Legacy format received, but we use magnificPopup parsing now")
    }
    
    // MARK: - Data Extraction Helpers
    
    private func extractID(from data: [String: Any]) -> Int? {
        if let id = data["id"] as? Int {
            return id
        } else if let idString = data["id"] as? String {
            return Int(idString)
        } else if let nid = data["nid"] as? Int {
            return nid
        } else if let productId = data["product_id"] as? Int {
            return productId
        } else if let productId = data["productId"] as? String {
            return Int(productId)
        }
        return nil
    }
    
    private func extractTitle(from data: [String: Any]) -> String {
        if let title = data["title"] as? String {
            return title
        } else if let name = data["name"] as? String {
            return name
        } else if let productName = data["product_name"] as? String {
            return productName
        }
        return ""
    }
    
    private func extractPrice(from data: [String: Any]) -> Double {
        if let price = data["price"] as? Double {
            return price
        } else if let price = data["price"] as? Int {
            return Double(price)
        } else if let priceString = data["price"] as? String {
            let cleanPrice = priceString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            return Double(cleanPrice) ?? 0.0
        } else if let cost = data["cost"] as? Double {
            return cost
        }
        return 0.0
    }
    
    private func extractImage(from data: [String: Any]) -> String {
        if let image = data["image"] as? String {
            return image
        } else if let imageUrl = data["image_url"] as? String {
            return imageUrl
        } else if let thumbnail = data["thumbnail"] as? String {
            return thumbnail
        } else if let photo = data["photo"] as? String {
            return photo
        }
        return ""
    }
    
    private func extractQuantity(from data: [String: Any]) -> Int {
        if let qty = data["qty"] as? Int {
            return qty
        } else if let quantity = data["quantity"] as? Int {
            return quantity
        } else if let count = data["count"] as? Int {
            return count
        }
        return 1
    }

}
