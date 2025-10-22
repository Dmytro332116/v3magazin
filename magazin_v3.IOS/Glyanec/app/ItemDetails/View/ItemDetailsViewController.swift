import UIKit
import SDWebImage

protocol ItemDetailsViewProtocol {
    func reloadTableView()
    func updateItem()
}

class ItemDetailsViewController: BaseViewController<ItemDetailsViewModel>, ItemDetailsViewProtocol {
    
    // MARK: - Outlets
    @IBOutlet weak var detailsTableView: UITableView!
    @IBOutlet weak var previevImageView: UIImageView!
    @IBOutlet weak var itemTitle0: UILabel!
    @IBOutlet weak var itemTitle1: UILabel!
    @IBOutlet weak var itemLevelTitle: UILabel!
    @IBOutlet weak var itemLevelNumberTitle: UILabel!
    
    @IBOutlet weak var closeB: UIButton!
    @IBOutlet weak var payB: UIButton!
    @IBOutlet weak var basketB: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: - Properties
    var arrayM = NSMutableArray()
    var arrayMBA = NSMutableArray()
    let itemCharacteristicsCell = "ItemCharacteristicsCell"
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        config()
        updateFavoriteButtonState() // ← перевіряємо стан сердечка
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getItemDetails()
    }
    
    func config() {
        detailsTableView.register(
            UINib(nibName: "ItemCharacteristicsCell", bundle: nil),
            forCellReuseIdentifier: itemCharacteristicsCell
        )
    }
    
    // MARK: - Update UI
    func updateCurrentItem() {
        guard let item = viewModel.itemDetails?.products.first else { return }
        
        itemLevelTitle.text = item.title
        itemTitle0.text = "\(item.price) ₴"
        
        if item.price_old != 0.0 {
            itemTitle1.text = "\(item.price_old) ₴"
            itemLevelNumberTitle.isHidden = false
            itemTitle1.isHidden = false
        } else {
            itemTitle1.isHidden = true
            itemLevelNumberTitle.isHidden = true
        }
        
        setItemPreviewImageView(image: item.images?.first ?? "")
    }
    
    func setItemPreviewImageView(image: String) {
        if let imageCache = SDImageCache.shared.imageFromCache(forKey: image) {
            previevImageView.image = imageCache
        } else if let url = URL(string: image) {
            previevImageView.sd_setImage(with: url, completed: nil)
        }
    }
    
    func updateItem() {
        updateCurrentItem()
        reloadTableView()
    }
    
    func reloadTableView() {
        detailsTableView.reloadData()
    }
    
    func closeView() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    @IBAction func closeBAction(_ sender: Any) {
        closeView()
    }
    
    @IBAction func payBAction(_ sender: Any) {
    guard let item = viewModel.itemDetails?.products.first else { return }

    var list: [ItemBasketModel] = []
    var listBasket: [BasketModel] = []

    if let data = UserDefaults.standard.value(forKey: "ItemBasketModel") as? Data {
        list = (try? PropertyListDecoder().decode([ItemBasketModel].self, from: data)) ?? []
    }
    if let data = UserDefaults.standard.value(forKey: "BasketModel") as? Data {
        listBasket = (try? PropertyListDecoder().decode([BasketModel].self, from: data)) ?? []
    }

    // Перевіряємо, чи товар уже є
    let itemId = Int(item.id ?? "0") ?? 0
    if list.contains(where: { $0.id == itemId }) {
        print("🛒 Товар вже є в кошику")
    } else {
        list.append(
            ItemBasketModel(
                id: itemId,
                title: item.title ?? "",
                price: "\(item.price)",
                image: item.images?.first ?? "",
                qty: 1
            )
        )
        listBasket.append(
            BasketModel(
                id: itemId,
                qty: 1
            )
        )
        UserDefaults.standard.set(try? PropertyListEncoder().encode(list), forKey: "ItemBasketModel")
        UserDefaults.standard.set(try? PropertyListEncoder().encode(listBasket), forKey: "BasketModel")
    }

    appDelegate?.scheduleNotification(notificationType: "✅ Товар додано в кошик", body: item.title ?? "")

    // 👉 автоматично переходимо в кошик
    if let tabBarController = self.tabBarController {
        tabBarController.selectedIndex = 3 // номер вкладки кошика
        tabBarController.tabBar.isHidden = true
    } else {
        closeView()
    }
}

    
    @IBAction func basketBAction(_ sender: Any) {
        closeView()
        tabBarController?.selectedIndex = 3
        tabBarController?.tabBar.isHidden = true
    }
    
    // MARK: - ❤️ Favorites Logic
    @IBAction func favoriteButtonAction(_ sender: Any) {
        guard let item = viewModel.itemDetails?.products.first else { return }
        
        var favorites: [ItemBasketModel] = []
        if let data = UserDefaults.standard.value(forKey: "ItemFavoriteModel") as? Data {
            favorites = (try? PropertyListDecoder().decode([ItemBasketModel].self, from: data)) ?? []
        }
        
        // toggle: додати або видалити
        if let index = favorites.firstIndex(where: { $0.id == Int(item.id ?? "0") }) {
            favorites.remove(at: index)
            favoriteButton.setImage(UIImage(named: "heartEmpty"), for: .normal)
            appDelegate?.scheduleNotification(notificationType: "Видалено з вибраного", body: item.title ?? "")
        } else {
            let newItem = ItemBasketModel(
                id: Int(item.id ?? "0") ?? 0,
                title: item.title ?? "",
                price: "\(item.price)",
                image: item.images?.first ?? "",
                qty: 1
            )
            favorites.append(newItem)
            favoriteButton.setImage(UIImage(named: "heartFilled"), for: .normal)
            appDelegate?.scheduleNotification(notificationType: "Додано у вибране", body: item.title ?? "")
        }
        
        // зберігаємо
        UserDefaults.standard.set(try? PropertyListEncoder().encode(favorites), forKey: "ItemFavoriteModel")
        
        // анімація ❤️
        animateFavoriteButton()
    }
    
    func updateFavoriteButtonState() {
        guard let item = viewModel.itemDetails?.products.first else { return }
        if let data = UserDefaults.standard.value(forKey: "ItemFavoriteModel") as? Data,
           let list = try? PropertyListDecoder().decode([ItemBasketModel].self, from: data),
           list.contains(where: { $0.id == Int(item.id ?? "0") }) {
            favoriteButton.setImage(UIImage(named: "heartFilled"), for: .normal)
        } else {
            favoriteButton.setImage(UIImage(named: "heartEmpty"), for: .normal)
        }
    }
    
    // MARK: - ❤️ Animation
    func animateFavoriteButton() {
        UIView.animate(withDuration: 0.1,
                       animations: { self.favoriteButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3) }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.favoriteButton.transform = .identity
            }
        }
    }
}
