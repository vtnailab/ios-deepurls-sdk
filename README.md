# 🚀 DeepUrls SDK for iOS & macOS

[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)

A lightweight, powerful Swift Package Manager (SPM) library for creating and managing deep links. Designed for performance and strict logic parity with the Android DeepUrls SDK.

---

## 📋 Requirements

- **iOS 13.0+** / **macOS 10.15+**
- **Swift 5.5+** (Supports `async/await`)
- **Xcode 13+**

---

## 📦 Installation

### Swift Package Manager

Add the following URL to your package dependencies in Xcode (**File → Add Packages...**):

```text
https://github.com/vtnailab/ios-deepurls-sdk
```

---

## 🚀 Quick Start

### 1. Initialize the SDK
Initialize the SDK once, typically in your `AppDelegate` or `@main` App struct.

```swift
import DeepUrlsSDK

// Basic Configuration
DeepUrls.configure(appId: "your-app-id", deepKey: "your-deep-key")
```

### 2. Create Deep Links
You can create short or long deep links either using modern `async/await` or traditional completion handlers.

#### Option A: Modern Swift (Async/Await)
```swift
do {
    let (shortUrl, longUrl) = try await DeepUrls.createLink(
        route: "promo/discount",
        params: ["code": "SAVE50"]
    )
    print("✨ Link created: \(shortUrl ?? "n/a")")
} catch {
    print("❌ Error: \(error.localizedDescription)")
}
```

#### Option B: Completion Handler
```swift
DeepUrls.createLink(route: "promo/discount", params: ["code": "SAVE50"]) { success, shortUrl, longUrl in
    if success, let link = shortUrl {
        print("✨ Short link: \(link)")
    }
}
```

#### Link Preview and Campaign Metadata
```swift
let (shortUrl, longUrl) = try await DeepUrls.createLink(
    route: "promo/discount",
    params: ["code": "SAVE50"],
    previewTitle: "Summer Sale",
    previewDescription: "Save 20% for a limited time",
    previewImage: "https://example.com/preview.png",
    campaignData: ["campaignId": "campaign_123", "source": "newsletter"]
)
```

---

## 📱 Handling Incoming Links

The SDK handles Universal Links and Custom URL Schemes seamlessly. It automatically reports referrers for attribution and parses parameters for you.

### SwiftUI
```swift
WindowGroup {
    ContentView()
        .onOpenURL { url in
            DeepUrls.handleOpenURL(url) { result in
                print("🎯 Navigate to \(result.route) with \(result.params)")
            }
        }
}
```

### UIKit (iOS)
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return DeepUrls.handleOpenURL(url) { result in
        // Your navigation logic
    }
}
```

### AppKit (macOS)
```swift
func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    DeepUrls.handleOpenURL(url) { result in
        // Your navigation logic
    }
}
```

---

## 🛠 Advanced Features

### Error Handling
The SDK provides detailed error types to help you debug integration issues.

```swift
do {
    try await DeepUrls.createLink(route: "test")
} catch let error as DeepUrlsError {
    switch error {
    case .notConfigured:    print("Please call configure() first")
    case .unauthorized:     print("Check your appId and deepKey")
    case .serverError(let code, let msg): print("Server Error \(code): \(msg ?? "")")
    default:                print("Something went wrong")
    }
}
```

### Result Structure
When a deep link is handled, you receive a `DeepLinkResult`:

| Property | Type | Description |
| :--- | :--- | :--- |
| `route` | `String` | The path components (e.g., `promo/offer`). |
| `params` | `[String: String]` | Key-value pairs from the URL query. |
| `url` | `URL` | The original deep link URL. |

---

## 🧪 Testing

The SDK includes a comprehensive test suite. To run the tests, execute the following in your terminal:

```bash
swift test
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
