import Foundation
import Alamofire

class Glyanec {
    
    static var apiEndpoint: String {
        return "https://webmagazin-app.glyanec.net/"
    }
}

class NetworkSessionManager {
    
    static let shared = NetworkSessionManager()
    var sessionManager: SessionManager
    
    init() {
        let configuration = URLSessionConfiguration.default
        var headers = SessionManager.defaultHTTPHeaders
        let accessToken = KeyChain.get(key:  KeyConstant.userToken) ?? "WzTZJtUNG36trFejyndUngbKuye5AGH9"

        headers["Content-Type"] = "application/json"
        headers["accept-language"] = Locale.current.languageCode
        
        if accessToken.count > 0 {
            headers["x-token"] = "WzTZJtUNG36trFejyndUngbKuye5AGH9"
        }
        
        configuration.httpAdditionalHeaders = headers
        configuration.timeoutIntervalForRequest = 60.0
                
        self.sessionManager = SessionManager(
            configuration: configuration
        )
//        [
//        self.sessionManager = SessionManager(
//            configuration: configuration
//        )
        
//        let adapter = JWTAccessTokenAdapter()
//        self.sessionManager.adapter = adapter
//        self.sessionManager.retrier = adapter
    }
}
