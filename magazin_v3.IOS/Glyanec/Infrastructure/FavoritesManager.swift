import Foundation

/// Менеджер для роботи з "Вподобайками" (Favorites) через Drupal API
final class FavoritesManager {
    
    static let shared = FavoritesManager()
    
    // Notification для оновлення UI
    static let favoritesDidUpdateNotification = Notification.Name("FavoritesManagerDidUpdate")
    
    private let apiURL = URL(string: "https://v3magazin.glyanec.net/api/drupal_package_like/like")!
    private let defaultsKey = "favoriteProductIDs"
    
    private init() {
        print("✅ [FavoritesManager] Initialized")
    }
    
    // MARK: - Storage
    
    private var storedIDs: [Int] {
        get {
            UserDefaults.standard.array(forKey: defaultsKey) as? [Int] ?? []
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: defaultsKey)
            print("💾 [FavoritesManager] Saved \(newValue.count) favorite IDs")
        }
    }
    
    // MARK: - Public Methods
    
    /// Перевірка чи товар в обраному
    func isFavorite(_ id: Int) -> Bool {
        return storedIDs.contains(id)
    }
    
    /// Перемикання статусу "обране" для товару
    func toggleFavorite(for id: Int, completion: @escaping (Bool) -> Void) {
        let isCurrentlyFavorite = isFavorite(id)
        let adding = !isCurrentlyFavorite
        
        print("❤️ [FavoritesManager] Toggling favorite for ID \(id): \(adding ? "ADD" : "REMOVE")")
        
        let body: [String: Any] = [
            "d_p_l": [
                "entity_type": "node",
                "entity_id": "\(id)",
                "like_type": "favorites",
                "like_subtype": adding ? "add" : "remove",
                "count": "0",
                "texts": [
                    "on": "В обране",
                    "off": "Видалити з обраного"
                ],
                "class": ["favorite_button"],
                "tag": "a"
            ]
        ]
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Додаємо cookies з WebView для авторизації
        if let cookies = HTTPCookieStorage.shared.cookies {
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in cookieHeader {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ [FavoritesManager] Error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                print("❌ [FavoritesManager] Invalid response")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            print("📡 [FavoritesManager] Response status: \(http.statusCode)")
            
            if http.statusCode == 200 {
                DispatchQueue.main.async {
                    // Оновлюємо локальний стан
                    var ids = self.storedIDs
                    
                    if adding {
                        if !ids.contains(id) {
                            ids.append(id)
                        }
                    } else {
                        ids.removeAll { $0 == id }
                    }
                    
                    self.storedIDs = ids
                    
                    // Надсилаємо notification
                    NotificationCenter.default.post(
                        name: FavoritesManager.favoritesDidUpdateNotification,
                        object: nil
                    )
                    
                    print("✅ [FavoritesManager] Updated successfully")
                    completion(true)
                }
            } else {
                print("⚠️ [FavoritesManager] Unexpected status code: \(http.statusCode)")
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }
    
    /// Отримати всі ID обраних товарів
    func getAllFavorites() -> [Int] {
        return storedIDs
    }
    
    /// Очистити всі вподобайки
    func clearAll() {
        print("🗑️ [FavoritesManager] Clearing all favorites")
        storedIDs = []
        NotificationCenter.default.post(
            name: FavoritesManager.favoritesDidUpdateNotification,
            object: nil
        )
    }
    
    /// Завантажити список обраних товарів із сервера (опціонально)
    func syncWithServer(completion: @escaping ([Int]?) -> Void) {
        // TODO: Реалізувати завантаження списку з /user/favorites через HTML parsing
        // Поки що використовуємо локальне збереження
        completion(storedIDs)
    }
}

