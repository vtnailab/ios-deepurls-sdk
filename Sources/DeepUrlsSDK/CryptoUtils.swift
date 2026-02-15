import Foundation
import CryptoKit

enum CryptoUtils {
    /// Computes HMAC-SHA256 signature for the given data using the secret key.
    static func hmacSha256(data: String, secret: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(data.utf8),
            using: key
        )
        return signature.map { String(format: "%02x", $0) }.joined()
    }
}
