import Foundation

/// Result of parsing an incoming deep link.
public struct DeepLinkResult {
    /// The route path (e.g. "promo/offer" or path components joined)
    public let route: String
    /// Query parameters from the URL
    public let params: [String: String]
    /// The original URL
    public let url: URL
    
    public init(route: String, params: [String: String], url: URL) {
        self.route = route
        self.params = params
        self.url = url
    }
}

/// Handles incoming deeplink URLs when the app is opened via a link.
public enum DeepLinkHandler {
    private static let mockBundleId = "com.deepurls.sdk.mock"
    
    /// Call this when your app receives a URL from `application(_:open:options:)` or `scene(_:openURLContexts:)`.
    /// The SDK will:
    /// 1. Report referrer to the backend if the URL contains `clickId` (for attribution)
    /// 2. Invoke the handler callback with parsed route and params so you can navigate in-app
    ///
    /// - Parameters:
    ///   - url: The URL that opened your app (e.g. from `options[.url]` or `URLContext.url`)
    ///   - onHandled: Called when the URL is recognized; use to navigate to the appropriate screen
    /// - Returns: `true` if the SDK handled the URL (reported referrer and/or invoked handler); `false` otherwise
    @discardableResult
    public static func handle(
        url: URL,
        onHandled: ((DeepLinkResult) -> Void)? = nil
    ) -> Bool {
        let bundleId = Bundle.main.bundleIdentifier ?? mockBundleId
        
        let result = parse(url: url)
        
        // Build referrer string from query (e.g. clickId=abc&utm_source=...)
        if result.params["clickId"] != nil, let query = url.query {
            ReferrerManager.reportReferrer(referrer: query, bundleId: bundleId)
        }
        
        onHandled?(result)
        return true
    }
    
    /// Parses a deep link URL into a `DeepLinkResult`.
    /// - Parameter url: The incoming deep link URL.
    /// - Returns: A `DeepLinkResult` containing the route and parameters.
    public static func parse(url: URL) -> DeepLinkResult {
        // Parse route from path: /promo/offer -> "promo/offer"
        let path = url.path
        let route: String
        if path.isEmpty || path == "/" {
            route = ""
        } else {
            route = path.hasPrefix("/") ? String(path.dropFirst()) : path
        }
        
        // Parse query params
        var params: [String: String] = [:]
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                if let value = item.value {
                    params[item.name] = value
                }
            }
        }
        
        return DeepLinkResult(route: route, params: params, url: url)
    }
}
