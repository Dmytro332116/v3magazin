# 🛒 Інтеграція кошика WebView з iOS додатком - Документація

## 📋 Зміст
- [Що було виправлено](#що-було-виправлено)
- [Архітектура рішення](#архітектура-рішення)
- [Як це працює](#як-це-працює)
- [Тестування](#тестування)
- [Troubleshooting](#troubleshooting)

---

## ✅ Що було виправлено

### 1. **Додано відсутні моделі та API методи**
- ✅ Створено `ResultItemListModel` для вибраного (Favorites)
- ✅ Додано метод `NetworkFavorites.getFavoritesList()` для API запитів
- ✅ Виправлено модифікатори доступу у `FavoritesViewController`

### 2. **Налаштовано спільний WebView data store**
```swift
// ✅ Всі WebView тепер використовують спільний data store і process pool
webConfiguration.websiteDataStore = .default()
webConfiguration.processPool = WebViewProcessPool.shared
```

**Що це дає:**
- Cookies зберігаються між усіма вкладками
- Сесія користувача не губиться при переході між вкладками
- localStorage та sessionStorage працюють коректно

### 3. **Додано перехоплення навігації до кошика**
```swift
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url {
        let urlString = url.absoluteString
        
        // Якщо користувач натискає на кошик на сайті - відкриваємо вкладку додатку
        if urlString.contains("/cart") || urlString.contains("/basket") || urlString.contains("/checkout") {
            tabBarController?.selectedIndex = 3 // Кошик
            decisionHandler(.cancel)
            return
        }
        
        // Якщо натискає на favorites - відкриваємо відповідну вкладку
        if urlString.contains("/favorite") || urlString.contains("/wishlist") {
            tabBarController?.selectedIndex = 2 // Favorites
            decisionHandler(.cancel)
            return
        }
    }
    
    decisionHandler(.allow)
}
```

**Що це дає:**
- Кошик відкривається у додатку, а не у Safari
- Користувач залишається всередині додатку
- Плавна навігація без виходу з програми

### 4. **Покращено логіку додавання в кошик**
```swift
// ✅ Перевірка на дублікати
let itemId = Int(id) ?? 0
if let existingIndex = list.firstIndex(where: { $0.id == itemId }) {
    // Якщо товар вже є - збільшуємо кількість
    list[existingIndex].qty += 1
    print("✅ Оновлено кількість товару: \(title), qty: \(list[existingIndex].qty)")
} else {
    // Якщо новий - додаємо
    list.append(ItemBasketModel(id: itemId, title: title, price: String(price), image: image, qty: 1))
    print("✅ Додано новий товар: \(title)")
}
```

**Що це дає:**
- Немає дублікатів у кошику
- Коректний підрахунок кількості товарів
- Економія пам'яті

### 5. **Додано систему NotificationCenter для синхронізації**
```swift
// У WebStoreViewController після додавання товару:
NotificationCenter.default.post(name: NSNotification.Name("CartUpdated"), object: nil)

// У BasketViewController підписуємося на оновлення:
NotificationCenter.default.addObserver(
    self,
    selector: #selector(cartDidUpdate),
    name: NSNotification.Name("CartUpdated"),
    object: nil
)

@objc func cartDidUpdate() {
    print("🔄 Кошик оновлено, перезавантажуємо дані...")
    viewModel.getBasketList()
}
```

**Що це дає:**
- Кошик автоматично оновлюється при додаванні товару
- Реалтайм синхронізація між WebView і нативним UI
- Користувач одразу бачить зміни

---

## 🏗 Архітектура рішення

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS App (Swift)                          │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Головна  │  │ Каталог  │  │Favorites │  │  Кошик   │  │
│  │ (WebView)│  │ (WebView)│  │ (Native) │  │ (Native) │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
│       │             │              │             │         │
│       └─────────────┴──────────────┴─────────────┘         │
│                     │                                       │
│         ┌───────────▼──────────────┐                       │
│         │  WebViewProcessPool      │ ← Спільні cookies    │
│         │  (shared WKProcessPool)  │                       │
│         └───────────┬──────────────┘                       │
│                     │                                       │
│         ┌───────────▼──────────────┐                       │
│         │ JavaScript Bridge        │                       │
│         │ (WKScriptMessageHandler) │                       │
│         └───────────┬──────────────┘                       │
│                     │                                       │
│         ┌───────────▼──────────────┐                       │
│         │  UserDefaults Storage    │ ← Локальне           │
│         │  - ItemBasketModel       │   зберігання         │
│         │  - BasketModel           │                       │
│         └──────────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Як це працює

### Потік додавання товару в кошик:

1. **Користувач натискає "Додати в кошик" на сайті (у WebView)**
   ```javascript
   // JavaScript на сайті відправляє повідомлення в Swift
   window.webkit.messageHandlers.cartHandler.postMessage({
       id: "123",
       title: "Товар",
       price: 299.99,
       image: "https://..."
   });
   ```

2. **WebStoreViewController отримує повідомлення**
   ```swift
   func userContentController(_ userContentController: WKUserContentController, 
                              didReceive message: WKScriptMessage) {
       // Розпаковуємо дані товару
       if let productData = message.body as? [String: Any] { ... }
   ```

3. **Перевірка на дублікати**
   ```swift
   if let existingIndex = list.firstIndex(where: { $0.id == itemId }) {
       list[existingIndex].qty += 1  // Збільшуємо кількість
   } else {
       list.append(newItem)  // Додаємо новий товар
   }
   ```

4. **Збереження в UserDefaults**
   ```swift
   UserDefaults.standard.set(
       try? PropertyListEncoder().encode(list), 
       forKey: "ItemBasketModel"
   )
   ```

5. **Надсилання notification**
   ```swift
   NotificationCenter.default.post(
       name: NSNotification.Name("CartUpdated"), 
       object: nil
   )
   ```

6. **BasketViewController оновлює UI**
   ```swift
   @objc func cartDidUpdate() {
       viewModel.getBasketList()  // Перезавантажує дані
       basketTV.reloadData()      // Оновлює таблицю
   }
   ```

7. **Автоматичний перехід на вкладку кошика**
   ```swift
   tabBarController?.selectedIndex = 3
   ```

---

## 🧪 Тестування

### Сценарії для перевірки:

#### ✅ **Тест 1: Додавання товару з головної сторінки**
1. Відкрийте головну вкладку
2. Натисніть "Додати в кошик" на будь-якому товарі
3. **Очікується:** 
   - Автоматичний перехід на вкладку кошика
   - Товар з'являється у списку
   - Push-notification "Товар додано в кошик"

#### ✅ **Тест 2: Перевірка дублікатів**
1. Додайте товар у кошик
2. Поверніться на головну
3. Додайте той самий товар знову
4. **Очікується:** 
   - У кошику лише один запис про товар
   - Кількість (qty) = 2

#### ✅ **Тест 3: Збереження між вкладками**
1. Додайте товар у кошик з головної сторінки
2. Перейдіть на каталог
3. Перейдіть у кошик
4. **Очікується:** 
   - Товар залишається у кошику
   - Дані не втрачаються

#### ✅ **Тест 4: Збереження після перезапуску додатку**
1. Додайте кілька товарів у кошик
2. Закрийте додаток (force quit)
3. Відкрийте додаток знову
4. Перейдіть у кошик
5. **Очікується:** 
   - Всі товари на місці
   - UserDefaults зберіг дані

#### ✅ **Тест 5: Перехоплення навігації**
1. На сайті натисніть на іконку кошика (якщо є посилання /cart)
2. **Очікується:** 
   - Safari не відкривається
   - Автоматичний перехід на вкладку кошика в додатку

#### ✅ **Тест 6: Спільні cookies між вкладками**
1. Авторизуйтесь на сайті у вкладці "Головна"
2. Перейдіть на вкладку "Каталог"
3. **Очікується:** 
   - Ви залишаєтесь авторизованим
   - Cookies зберігаються

---

## 🐛 Troubleshooting

### Проблема: Товар не з'являється у кошику

**Можливі причини:**
1. JavaScript не може знайти кнопку на сайті
   - **Рішення:** Перевірте селектор у JavaScript коді (`a[data-onclick*="basket_ajax_link"]`)
   - Подивіться в консолі Xcode на помилки JavaScript

2. UserDefaults не зберігає дані
   - **Рішення:** Перевірте, чи ItemBasketModel відповідає протоколу Codable
   - Подивіться логи: `print("✅ Додано новий товар: \(title)")`

### Проблема: Кошик не оновлюється автоматично

**Можливі причини:**
1. NotificationCenter не працює
   - **Рішення:** Перевірте, чи підписаний BasketViewController на "CartUpdated"
   - Подивіться, чи викликається `@objc func cartDidUpdate()`

2. BasketViewController не у пам'яті
   - **Рішення:** iOS може вивантажити контролер, якщо він не використовується

### Проблема: Cookies не зберігаються між вкладками

**Можливі причини:**
1. Різні process pools
   - **Рішення:** Переконайтесь, що всі WebView використовують `WebViewProcessPool.shared`

2. Різні data stores
   - **Рішення:** Використовуйте `.default()` замість створення нових

### Проблема: Safari відкривається замість вкладки кошика

**Можливі причини:**
1. URL не перехоплюється
   - **Рішення:** Перевірте умови у `decidePolicyFor navigationAction`
   - Додайте інші варіанти URL кошика: `/cart`, `/basket`, `/checkout`

---

## 📝 Налаштування під твій сайт

### Як змінити селектори JavaScript:

Якщо кнопки "Додати в кошик" на твоєму сайті мають інші класи/атрибути:

1. Відкрий `WebStoreViewController.swift`
2. Знайди рядок:
   ```javascript
   document.querySelectorAll('a[data-onclick*="basket_ajax_link"]')
   ```
3. Зміни на свій селектор, наприклад:
   ```javascript
   document.querySelectorAll('.add-to-cart-button')
   // або
   document.querySelectorAll('[data-product-add]')
   ```

### Як додати інші URL для перехоплення:

1. Знайди метод `decidePolicyFor navigationAction`
2. Додай свої URL:
   ```swift
   if urlString.contains("/my-custom-cart") || 
      urlString.contains("/order") {
       tabBarController?.selectedIndex = 3
       decisionHandler(.cancel)
       return
   }
   ```

---

## 🚀 Подальші покращення

### Можливі додаткові фічі:

1. **Синхронізація з сервером**
   - Відправляти кошик на API сайту
   - Завантажувати кошик з сервера при запуску

2. **Push notifications**
   - Нагадування про товари в кошику
   - Знижки на товари в кошику

3. **Favorites через API**
   - Повна інтеграція з API вибраного на сайті
   - Синхронізація між додатком і сайтом

4. **Analytics**
   - Відстежування додавань у кошик
   - Аналіз поведінки користувача

---

## 📞 Підтримка

Якщо виникли проблеми:
1. Подивись логи в Xcode Console
2. Перевір Network запити в Safari Web Inspector
3. Переконайся, що JavaScript на сайті правильно інжектується

---

**Автор:** AI Assistant  
**Дата:** 2025-10-17  
**Версія:** 1.0

