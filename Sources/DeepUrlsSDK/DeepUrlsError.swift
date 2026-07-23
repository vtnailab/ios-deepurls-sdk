import Foundation

/// Errors that can be thrown by the DeepUrls SDK.
public enum DeepUrlsError: Error, LocalizedError {
    /// SDK was used before calling `DeepUrls.configure(appId:deepKey:)`.
    case notConfigured
    /// The network request failed.
    case networkError(Error)
    /// The server returned an error response.
    case serverError(Int, String?)
    /// Failed to serialize or deserialize data.
    case serializationError
    /// Unauthorized request (check your appId and deepKey).
    case unauthorized
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "DeepUrls SDK not initialized. Call DeepUrls.configure(appId:deepKey:) first."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let body):
            return "Server error (HTTP \(code)): \(body ?? "No body")"
        case .serializationError:
            return "Failed to process data."
        case .unauthorized:
            return "Unauthorized. Please verify your appId and deepKey."
        }
    }
}
