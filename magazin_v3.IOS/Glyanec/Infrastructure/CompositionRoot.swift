import UIKit

/// Кастомний TabBarController з обробкою повторних тапів
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        print("✅ [MainTabBarController] Initialized with delegate")
    }
    
    // MARK: - UITabBarControllerDelegate
    
    /// Обробка повторного тапу по вже активній вкладці
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Якщо це UINavigationController і в ньому є більше 1 екрану
        if let navController = viewController as? UINavigationController,
           navController.viewControllers.count > 1 {
            print("🔙 [MainTabBarController] Tab re-tapped - popping to root")
            navController.popToRootViewController(animated: true)
        }
    }
}

class CompositionRoot {

    static var sharedInstance: CompositionRoot = CompositionRoot()

    var rootTabBarController: MainTabBarController!

    required init() {
        configureRootTabBarController()
    }
    
    @available(iOS 12.0, *)
    func updateUI(style: UIUserInterfaceStyle) {
    }
    
    private func configureRootTabBarController()
    {
        // ✅ Використовуємо кастомний TabBarController з delegate
        rootTabBarController = MainTabBarController()
        rootTabBarController.tabBar.tintColor = ColorCompatibility.label
        rootTabBarController.tabBar.backgroundColor = .white
        rootTabBarController.tabBar.clipsToBounds = true
        
        var viewControllersList: [UIViewController] = [UIViewController]()
        let mainWebStoreViewController = WebStoreViewController()
        mainWebStoreViewController.urlString = "https://v3magazin.glyanec.net/"
        mainWebStoreViewController.tabBarItem = UITabBarItem(title: "Головна", image: UIImage(named: "home store"), tag: 1)
        mainWebStoreViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewControllersList.append(mainWebStoreViewController)

        let catalogWebStoreViewController = WebStoreViewController()
        catalogWebStoreViewController.urlString = "https://v3magazin.glyanec.net/catalog/all"
        catalogWebStoreViewController.tabBarItem = UITabBarItem(title: "Магазин", image: UIImage(named: "list"), tag: 2)
        catalogWebStoreViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewControllersList.append(catalogWebStoreViewController)

        let favoritesViewController = resolveFavoritesViewController()
        // ✅ Використовуємо system icons для серця
        favoritesViewController.tabBarItem = UITabBarItem(
            title: "Списки",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )
        favoritesViewController.tabBarItem.tag = 3
        viewControllersList.append(favoritesViewController)
        
        let basketViewController = resolveBasketViewController(list: [ItemBasketModel]())
        basketViewController.tabBarItem = UITabBarItem(title: "Кошик", image: UIImage(named: "shopping basket"), tag: 4)
        basketViewController.tabBarItem.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        viewControllersList.append(basketViewController)

        let viewControllers = viewControllersList.map { (viewController) -> UIViewController in
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.isHidden = true
            return navigationController
        }

        rootTabBarController.setViewControllers(viewControllers, animated: true)
    }

    // MARK: ViewControllers
    func resolveSignUpViewController() -> LogInViewController {
        let vc = LogInViewController.instantiateFromStoryboard("LogIn")
        vc.viewModel = resolveSignUpViewModel(view: vc)
        return vc
    }
    
    func resolveMainViewController() -> MainViewController {
        let vc = MainViewController.instantiateFromStoryboard("Main")
        vc.viewModel = resolveMainViewModel(view: vc)
        return vc
    }

    func resolveItemDetailsViewController(id: String) -> ItemDetailsViewController {
        let vc = ItemDetailsViewController.instantiateFromStoryboard("ItemDetails")
        vc.viewModel = resolveItemDetailsViewModel(view: vc, id: id)
        return vc
    }
    
    func resolveProductsViewController(categories: [ResultCategorysListModel]) -> ProductsViewController {
        let vc = ProductsViewController.instantiateFromStoryboard("Products")
        vc.viewModel = resolveProductsViewModel(view: vc, categories: categories)
        return vc
    }

    func resolveCategoryProductsViewController() -> CategoryViewController {
        let vc = CategoryViewController.instantiateFromStoryboard("Products")
        vc.viewModel = resolveCategoryProductsViewModel(view: vc)
        return vc
    }

    func resolveCategoryItemsViewController(caregoryId:String,
                                            caregoryName:String) -> CategoryItemsViewController {
        let vc = CategoryItemsViewController.instantiateFromStoryboard("Products")
        vc.viewModel = resolveresolveCategoryItemsModel(view: vc, caregoryId: caregoryId, caregoryName: caregoryName)
        return vc
    }
    
    func resolveFavoritesViewController() -> FavoritesViewController {
        // ✅ Створюємо програмно - тепер це WebView контролер
        let vc = FavoritesViewController()
        return vc
    }

    func resolveBasketViewController(list: [ItemBasketModel]?) -> BasketViewController {
        let vc = BasketViewController.instantiateFromStoryboard("Basket")
        vc.viewModel = resolveBasketViewModel(view: vc, list: list)
        return vc
    }
    
// MARK: ViewModels
    
    func resolveSignUpViewModel(view: LogInViewProtocol) -> LogInViewModel {
        return LogInViewModel(view: view)
    }

    func resolveMainViewModel(view: MainViewProtocol) -> MainViewModel {
        return MainViewModel(view: view)
    }

    func resolveItemDetailsViewModel(view: ItemDetailsViewProtocol, id: String) -> ItemDetailsViewModel {
        return ItemDetailsViewModel(view: view, id: id)
    }
    
    func resolveProductsViewModel(view: ProductsViewProtocol, categories: [ResultCategorysListModel]) -> ProductsViewModel {
        return ProductsViewModel(view: view, categories: categories)
    }

    func resolveCategoryProductsViewModel(view: CategoryViewProtocol) -> CategoryViewModel {
        return CategoryViewModel(view: view)
    }

    func resolveresolveCategoryItemsModel(view: CategoryItemsViewProtocol, caregoryId: String, caregoryName:String) -> CategoryItemsViewModel {
        return CategoryItemsViewModel(view: view, caregoryId: caregoryId, caregoryName: caregoryName)
    }

    // ✅ Більше не використовується - FavoritesViewController тепер WebView-based
    // func resolveFavoritesViewModel(view: FavoritesViewProtocol) -> FavoritesViewModel {
    //     return FavoritesViewModel(view: view)
    // }

    func resolveBasketViewModel(view: BasketViewProtocol, list: [ItemBasketModel]?) -> BasketViewModel {
        return BasketViewModel(view: view, list: list)
    }    
}

// MARK: - CartManager

/// Singleton для управління кошиком по всьому додатку
class CartManager {
    static let shared = CartManager()
    
    // Notification для оновлення UI
    static let cartDidUpdateNotification = Notification.Name("CartManagerDidUpdate")
    
    private init() {}
    
    // MARK: - Get Cart Items
    
    func getCartItems() -> [ItemBasketModel] {
        if let data = UserDefaults.standard.value(forKey: "ItemBasketModel") as? Data {
            return (try? PropertyListDecoder().decode([ItemBasketModel].self, from: data)) ?? []
        }
        return []
    }
    
    func getBasketModels() -> [BasketModel] {
        if let data = UserDefaults.standard.value(forKey: "BasketModel") as? Data {
            return (try? PropertyListDecoder().decode([BasketModel].self, from: data)) ?? []
        }
        return []
    }
    
    // MARK: - Replace Entire Cart (from WebView HTML)
    
    /// Замінює весь кошик новими даними (викликається після парсингу HTML з WebView)
    func replaceCart(with items: [ItemBasketModel]) {
        print("🔄 [CartManager] Replacing cart with \(items.count) items")
        
        // ✅ ВАЖЛИВО: Все в main thread для UIKit
        DispatchQueue.main.async {
            // Зберігаємо ItemBasketModel
            UserDefaults.standard.set(try? PropertyListEncoder().encode(items), forKey: "ItemBasketModel")
            
            // Створюємо BasketModel (для API)
            let basketModels = items.map { BasketModel(id: $0.id, qty: $0.qty) }
            UserDefaults.standard.set(try? PropertyListEncoder().encode(basketModels), forKey: "BasketModel")
            
            print("✅ [CartManager] Cart saved to UserDefaults")
            print("📦 [CartManager] Items in cart: \(items.map { "\($0.title) (x\($0.qty))" }.joined(separator: ", "))")
            
            // Надсилаємо notification для оновлення UI - в main thread!
            NotificationCenter.default.post(name: CartManager.cartDidUpdateNotification, object: nil)
            
            print("✅ [CartManager] Notification sent, UI should update now")
        }
    }
    
    // MARK: - Add Single Item
    
    /// Додає один товар (або збільшує кількість якщо вже є)
    func addItem(_ item: ItemBasketModel) {
        var items = getCartItems()
        
        if let existingIndex = items.firstIndex(where: { $0.id == item.id }) {
            // Збільшуємо кількість
            items[existingIndex].qty += item.qty
            print("🔄 [CartManager] Updated quantity for item \(item.id): qty=\(items[existingIndex].qty)")
        } else {
            // Додаємо новий
            items.append(item)
            print("✅ [CartManager] Added new item: \(item.title)")
        }
        
        replaceCart(with: items)
    }
    
    // MARK: - Remove Item
    
    func removeItem(at index: Int) {
        var items = getCartItems()
        guard index < items.count else { return }
        
        let removedItem = items.remove(at: index)
        print("🗑️ [CartManager] Removed item: \(removedItem.title)")
        
        replaceCart(with: items)
    }
    
    func removeItem(withId id: Int) {
        var items = getCartItems()
        items.removeAll { $0.id == id }
        replaceCart(with: items)
    }
    
    // MARK: - Update Quantity
    
    func updateQuantity(for id: Int, quantity: Int) {
        var items = getCartItems()
        
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].qty = quantity
            print("🔄 [CartManager] Updated quantity for item \(id): qty=\(quantity)")
            replaceCart(with: items)
        }
    }
    
    // MARK: - Clear Cart
    
    func clearCart() {
        print("🗑️ [CartManager] Clearing cart")
        UserDefaults.standard.removeObject(forKey: "ItemBasketModel")
        UserDefaults.standard.removeObject(forKey: "BasketModel")
        NotificationCenter.default.post(name: CartManager.cartDidUpdateNotification, object: nil)
    }
    
    // MARK: - Cart Info
    
    func getTotalPrice() -> Double {
        return getCartItems().reduce(0) { sum, item in
            let price = Double(item.price) ?? 0
            return sum + (price * Double(item.qty))
        }
    }
    
    func getTotalItemsCount() -> Int {
        return getCartItems().reduce(0) { $0 + $1.qty }
    }
}
