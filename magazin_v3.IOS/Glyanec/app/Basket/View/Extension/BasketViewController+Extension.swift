import Foundation
import UIKit
import SDWebImage

extension BasketViewController: UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count: Int
        switch section {
        case 0:
            count = viewModel.list?.count ?? 0
            print("📊 [TableView] numberOfRowsInSection[\(section)] = \(count) items")
            return count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 100
        default:
            return 126
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 100
        default:
            return 126
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("📦 [TableView] cellForRowAt section:\(indexPath.section) row:\(indexPath.row)")
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: basketItemCellInditifer, for: indexPath) as! BasketItemCell
            if let item = viewModel.list?[indexPath.row] {
                print("   ✅ Configuring cell with: \(item.title)")
                cell.config(item: item, row: indexPath.row)
                cell.delegate = self
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: basketPriceCellInditifer, for: indexPath) as! BasketPriceCell
            if let list = viewModel.list {
                cell.config(list: list)
                cell.delegate = self
            }
            return cell
        }
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
