import UIKit
import SDWebImage
import UserNotifications

class MainItemCell: UICollectionViewCell, BaseAlert, UNUserNotificationCenterDelegate  {
    
    @IBOutlet weak var discountV: UIView!
    @IBOutlet weak var itemIV: UIImageView!
    @IBOutlet weak var discountLabel: UILabel!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var oldPriceLabel: UILabel!
    @IBOutlet weak var newPriceLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var buyButton: UIButton!
    
    var item: ResultProductModel!
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateFavoriteIcon() // коли клітинка створюється
    }

    func config(item: ResultProductModel) {
        self.item = item
        itemTitleLabel.text = item.title
        newPriceLabel.text = String(format: "%@ %@", String(item.price ?? 0), "₴")
        
        if let old = item.price_old, old != 0 {
            oldPriceLabel.text = String(format: "%@ %@", String(old), "₴")
            discountLabel.text = "-5%"
            discountLabel.isHidden = false
            oldPriceLabel.isHidden = false
            discountV.isHidden = false
        } else {
            oldPriceLabel.isHidden = true
            discountLabel.isHidden = true
            discountV.isHidden = true
        }

        if let images = item.images, let first = images.first {
            setItemPreviewImageView(image: first)
        }
        updateFavoriteIcon()
    }
    
    func setItemPreviewImageView(image: String) {
        if let cached = SDImageCache.shared.imageFromCache(forKey: image) {
            itemIV.image = cached
        } else if let url = URL(string: image) {
            itemIV.sd_setImage(with: url)
        }
    }

    // MARK: - Favorite logic
    @IBAction func folowItemAction(_ sender: Any) {
        guard let id = item?.id else { return }
        var favorites: [ItemBasketModel] = []
        if let data = UserDefaults.standard.value(forKey: "ItemFavoriteModel") as? Data {
            favorites = (try? PropertyListDecoder().decode([ItemBasketModel].self, from: data)) ?? []
        }

        if let index = favorites.firstIndex(where: { String($0.id) == id }) {
            favorites.remove(at: index)
            appDelegate?.scheduleNotification(notificationType: "Видалено з вибраного", body: item.title ?? "")
        } else {
            let imageStr = item.images?.first ?? ""
            favorites.append(
                ItemBasketModel(id: Int(id) ?? 0,
                                title: item.title ?? "",
                                price: String(item.price ?? 0),
                                image: imageStr,
                                qty: 1)
            )
            appDelegate?.scheduleNotification(notificationType: "Товар додано у вибране", body: item.title ?? "")
        }

        UserDefaults.standard.set(try? PropertyListEncoder().encode(favorites), forKey: "ItemFavoriteModel")
        updateFavoriteIcon()
    }

    @IBAction func buyItemAction(_ sender: Any) {
    guard let item = self.item else {
        print("⚠️ Item = nil — не вдалося додати в кошик")
        return
    }
    
    let itemId = Int(item.id ?? "") ?? 0
    let imageString = item.images?.first ?? ""
    var list: [ItemBasketModel] = []
    var listBasket: [BasketModel] = []
    
    // 1️⃣ Зчитуємо попередні дані з UserDefaults
    if let data = UserDefaults.standard.value(forKey: "ItemBasketModel") as? Data {
        list = (try? PropertyListDecoder().decode([ItemBasketModel].self, from: data)) ?? []
    }
    if let data = UserDefaults.standard.value(forKey: "BasketModel") as? Data {
        listBasket = (try? PropertyListDecoder().decode([BasketModel].self, from: data)) ?? []
    }

    // 2️⃣ Перевіряємо, чи товар уже є в кошику
    if list.contains(where: { $0.id == itemId }) {
        print("🛒 \(item.title ?? "") вже є в кошику — не дублюємо")
        return
    }

    // 3️⃣ Додаємо новий товар
    list.append(
        ItemBasketModel(id: itemId,
                        title: item.title ?? "",
                        price: String(item.price ?? 0),
                        image: imageString,
                        qty: 1)
    )
    listBasket.append(BasketModel(id: itemId, qty: 1))
    
    // 4️⃣ Зберігаємо назад у UserDefaults
    UserDefaults.standard.set(try? PropertyListEncoder().encode(list), forKey: "ItemBasketModel")
    UserDefaults.standard.set(try? PropertyListEncoder().encode(listBasket), forKey: "BasketModel")

    // 5️⃣ Повідомлення і лог у консоль
    self.appDelegate?.scheduleNotification(notificationType: "Товар додано в кошик", body: item.title ?? "")
    print("✅ Додано в кошик:", item.title ?? "")
}


    private func updateFavoriteIcon() {
        guard let id = item?.id else { return }
        var favorites: [ItemBasketModel] = []
        if let data = UserDefaults.standard.value(forKey: "ItemFavoriteModel") as? Data {
            favorites = (try? PropertyListDecoder().decode([ItemBasketModel].self, from: data)) ?? []
        }

        let isFav = favorites.contains { String($0.id) == id }
        let imageName = isFav ? "heartFavorite" : "heartUnFavorite"
        favoriteButton.setImage(UIImage(named: imageName), for: .normal)
    }
}
