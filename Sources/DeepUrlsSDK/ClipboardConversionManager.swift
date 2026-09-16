import Foundation

/// Manages iOS deferred deep-link clipboard conversion reporting.
///
/// This is separate from `ReferrerManager` because clipboard-based deferred attribution
/// is an iOS-specific flow with different idempotency requirements:
/// the sent flag is only persisted after a confirmed HTTP 200 response.
enum ClipboardConversionManager {
    private static let sentKey = "deepurls_clipboard_conversion_sent"
    private static let versionKey = "deepurls_clipboard_conversion_version"

    private static var defaults: UserDefaults { UserDefaults.standard }

    /// Whether a clipboard conversion has already been successfully sent for the current app version/build.
    static var isClipboardConversionSent: Bool {
        let currentVersion = currentVersionString
        let savedVersion = defaults.string(forKey: versionKey)
        let sent = defaults.bool(forKey: sentKey)
        return sent && savedVersion == currentVersion
    }

    /// Reports a clipboard conversion to the backend (fire-and-forget).
    /// - Parameter clickId: The click identifier from the clipboard.
    /// - Returns: `true` if the request was dispatched (not a duplicate and non-empty), `false` otherwise.
    @discardableResult
    static func reportClipboardConversion(_ clickId: String) -> Bool {
        guard !clickId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard !isClipboardConversionSent else {
            return false
        }
        Task {
            _ = await reportClipboardConversionAsync(clickId)
        }
        return true
    }

    /// Reports a clipboard conversion to the backend and returns whether it succeeded.
    ///
    /// - Parameter clickId: The click identifier from the clipboard.
    /// - Returns: `true` only if the backend returned HTTP 200 and the sent state was persisted.
    ///
    /// Behavior:
    /// - Empty `clickId` → returns `false`, no request sent.
    /// - Already sent for current version/build → returns `false`, no request sent.
    /// - On HTTP 200 → marks sent and saves version/build, returns `true`.
    /// - On any failure → does **not** mark sent, returns `false` (allows retry).
    static func reportClipboardConversionAsync(_ clickId: String) async -> Bool {
        guard !clickId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard !isClipboardConversionSent else {
            return false
        }

        do {
            try await ApiClient.sendClipboardConversionAsync(clickId: clickId)
            // Only persist on confirmed success
            defaults.set(true, forKey: sentKey)
            defaults.set(currentVersionString, forKey: versionKey)
            return true
        } catch {
            // Do not persist — allows retry on next launch
            return false
        }
    }

    /// Clears the clipboard conversion sent state. Intended for testing only.
    static func resetClipboardConversionState() {
        defaults.removeObject(forKey: sentKey)
        defaults.removeObject(forKey: versionKey)
    }

    // MARK: - Private

    private static var currentVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version)(\(build))"
    }
}
