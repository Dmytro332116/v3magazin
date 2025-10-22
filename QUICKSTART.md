# 🚀 Quick Start - WebView Інтеграція Кошика

## ✅ Що вже працює

### 1. **JavaScript Bridge** 
Автоматично перехоплює натискання на "Додати в кошик" на сайті

### 2. **Локальне збереження**
Всі товари зберігаються у `UserDefaults` і не губляться після перезапуску

### 3. **Синхронізація між вкладками**
Cookies та сесія працюють на всіх вкладках WebView

### 4. **Автоматична навігація**
При додаванні товару - автоматичний перехід на вкладку кошика

---

## 🎯 Швидке тестування

### Крок 1: Запустіть додаток
```bash
cd "/Users/dmitro/Downloads/GlyanecShop_iOS-masterr 4"
open Glyanec.xcworkspace
# Або натисніть Cmd+R у Xcode
```

### Крок 2: Перевірте базовий функціонал
1. ✅ Відкрийте головну вкладку
2. ✅ Натисніть "Додати в кошик" на будь-якому товарі
3. ✅ Переконайтесь, що відкрилась вкладка кошика
4. ✅ Перевірте, що товар з'явився у списку

### Крок 3: Перевірте збереження
1. ✅ Додайте кілька товарів
2. ✅ Закрийте додаток (Cmd+Q в симуляторі)
3. ✅ Запустіть знову
4. ✅ Перейдіть у кошик - товари мають бути на місці

---

## 🔧 Швидке налаштування (якщо потрібно)

### Якщо кнопка "Додати в кошик" на сайті має інший клас:

**Файл:** `Glyanec/app/Main/WebStoreViewController.swift`

**Знайдіть рядок 83:**
```swift
document.querySelectorAll('a[data-onclick*="basket_ajax_link"]')
```

**Замініть на свій селектор:**
```swift
// Приклад 1: якщо кнопка має клас .btn-add-cart
document.querySelectorAll('.btn-add-cart')

// Приклад 2: якщо кнопка має data-атрибут
document.querySelectorAll('[data-add-to-cart]')

// Приклад 3: якщо кнопка має id
document.querySelectorAll('#addToCartBtn')
```

### Якщо URL кошика на сайті інший:

**Файл:** `Glyanec/app/Main/WebStoreViewController.swift`

**Знайдіть рядок 58:**
```swift
if urlString.contains("/cart") || urlString.contains("/basket") || urlString.contains("/checkout") {
```

**Додайте свій URL:**
```swift
if urlString.contains("/cart") || 
   urlString.contains("/basket") || 
   urlString.contains("/checkout") ||
   urlString.contains("/your-custom-cart-url") {
```

---

## 📊 Де дивитись логи

### В Xcode Console (Cmd+Shift+Y):

**Успішне додавання:**
```
✅ Додано новий товар: Назва товару
✅ Товар збережено в нативний кошик: Назва товару
```

**Оновлення кількості:**
```
✅ Оновлено кількість товару: Назва товару, qty: 2
```

**Оновлення кошика:**
```
🔄 Кошик оновлено, перезавантажуємо дані...
```

**JavaScript помилки:**
```
JavaScript injection error: [опис помилки]
Error parsing product data from JavaScript.
```

---

## 🐛 Проблеми? Швидкі рішення

### ❌ Товар не додається
**Рішення:**
1. Перевірте Console в Xcode - там має з'явитись `"Received product data from JavaScript: ..."`
2. Якщо немає - перевірте селектор JavaScript (див. вище)
3. Спробуйте перезавантажити сторінку (pull-to-refresh в WebView)

### ❌ Кошик порожній після перезапуску
**Рішення:**
1. Перевірте, що товар успішно додався (див. логи)
2. Перегляньте UserDefaults в debugger:
   ```swift
   let defaults = UserDefaults.standard
   let data = defaults.value(forKey: "ItemBasketModel")
   print(data)
   ```

### ❌ Safari відкривається замість вкладки кошика
**Рішення:**
1. Перевірте, що `decidePolicyFor navigationAction` викликається
2. Додайте більше варіантів URL (див. налаштування вище)
3. Подивіться, який саме URL намагається відкритись:
   ```swift
   print("🔗 Trying to open URL: \(url.absoluteString)")
   ```

---

## 📱 Індекси вкладок Tab Bar

```
0 - Головна (WebView)
1 - Каталог (WebView)
2 - Favorites (Native)
3 - Кошик (Native)
```

Якщо у вас інший порядок - змініть у коді:
```swift
tabBarController?.selectedIndex = 3  // ← Ваш індекс
```

---

## 🎉 Готово!

Тепер ваш WebView додаток має повну інтеграцію з кошиком! 

Більше деталей → `INTEGRATION_GUIDE.md`

