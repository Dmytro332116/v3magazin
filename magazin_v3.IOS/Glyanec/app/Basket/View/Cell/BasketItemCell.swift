import UIKit
import SDWebImage

protocol BasketItemCellDelegate: class {
    func removeItem(row: Int, itemTitle: String)
    func increaseQuantity(row: Int)
    func decreaseQuantity(row: Int)
}

class BasketItemCell: UITableViewCell {
    
    @IBOutlet weak var itemIV: UIImageView!
    @IBOutlet weak var favoriteB: UIButton!
    
    @IBOutlet weak var titleL: UILabel!
    @IBOutlet weak var priceL: UILabel!
    @IBOutlet weak var sumPriceL: UILabel!
    @IBOutlet weak var counterL: UILabel!
    
    // Кнопки для зміни кількості (створюються програмно)
    private var decreaseButton: UIButton!
    private var increaseButton: UIButton!
    private var quantityStackView: UIStackView!
    
    // Кнопка видалення поверх фото (як на сайті)
    private var deleteButton: UIButton!
    
    weak var delegate: BasketItemCellDelegate?
    var itemIndex: Int? = nil
    var currentItem: ItemBasketModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupQuantityControls()
        setupDeleteButton()
    }
    
    private func setupDeleteButton() {
        // Створюємо кнопку видалення (червоне коло з білою іконкою смітника)
        deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Налаштування іконки смітника
        let trashIcon = UIImage(systemName: "trash.fill")
        deleteButton.setImage(trashIcon, for: .normal)
        deleteButton.tintColor = .white
        
        // Стиль кнопки
        deleteButton.backgroundColor = UIColor.systemRed
        deleteButton.layer.cornerRadius = 16  // Половина від 32x32 = круг
        deleteButton.layer.shadowColor = UIColor.black.cgColor
        deleteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        deleteButton.layer.shadowRadius = 3
        deleteButton.layer.shadowOpacity = 0.3
        
        // Підключаємо action
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Додаємо кнопку ПОВЕРХ фото
        contentView.addSubview(deleteButton)
        
        // Constraints - лівий верхній кут фото з відступами
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: 32),
            deleteButton.heightAnchor.constraint(equalToConstant: 32),
            deleteButton.leadingAnchor.constraint(equalTo: itemIV.leadingAnchor, constant: 6),
            deleteButton.topAnchor.constraint(equalTo: itemIV.topAnchor, constant: 6)
        ])
        
        // Переміщуємо кнопку на передній план
        contentView.bringSubviewToFront(deleteButton)
    }
    
    private func setupQuantityControls() {
        // Створюємо кнопку зменшення (стиль як на сайті - зелена рамка)
        decreaseButton = UIButton(type: .system)
        decreaseButton.setTitle("−", for: .normal)
        decreaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        decreaseButton.setTitleColor(UIColor.systemGreen, for: .normal)
        decreaseButton.setTitleColor(UIColor.systemGray, for: .disabled)
        decreaseButton.backgroundColor = .white
        decreaseButton.layer.borderWidth = 1.5
        decreaseButton.layer.borderColor = UIColor.systemGreen.cgColor
        decreaseButton.layer.cornerRadius = 6
        decreaseButton.addTarget(self, action: #selector(decreaseButtonTapped), for: .touchUpInside)
        decreaseButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Створюємо кнопку збільшення (стиль як на сайті - зелена рамка)
        increaseButton = UIButton(type: .system)
        increaseButton.setTitle("+", for: .normal)
        increaseButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        increaseButton.setTitleColor(UIColor.systemGreen, for: .normal)
        increaseButton.backgroundColor = .white
        increaseButton.layer.borderWidth = 1.5
        increaseButton.layer.borderColor = UIColor.systemGreen.cgColor
        increaseButton.layer.cornerRadius = 6
        increaseButton.addTarget(self, action: #selector(increaseButtonTapped), for: .touchUpInside)
        increaseButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Показуємо label кількості
        counterL.isHidden = false
        counterL.textAlignment = .center
        counterL.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        // Створюємо stack view для контролів кількості
        quantityStackView = UIStackView(arrangedSubviews: [decreaseButton, counterL, increaseButton])
        quantityStackView.axis = .horizontal
        quantityStackView.spacing = 8
        quantityStackView.alignment = .center
        quantityStackView.distribution = .equalSpacing
        quantityStackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(quantityStackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            decreaseButton.widthAnchor.constraint(equalToConstant: 30),
            decreaseButton.heightAnchor.constraint(equalToConstant: 30),
            
            counterL.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),
            
            increaseButton.widthAnchor.constraint(equalToConstant: 30),
            increaseButton.heightAnchor.constraint(equalToConstant: 30),
            
            quantityStackView.leadingAnchor.constraint(equalTo: itemIV.trailingAnchor, constant: 13),
            quantityStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func config(item: ItemBasketModel, row: Int) {
        currentItem = item
        itemIndex = row
        titleL.text = item.title
        
        // Очищаємо ціну від пробілів та конвертуємо
        let cleanPrice = item.price.replacingOccurrences(of: " ", with: "")
        let price = Double(cleanPrice) ?? 0
        
        // Відображаємо ціну за одиницю
        priceL.text = String(format: "%.0f %@", price, "₴")
        
        counterL.text = "\(item.qty) шт"
        
        // Розраховуємо загальну суму (ціна × кількість)
        let totalPrice = price * Double(item.qty)
        sumPriceL.text = String(format: "%.0f %@", totalPrice, "₴")
        
        setItemPreviewImageView(image: item.image)
        
        // Блокуємо кнопку "-" якщо кількість = 1 (зі зміною стилю)
        decreaseButton.isEnabled = item.qty > 1
        if item.qty > 1 {
            decreaseButton.layer.borderColor = UIColor.systemGreen.cgColor
            decreaseButton.alpha = 1.0
        } else {
            decreaseButton.layer.borderColor = UIColor.systemGray3.cgColor
            decreaseButton.alpha = 0.5
        }
        
        print("💰 [Cell] Configured: \(item.title), price=\(price), qty=\(item.qty), total=\(totalPrice)")
    }
    
    func setItemPreviewImageView(image:String) {
        if let imageCache = SDImageCache.shared.imageFromCache(forKey: image) {
            itemIV.image = imageCache
        } else {
            if let url = URL(string: image) {
                itemIV.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    @objc private func deleteButtonTapped() {
        // Нова кнопка видалення поверх фото
        guard let index = itemIndex, let title = titleL.text else { return }
        print("🗑️ [Cell] Delete button tapped for row \(index)")
        delegate?.removeItem(row: index, itemTitle: title)
    }
    
    @objc private func decreaseButtonTapped() {
        guard let index = itemIndex else { return }
        delegate?.decreaseQuantity(row: index)
    }
    
    @objc private func increaseButtonTapped() {
        guard let index = itemIndex else { return }
        delegate?.increaseQuantity(row: index)
    }
}
