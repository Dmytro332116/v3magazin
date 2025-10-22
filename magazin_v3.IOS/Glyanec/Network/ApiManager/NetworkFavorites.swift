import Foundation
import PromiseKit
import Alamofire

class NetworkFavorites {

static private var baseURL: String {
    return Glyanec.apiEndpoint + "api/v1/"
}

static private var addFavoriteUrl: String {
    return baseURL + "user/favorite/add/"
}

static private var getFavoritesListUrl: String {
    return baseURL + "user/favorite/list"
}

static func getFavoritesList() -> Promise<[ResultItemListModel]?> {
        return Promise<[ResultItemListModel]?> { resolver in
            NetworkSessionManager.shared
                .sessionManager
                .request(getFavoritesListUrl,
                         method: .get,
                         parameters: nil,
                         encoding: JSONEncoding.default,
                         headers: nil)
                .validate()
                .responseJSON { response in

                    guard let data = response.data else { return resolver.reject(NetworkError.nonResultError) }

                    if let errorMessage = NetworkErrorHandler.containsError(data: data) {
                        return resolver.reject(APIError(errorData: errorMessage))
                    }

                    do {
                        let result = try JSONDecoder().decode([ResultItemListModel].self, from: data)
                        return resolver.fulfill(result)
                    } catch {
                        return resolver.reject(error)
                    }
            }
        }
    }

static func addFavorite(id: String) -> Promise<Bool?> {
        return Promise<Bool?> { resolver in
            NetworkSessionManager.shared
                .sessionManager
                .request(addFavoriteUrl + id,
                         method: .post,
                         parameters: nil,
                         encoding: JSONEncoding.default,
                         headers: nil)
                .validate()
                .responseJSON { response in

                    if let statusCode = response.response?.statusCode, statusCode >= 200, statusCode <= 300 {
                        return resolver.fulfill(true)
                    }

                    guard let data = response.data else { return resolver.reject(NetworkError.nonResultError) }

                    if let errorMessage = NetworkErrorHandler.containsError(data: data) {
                        return resolver.reject(APIError(errorData: errorMessage))
                    }

                    return resolver.reject(NetworkError.nonResultError)
            }
        }
    }
}
