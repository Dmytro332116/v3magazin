import Foundation

// ✅ ЗАКОМЕНТОВАНО - більше не використовується
// FavoritesViewController тепер WebView-based і не потребує ViewModel
//
// class FavoritesViewModel: ViewModel, BaseAlert {
//
//     var view: FavoritesViewProtocol!
//     private var items: [ResultItemListModel] = []
//
//     init(view: FavoritesViewProtocol) {
//         self.view = view
//     }
//
//     func getFavoritesItems() -> [ResultItemListModel] {
//         return items
//     }
//
//     func getFavoritesList() {
//         LoadingSpinner.shared.startActivity()
//         NetworkFavorites.getFavoritesList()
//             .done { model in
//                 LoadingSpinner.shared.stopActivity()
//                 if let model = model { self.items = model }
//                 self.view.updateCollection()
//             }
//             .catch { error in
//                 LoadingSpinner.shared.stopActivity()
//                 self.view.updateCollection()
//                 let message = NetworkErrorHandler.errorMessageFrom(error: error)
//                 self.displayErrorNotification(withText: message ?? "", sticky: false, action: nil, actionName: "Ok")
//             }
//     }
//
//     func addFavorite(id: String) {
//         LoadingSpinner.shared.startActivity()
//         NetworkFavorites.addFavorite(id: id)
//             .done { _ in
//                 LoadingSpinner.shared.stopActivity()
//
//                 if let idx = self.items.firstIndex(where: { $0.id == id }) {
//                     self.items.remove(at: idx)
//                 } else {
//                     self.items.append(ResultItemListModel(id: id))
//                 }
//
//                 self.view.updateCollection()
//             }
//             .catch { error in
//                 LoadingSpinner.shared.stopActivity()
//                 let message = NetworkErrorHandler.errorMessageFrom(error: error)
//                 self.displayErrorNotification(withText: message ?? "", sticky: false, action: nil, actionName: "Ok")
//             }
//     }
// }
