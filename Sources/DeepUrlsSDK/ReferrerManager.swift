import Foundation

/// Manages install referrer reporting. iOS does not have an equivalent to Android's Install Referrer API.
/// Call `reportReferrer` when you obtain referrer data (e.g. from a deep link containing clickId, or from an attribution provider).
enum ReferrerManager {
    private static let prefsKey = "deepurls_referrer_sent"
    private static let prefsVersionKey = "deepurls_last_version"
    
    private static var defaults: UserDefaults { UserDefaults.standard }
    
    /// Reports referrer to the backend if it contains "clickId". Skips if already sent for current app version.
    /// - Parameters:
    ///   - referrer: The referrer string (e.g. from a deep link URL or attribution provider)
    ///   - bundleId: Your app's bundle identifier
    static func reportReferrer(referrer: String, bundleId: String) {
        guard referrer.contains("clickId") else {
            return
        }
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let lastVersion = defaults.string(forKey: prefsVersionKey)
        let alreadySent = defaults.bool(forKey: prefsKey)
        
        if lastVersion != currentVersion || !alreadySent {
            ApiClient.sendReferrer(referrer: referrer, bundleId: bundleId)
            defaults.set(true, forKey: prefsKey)
            defaults.set(currentVersion, forKey: prefsVersionKey)
        }
    }
}
