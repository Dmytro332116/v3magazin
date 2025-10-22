import Foundation
import UIKit

// ✅ ЗАКОМЕНТОВАНО - більше не використовується
// FavoritesViewController тепер WebView-based і не потребує UITableView
//
// extension FavoritesViewController: UITableViewDelegate, UITableViewDataSource {
//     
//     func numberOfSections(in tableView: UITableView) -> Int {
//         return 1
//     }
//
//     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//         return favorites.count
//     }
//
//     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//         return 70
//     }
//
//     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//         let cell = tableView.dequeueReusableCell(withIdentifier: favoriteListCellIdentifier, for: indexPath) as! FavoriteListTVCell
//         let item = favorites[indexPath.row]
//         cell.configure(with: item)
//         return cell
//     }
//
//     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//         let selectedItem = favorites[indexPath.row]
//         
//         // Navigate to item details if we have an id
//         if let itemId = selectedItem.id {
//             let detailVC = CompositionRoot.sharedInstance.resolveItemDetailsViewController(id: itemId)
//             navigationController?.pushViewController(detailVC, animated: true)
//         }
//     }
// }

