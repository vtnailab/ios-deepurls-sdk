import Foundation

enum ApiClient {
    private static let postReferrerURL = "https://us-central1-v3deeplinks.cloudfunctions.net/postReferrer"
    private static let postGenerateLinkURL = "https://us-central1-v3deeplinks.cloudfunctions.net/postGenerateLink"
    
    private static var config: DeepUrlsConfig {
        DeepUrls.getConfig()
    }
    
    private static func generateNonce() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    /// Sends install referrer to the backend (call when you have referrer data, e.g. from a deep link or attribution provider).
    static func sendReferrer(referrer: String, bundleId: String) {
        let timestamp = "\(Int(Date().timeIntervalSince1970))"
        let nonce = generateNonce()
        let signaturePayload = """
            {"appId":"\(config.appId)","referrer":"\(referrer)","timestamp":\(timestamp),"nonce":"\(nonce)"}
            """
        let signature = CryptoUtils.hmacSha256(data: signaturePayload, secret: config.deepKey)
        
        var request = URLRequest(url: URL(string: postReferrerURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(timestamp, forHTTPHeaderField: "x-timestamp")
        request.setValue(nonce, forHTTPHeaderField: "x-nonce")
        request.setValue(signature, forHTTPHeaderField: "x-signature")
        
        let body: [String: Any] = [
            "appId": config.appId,
            "referrer": referrer
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("[DeepUrlsSDK] Failed to send referrer: \(error)")
            }
        }.resume()
    }
    
    /// Creates a deep link. Callback returns (success, shortUrl, longUrl).
    static func createLink(
        route: String,
        params: [String: Any] = [:],
        useShort: Bool = true,
        callback: @escaping (Bool, String?, String?) -> Void
    ) {
        let timestamp = "\(Int(Date().timeIntervalSince1970))"
        let nonce = generateNonce()
        
        let paramsJson: String
        if let data = try? JSONSerialization.data(withJSONObject: params),
           let str = String(data: data, encoding: .utf8) {
            paramsJson = str
        } else {
            paramsJson = "{}"
        }
        
        let signaturePayload = """
            {"appId":"\(config.appId)","route":"\(route)","params":\(paramsJson),"timestamp":\(Int(timestamp) ?? 0),"nonce":"\(nonce)"}
            """
        let signature = CryptoUtils.hmacSha256(data: signaturePayload, secret: config.deepKey)
        
        let bodyDict: [String: Any] = [
            "appId": config.appId,
            "route": route,
            "params": params,
            "useShort": useShort,
            "timestamp": Int(timestamp) ?? 0,
            "nonce": nonce
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            print("[DeepUrlsSDK] CreateLink error: Failed to serialize request body")
            callback(false, nil, nil)
            return
        }
        
        var request = URLRequest(url: URL(string: postGenerateLinkURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(timestamp, forHTTPHeaderField: "x-timestamp")
        request.setValue(nonce, forHTTPHeaderField: "x-nonce")
        request.setValue(signature, forHTTPHeaderField: "x-signature")
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DeepUrlsSDK] CreateLink error: \(error)")
                callback(false, nil, nil)
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let errorBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
                print("[DeepUrlsSDK] CreateLink error: HTTP \(statusCode), body: \(errorBody)")
                callback(false, nil, nil)
                return
            }
            
            let url = json["url"] as? String
            let longUrl = json["longUrl"] as? String
            callback(true, url, longUrl)
        }.resume()
    }
}
