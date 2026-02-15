import Foundation

/// Configuration for the DeepUrls SDK.
public struct DeepUrlsConfig {
    public let appId: String
    public let deepKey: String
    
    public init(appId: String, deepKey: String) {
        self.appId = appId
        self.deepKey = deepKey
    }
}
