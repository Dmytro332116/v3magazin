# v3magazin – інструкція для команди (iOS та Android)

Це монорепозиторій з двома окремими проєктами: iOS та Android. Код розділено по платформах для зручності роботи, тестування та публікації.

- iOS: `magazin_v3.IOS`
- Android: `magazin_v3.Android/android`

Репозиторій для команди: [github.com/Dmytro332116/v3magazin](https://github.com/Dmytro332116/v3magazin)

## 1) Структура репозиторію

- `magazin_v3.IOS/`
  - `Glyanec.xcworkspace` – відкривати в Xcode
  - `Glyanec.xcodeproj`, `Glyanec/`, `Pods/` – код і залежності iOS
- `magazin_v3.Android/android/` – корінь Gradle‑проєкту Android (відкривати в Android Studio)
- `README.md` – ця інструкція
- Інші документи: `QUICKSTART.md`, `INTEGRATION_GUIDE.md`, `CHANGELOG.md`

## 2) Архітектура застосунку (обидві платформи)

- Основа – WebView, який відображає магазин: головна, каталог, списки (вибране)
- Нативна нижня навігація (`BottomNavigation` на Android, `UITabBarController` на iOS)
- Нативний кошик:
  - Android: `RecyclerView` + локальне збереження (SharedPreferences)
  - iOS: `UITableView` + локальне збереження
- URL‑и вкладок узгоджені між платформами

## 3) Вимоги до середовища

- macOS (для iOS)
- Xcode 15+ (iOS симулятори iOS 17/18)
- Android Studio (Koala/Hedgehog+) + Android SDK 34
- Java 17 (можна використати вбудований JDK Android Studio)

## 4) Швидкий старт – iOS

1. Відкрити робочу теку `magazin_v3.IOS`
2. Відкрити воркспейс: подвійний клік по `Glyanec.xcworkspace`
3. Обрати симулятор (наприклад, iPhone 15)
4. Запустити (⌘R)

Якщо на машині відсутні Pods або треба перевстановити:
```
cd magazin_v3.IOS
sudo gem install cocoapods   # якщо не встановлено
pod install
open Glyanec.xcworkspace
```

### Де шукати основні екрани (iOS)
- `Glyanec/Infrastructure/CompositionRoot.swift` – складання вкладок
- `Glyanec/app/Main/WebStoreViewController.swift` – WebView
- `Glyanec/app/Basket/...` – нативний кошик

### Типові проблеми (iOS)
- Якщо збірка “ламатиметься” через підписи – використовуйте Team = Personal/None для тесту на симуляторі
- Якщо Xcode не бачить Pods – виконайте `pod install`

## 5) Швидкий старт – Android

### Варіант A (Android Studio – рекомендовано)
1. Відкрити `magazin_v3.Android/android`
2. Дочекатися завершення Gradle Sync
3. В Device Manager створити/запустити емулятор (Pixel, API 34)
4. Запустити конфігурацію `app`

### Варіант B (CLI)
```
cd magazin_v3.Android/android
./gradlew assembleDebug

# якщо емулятор/пристрій підключений
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.glyanec.shop/.MainActivity
```

### Де шукати основні екрани (Android)
- `app/src/main/java/com/glyanec/shop/MainActivity.kt` – активність з `BottomNavigation`
- `app/src/main/java/com/glyanec/shop/fragments/WebViewFragment.kt` – WebView
- `app/src/main/java/com/glyanec/shop/fragments/BasketFragment.kt` + `BasketAdapter.kt` – нативний кошик
- `app/src/main/java/com/glyanec/shop/data/` – моделі/збереження кошика

### Типові проблеми (Android)
- Якщо WebView показує білий екран після першого запуску – перезапустіть застосунок:
  ```
  adb shell am force-stop com.glyanec.shop && adb shell am start -n com.glyanec.shop/.MainActivity
  ```
- Якщо Java не знайдена – використовуйте JDK, який постачається з Android Studio

## 6) Перевірка функціоналу (чек‑лист для QA)
- Вкладки: Головна / Магазин / Списки – відображаються та відкривають відповідні сторінки
- Кошик (нативний):
  - Відображення позицій (з назвою, ціною, фото, кількістю)
  - Зміна кількості ±
  - Видалення позиції
  - Загальна сума перераховується
  - Кнопка «Оформити» відкриває сторінку оформлення у WebView
- Навігація «Назад» в WebView працює (історія сторінок)

## 7) Збірки для сторів (коротко)

### iOS (App Store)
- Archive → Distribute App → App Store Connect (через Xcode/Transporter)
- Підготуйте скріншоти (6.7", 5.5"), метадані, Privacy, Export Compliance

### Android (Google Play)
- Релізний бандл: `./gradlew bundleRelease`
- Вивантажити `.aab` у Play Console, заповнити Store Listing, Data safety, Privacy Policy URL

## 8) Командна робота
- Гілки: `main` (стабільна), `feature/*` для задач
- Коміти: `feat:`, `fix:`, `chore:`, `docs:`
- Pull Request з коротким описом змін та скріншотами

---
Питання/допомога щодо запуску – пишіть у чат команди. Репозиторій: [v3magazin](https://github.com/Dmytro332116/v3magazin).

# GlyanecShop_iOS

Application template for an online store.
Swift development language.
MVVM architecture