import Foundation

/// Main entry point for the DeepUrls SDK.
public enum DeepUrls {
    private static var _config: DeepUrlsConfig?
    private static let lock = NSLock()
    
    /// Initialize the SDK with app credentials.
    /// - Parameters:
    ///   - appId: Your app ID from the DeepUrls dashboard
    ///   - deepKey: Your deep key for signing requests
    ///   - referrer: Optional. If you have referrer data (e.g. from a launch URL), pass it here to report to the backend
    public static func configure(appId: String, deepKey: String, referrer: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        _config = DeepUrlsConfig(appId: appId, deepKey: deepKey)
        
        if let referrer = referrer, let bundleId = Bundle.main.bundleIdentifier {
            ReferrerManager.reportReferrer(referrer: referrer, bundleId: bundleId)
        }
    }
    
    /// Create a deep link. The callback receives (success, shortUrl, longUrl).
    /// - Parameters:
    ///   - route: The route path (e.g. "promo/offer")
    ///   - params: Optional query parameters as key-value pairs
    ///   - useShort: If true, returns a short link; otherwise a long link
    ///   - callback: Called on completion with (success, url, longUrl)
    public static func createLink(
        route: String,
        params: [String: Any] = [:],
        useShort: Bool = true,
        callback: @escaping (Bool, String?, String?) -> Void
    ) {
        ApiClient.createLink(route: route, params: params, useShort: useShort, callback: callback)
    }
    
    /// Call this when you receive referrer data from a deep link or attribution provider.
    /// - Parameter referrer: The referrer string containing clickId
    public static func reportReferrer(_ referrer: String) {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        ReferrerManager.reportReferrer(referrer: referrer, bundleId: bundleId)
    }
    
    /// Handle incoming deeplink URLs when the app is opened via a link.
    /// Call from `application(_:open:options:)` or `scene(_:openURLContexts:)`.
    /// Reports referrer automatically if URL contains clickId, and invokes the handler for in-app navigation.
    ///
    /// - Parameters:
    ///   - url: The URL that opened your app
    ///   - onHandled: Called with parsed route and params; use to navigate to the appropriate screen
    /// - Returns: `true` if handled
    @discardableResult
    public static func handleOpenURL(
        _ url: URL,
        onHandled: ((DeepLinkResult) -> Void)? = nil
    ) -> Bool {
        DeepLinkHandler.handle(url: url, onHandled: onHandled)
    }
    
    internal static func getConfig() -> DeepUrlsConfig {
        lock.lock()
        defer { lock.unlock() }
        
        guard let config = _config else {
            fatalError("DeepUrls SDK not initialized. Call DeepUrls.configure(appId:deepKey:) first.")
        }
        return config
    }
}
