import UIKit

protocol BasketPriceCellDelegate: class {
    func updatePrice(price: Double)
}

class BasketPriceCell: UITableViewCell {
    
    @IBOutlet weak var title0L: UILabel!
    @IBOutlet weak var title1L: UILabel!
    @IBOutlet weak var price0L: UILabel!
    @IBOutlet weak var price1L: UILabel!
    
    weak var delegate: BasketPriceCellDelegate?
    
    func config(list: [ItemBasketModel]) {        
        title0L.text = "Товари"
        title1L.text = "Загальна вартість"
        price0L.text = String(format: "%@ %@", String(purchaseСalculation(list: list)), "₴")
        price1L.text = String(format: "%@ %@", String(purchaseСalculation(list: list)), "₴")
        
        self.delegate?.updatePrice(price: purchaseСalculation(list: list))
    }
    
    func purchaseСalculation(list: [ItemBasketModel]) -> Double {
        var totalPrise: Double = 0.0
        
        for item in list {
            // Ціна * кількість для кожного товару
            let price = Double(item.price.replacingOccurrences(of: " ", with: "")) ?? 0.0
            let quantity = Double(item.qty)
            totalPrise = totalPrise + (price * quantity)
        }
        
        return totalPrise
    }
}
