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
    
    /// Create a deep link using a completion handler.
    /// - Parameters:
    ///   - route: The route path (e.g. "promo/offer")
    ///   - params: Optional query parameters as key-value pairs
    ///   - useShort: If true, returns a short link; otherwise a long link
    ///   - callback: Called on completion with (success, url, longUrl)
    public static func createLink(
        route: String,
        params: [String: Any] = [:],
        useShort: Bool = true,
        previewTitle: String = "",
        previewDescription: String = "",
        previewImage: String? = nil,
        previewImageFileURL: URL? = nil,
        campaignData: [String: Any] = [:],
        callback: @escaping (Bool, String?, String?) -> Void
    ) {
        ApiClient.createLink(
            route: route,
            params: params,
            useShort: useShort,
            previewTitle: previewTitle,
            previewDescription: previewDescription,
            previewImage: previewImage,
            previewImageFileURL: previewImageFileURL,
            campaignData: campaignData,
            callback: callback
        )
    }
    
    /// Create a deep link using async/await.
    /// - Parameters:
    ///   - route: The route path (e.g. "promo/offer")
    ///   - params: Optional query parameters as key-value pairs
    ///   - useShort: If true, returns a short link; otherwise a long link
    /// - Returns: A tuple containing (shortUrl, longUrl)
    /// - Throws: `DeepUrlsError` if the request fails
    public static func createLink(
        route: String,
        params: [String: Any] = [:],
        useShort: Bool = true,
        previewTitle: String = "",
        previewDescription: String = "",
        previewImage: String? = nil,
        previewImageFileURL: URL? = nil,
        campaignData: [String: Any] = [:]
    ) async throws -> (String?, String?) {
        try await ApiClient.createLinkAsync(
            route: route,
            params: params,
            useShort: useShort,
            previewTitle: previewTitle,
            previewDescription: previewDescription,
            previewImage: previewImage,
            previewImageFileURL: previewImageFileURL,
            campaignData: campaignData
        )
    }
    
    /// Call this when you receive referrer data from a deep link or attribution provider.
    /// - Parameter referrer: The referrer string containing clickId
    public static func reportReferrer(_ referrer: String) {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        ReferrerManager.reportReferrer(referrer: referrer, bundleId: bundleId)
    }
    
    /// Handles incoming deeplink URLs when the app is opened via a link.
    ///
    /// This method should be called from your app's entry points such as `application(_:open:options:)` 
    /// on iOS/macOS or `WindowGroup.onOpenURL` in SwiftUI.
    ///
    /// The SDK will:
    /// 1. Automatically parse the URL into a ``DeepLinkResult``.
    /// 2. Report any attribution data (like `clickId`) to the backend.
    /// 3. Invoke your custom handler for in-app navigation.
    ///
    /// - Parameters:
    ///   - url: The URL that opened your app.
    ///   - onHandled: An optional closure called with the parsed route and parameters.
    /// - Returns: `true` if the SDK recognized and handled the URL; otherwise `false`.
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
