import UIKit
import SDWebImage

protocol BasketViewProtocol: BaseAlert {
    func config()
    func reloadTableView()
    func updateItems()
    func openOrder(string: String)
}

class BasketViewController: BaseViewController<BasketViewModel>, BasketViewProtocol {
    
    @IBOutlet weak var basketTV: UITableView!
    
    @IBOutlet weak var basketV: UIView!
    @IBOutlet weak var basketControlV: UIView!
    
    @IBOutlet weak var buyB: UIButton!
    
    let basketPriceCellInditifer = "BasketPriceCell"
    let basketItemCellInditifer = "BasketItemCell"
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
        
        // ✅ Підписуємося на оновлення кошика через CartManager
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cartDidUpdate),
            name: CartManager.cartDidUpdateNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // ✅ Обробник оновлення кошика
    @objc func cartDidUpdate() {
        print("📨 [BasketVC] ========================================")
        print("📨 [BasketVC] NOTIFICATION RECEIVED: CartManagerDidUpdate")
        print("📨 [BasketVC] Thread: \(Thread.isMainThread ? "MAIN ✅" : "BACKGROUND ⚠️")")
        print("📨 [BasketVC] Calling viewModel.getBasketList()...")
        
        viewModel.getBasketList()
        
        print("📨 [BasketVC] After getBasketList(), list count: \(viewModel.list?.count ?? 0)")
        print("📨 [BasketVC] ========================================")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ ВАЖЛИВО: Фіксуємо колір навігації (завжди чорний)
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.isHidden = false
        
        // 🔄 Запитуємо синхронізацію з WebView
        print("🔄 Requesting cart sync from WebView...")
        NotificationCenter.default.post(name: NSNotification.Name("RequestCartSync"), object: nil)
        
        // Затримка, щоб дати час JavaScript зчитати дані
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.getBasketList()
        }
        
        // ✅ TabBar завжди видимий - не ховаємо його
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateItems()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
    }

    func config() {
        basketTV.register(UINib(nibName: "BasketItemCell", bundle: nil), forCellReuseIdentifier: basketItemCellInditifer)
        basketTV.register(UINib(nibName: "BasketPriceCell", bundle: nil), forCellReuseIdentifier: basketPriceCellInditifer)
        
        basketV.roundExtensionCorners(corners: [.topLeft, .topRight], radius: 20.0)
        basketControlV.roundExtensionCorners(corners: [.topLeft, .topRight], radius: 15.0)
        basketV.shadow()
        basketControlV.shadow()
    }
    
    func reloadTableView() {
        print("🔄 [BasketVC] reloadTableView() - calling basketTV.reloadData()")
        print("📊 [BasketVC] viewModel.list count: \(viewModel.list?.count ?? 0)")
        basketTV.reloadData()
        print("✅ [BasketVC] basketTV.reloadData() completed")
    }
    
    func updateItems() {
        print("🔄 [BasketVC] updateItems() called")
        reloadTableView()
    }
    
    func openOrder(string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
    
    func openOrderInWebView() {
        print("🛒 [BasketVC] Opening order page in WebView")
        
        // Створюємо WebViewController програмно (без сториборда)
        let webVC = WebStoreViewController()
        webVC.urlString = "https://v3magazin.glyanec.net/basket/order"
        webVC.title = "Оформлення замовлення"
        
        // ✅ КРИТИЧНО: TabBar має залишатись видимим
        webVC.hidesBottomBarWhenPushed = false
        
        // ✅ Відкриваємо через PUSH — tab bar залишається видимим
        navigationController?.pushViewController(webVC, animated: true)
        
        print("✅ [BasketVC] Pushed order WebView to navigation stack")
    }

    @objc func reloadData() {
//        viewModel.getCategoryProducts()
    }
    
    @IBAction func backBAction(_ sender: Any) {
        // Переключаємось на головну вкладку
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func buyBAction(_ sender: Any) {
        print("🛒 [BasketVC] Buy button tapped")
        
        // Перевіряємо чи є товари в кошику
        if let list = viewModel.list, !list.isEmpty {
            // Відкриваємо сторінку оформлення замовлення у WebView
            openOrderInWebView()
        } else {
            // Показуємо алерт що кошик порожній
            let alert = UIAlertController(
                title: "Кошик порожній",
                message: "Додайте товари перед оформленням замовлення.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

extension BasketViewController: BasketPriceCellDelegate {
    func updatePrice(price: Double) {
        let price = String(price)
        buyB.setTitle(String(format: "Оформити %@ ", price, "₴"), for: .normal)
    }
}

extension BasketViewController: BasketItemCellDelegate {
    func removeItem(row: Int, itemTitle: String) {
        print("🗑️ [BasketVC] Removing item at row \(row)")
        
        guard let list = viewModel.list, row < list.count else {
            print("⚠️ [BasketVC] Invalid row index")
            return
        }
        
        let item = list[row]
        
        // Показуємо підтвердження видалення
        let alert = UIAlertController(
            title: "Видалити товар?",
            message: "Ви впевнені, що хочете видалити \"\(itemTitle)\" з кошика?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            print("✅ [BasketVC] User confirmed deletion")
            
            // Зберігаємо кількість товарів ДО видалення
            let itemsBeforeDelete = self.viewModel.list?.count ?? 0
            
            // ✅ ВАЖЛИВО: Тимчасово відписуємось від notification, щоб уникнути подвійного оновлення
            NotificationCenter.default.removeObserver(self, name: CartManager.cartDidUpdateNotification, object: nil)
            
            // Видаляємо товар з CartManager (це оновить дані)
            CartManager.shared.removeItem(at: row)
            
            // Оновлюємо дані з затримкою для синхронізації
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewModel.getBasketList()
                
                let itemsAfterDelete = self.viewModel.list?.count ?? 0
                print("🧮 [BasketVC] Before: \(itemsBeforeDelete), After: \(itemsAfterDelete)")
                
                // Просто перезавантажуємо таблицю - це найбезпечніший спосіб
                self.basketTV.reloadData()
                print("✅ [BasketVC] Table reloaded after deletion")
                
                // Підписуємось назад на notifications
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.cartDidUpdate),
                    name: CartManager.cartDidUpdateNotification,
                    object: nil
                )
                
                // Синхронізуємо з Drupal
                self.syncDeletionWithWebView(itemId: item.id)
                
                // Показуємо нотифікацію
                self.appDelegate?.scheduleNotification(
                    notificationType: "Товар видалений з кошика",
                    body: itemTitle
                )
            }
        })
        
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        
        // На iPad треба вказати sourceView для action sheet
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.basketTV
            popover.sourceRect = self.basketTV.rectForRow(at: IndexPath(row: row, section: 0))
        }
        
        self.present(alert, animated: true)
    }
    
    private func syncDeletionWithWebView(itemId: Int) {
        print("🔄 [BasketVC] Syncing deletion with WebView: id=\(itemId)")
        
        // Відправляємо подію для синхронізації з WebView
        NotificationCenter.default.post(
            name: NSNotification.Name("DeleteCartItem"),
            object: nil,
            userInfo: ["itemId": itemId]
        )
    }
    
    func increaseQuantity(row: Int) {
        print("➕ [BasketVC] Increasing quantity for row \(row)")
        
        guard let list = viewModel.list, row < list.count else {
            print("⚠️ [BasketVC] Invalid row index")
            return
        }
        
        let item = list[row]
        let newQty = item.qty + 1
        
        print("   Current qty: \(item.qty), new qty: \(newQty)")
        
        // Оновлюємо через CartManager
        CartManager.shared.updateQuantity(for: item.id, quantity: newQty)
        
        // Синхронізуємо з Drupal (опціонально)
        syncQuantityWithWebView(itemId: item.id, newQuantity: newQty)
    }
    
    func decreaseQuantity(row: Int) {
        print("➖ [BasketVC] Decreasing quantity for row \(row)")
        
        guard let list = viewModel.list, row < list.count else {
            print("⚠️ [BasketVC] Invalid row index")
            return
        }
        
        let item = list[row]
        
        // Не дозволяємо зменшити нижче 1
        if item.qty <= 1 {
            print("⚠️ [BasketVC] Cannot decrease below 1")
            return
        }
        
        let newQty = item.qty - 1
        
        print("   Current qty: \(item.qty), new qty: \(newQty)")
        
        // Оновлюємо через CartManager
        CartManager.shared.updateQuantity(for: item.id, quantity: newQty)
        
        // Синхронізуємо з Drupal (опціонально)
        syncQuantityWithWebView(itemId: item.id, newQuantity: newQty)
    }
    
    private func syncQuantityWithWebView(itemId: Int, newQuantity: Int) {
        // Відправляємо подію для синхронізації з WebView
        print("🔄 [BasketVC] Syncing quantity with WebView: id=\(itemId), qty=\(newQuantity)")
        
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateCartQuantity"),
            object: nil,
            userInfo: ["itemId": itemId, "quantity": newQuantity]
        )
    }
}
