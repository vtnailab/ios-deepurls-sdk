import Foundation

enum ApiClient {
    private static let postReferrerURL = "https://us-central1-v3deeplinks.cloudfunctions.net/postReferrer"
    private static let postGenerateLinkURL = "https://us-central1-v3deeplinks.cloudfunctions.net/postGenerateLink"
    
    private static var config: DeepUrlsConfig {
        DeepUrls.getConfig()
    }
    
    private static func generateNonce() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
    
    /// Canonicalizes a dictionary by sorting keys and ensuring no slash escaping.
    private static func canonicalJSON(_ dict: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else {
            return nil
        }
        // Match Kotlin SDK: .replace("\\/", "/")
        // Swift JSONSerialization escapes slashes by default.
        let jsonString = String(data: data, encoding: .utf8)
        return jsonString?.replacingOccurrences(of: "\\/", with: "/")
    }

    // MARK: - Referrer
    
    static func sendReferrer(referrer: String, bundleId: String) {
        Task {
            _ = try? await sendReferrerAsync(referrer: referrer, bundleId: bundleId)
        }
    }
    
    static func sendReferrerAsync(referrer: String, bundleId: String) async throws {
        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = generateNonce()
        
        let signaturePayloadDict: [String: Any] = [
            "appId": config.appId,
            "referrer": referrer,
            "timestamp": timestamp,
            "nonce": nonce
        ]
        
        guard let canonicalPayload = canonicalJSON(signaturePayloadDict) else {
            throw DeepUrlsError.serializationError
        }
        
        let signature = CryptoUtils.hmacSha256(data: canonicalPayload, secret: config.deepKey)
        
        var request = URLRequest(url: URL(string: postReferrerURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(timestamp)", forHTTPHeaderField: "x-timestamp")
        request.setValue(nonce, forHTTPHeaderField: "x-nonce")
        request.setValue(signature, forHTTPHeaderField: "x-signature")
        
        let body: [String: Any] = [
            "appId": config.appId,
            "referrer": referrer
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DeepUrlsError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1, nil)
        }
    }

    // MARK: - Create Link
    
    static func createLink(
        route: String,
        params: [String: Any] = [:],
        useShort: Bool = true,
        callback: @escaping (Bool, String?, String?) -> Void
    ) {
        Task {
            do {
                let (url, longUrl) = try await createLinkAsync(route: route, params: params, useShort: useShort)
                callback(true, url, longUrl)
            } catch {
                print("[DeepUrlsSDK] CreateLink error: \(error.localizedDescription)")
                callback(false, nil, nil)
            }
        }
    }
    
    static func createLinkAsync(
        route: String,
        params: [String: Any] = [:],
        useShort: Bool = true
    ) async throws -> (String?, String?) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = generateNonce()
        
        // Match Kotlin logic: signaturePayload includes appId, route, params, timestamp, nonce
        let signaturePayloadDict: [String: Any] = [
            "appId": config.appId,
            "route": route,
            "params": params,
            "timestamp": timestamp,
            "nonce": nonce
        ]
        
        guard let canonicalPayload = canonicalJSON(signaturePayloadDict) else {
            throw DeepUrlsError.serializationError
        }
        
        let signature = CryptoUtils.hmacSha256(data: canonicalPayload, secret: config.deepKey)
        
        let bodyDict: [String: Any] = [
            "appId": config.appId,
            "route": route,
            "params": params,
            "useShort": useShort,
            "timestamp": timestamp,
            "nonce": nonce
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            throw DeepUrlsError.serializationError
        }
        
        var request = URLRequest(url: URL(string: postGenerateLinkURL)!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(timestamp)", forHTTPHeaderField: "x-timestamp")
        request.setValue(nonce, forHTTPHeaderField: "x-nonce")
        request.setValue(signature, forHTTPHeaderField: "x-signature")
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepUrlsError.networkError(NSError(domain: "DeepUrlsSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        if httpResponse.statusCode == 401 {
            throw DeepUrlsError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8)
            throw DeepUrlsError.serverError(httpResponse.statusCode, errorBody)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DeepUrlsError.serializationError
        }
        
        let url = json["url"] as? String
        let longUrl = json["longUrl"] as? String
        return (url, longUrl)
    }
}
