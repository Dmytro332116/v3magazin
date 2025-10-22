import UIKit

class FavoriteListTVCell: UITableViewCell {
    
    @IBOutlet weak var actionIV: UIImageView!
    @IBOutlet weak var titleL: UILabel!
    @IBOutlet weak var countL: UILabel!
    
    func configure(with item: ResultItemListModel) {
        titleL.text = item.name ?? "Без назви"
        
        if let count = item.count {
            countL.text = "\(count)"
            countL.isHidden = false
        } else {
            countL.isHidden = true
        }
        
        actionIV.image = UIImage(named: "greenArrowRight")
    }
}
