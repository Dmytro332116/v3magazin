import Foundation

class BasketViewModel: ViewModel, BaseAlert {
    
    var view: BasketViewProtocol!
    var list: [ItemBasketModel]?
    
    init(view: BasketViewProtocol, list: [ItemBasketModel]?) {
        self.view = view
        self.list = list
    }
    
//    NetworkBasket
    func getBasketList() {
        print("🔍 [BasketVM] getBasketList() called")
        LoadingSpinner.shared.startActivity()
        
        if let data = UserDefaults.standard.value(forKey:"ItemBasketModel") as? Data {
            self.list = try! PropertyListDecoder().decode(Array<ItemBasketModel>.self, from: data)
            print("✅ [BasketVM] Loaded \(self.list?.count ?? 0) items from UserDefaults")
            if let items = self.list {
                for (index, item) in items.enumerated() {
                    print("   📦 [\(index+1)] \(item.title) - \(item.price) грн (x\(item.qty))")
                }
            }
        } else {
            print("⚠️ [BasketVM] No data in UserDefaults, cart is empty")
            self.list = []
        }
        
        print("🔄 [BasketVM] Calling view.updateItems()...")
        self.view.updateItems()
        print("✅ [BasketVM] view.updateItems() completed")
        
        LoadingSpinner.shared.stopActivity()
    }
    
    func purchasesList() {
        LoadingSpinner.shared.startActivity()
        NetworkPurchases.purchasesList(parameters: list!)
        .done { (oModel) in
            LoadingSpinner.shared.stopActivity()
            if (oModel?.status)! {
                UserDefaults.standard.removeObject(forKey: "BasketModel")
                UserDefaults.standard.removeObject(forKey: "ItemBasketModel")
                self.list = []
                self.view.updateItems()
                self.view.openOrder(string: (oModel?.orderUrl)!)
            } else {
                let message = NetworkErrorHandler.errorMessageFrom(error: oModel?.error as? Error ?? NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])) // Provide a default Error instance
                self.displayErrorNotification(withText: message ?? "", sticky: false, action: nil, actionName: "Ok")
            }
        }
        .catch { (error) in
            LoadingSpinner.shared.stopActivity()
            print(error)
            let message = NetworkErrorHandler.errorMessageFrom(error: error)
            self.displayErrorNotification(withText: message ?? "", sticky: false, action: nil, actionName: "Ok")
        }
    }

}
