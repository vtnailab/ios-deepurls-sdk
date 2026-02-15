# DeepUrls SDK for iOS

Swift Package Manager (SPM) library for creating and managing deep links. Mirrors the logic of the Android DeepUrls SDK.

## Requirements

- iOS 13+ / macOS 10.15+
- Swift 5.5+

## Installation

### Swift Package Manager

Add to your `Package.swift` or in Xcode: **File → Add Package Dependencies**

```
https://github.com/your-org/deepurl-SDK-iOS
```

Or add locally (e.g. if the package sits next to your project):

```swift
dependencies: [
    .package(path: "../deepurl-SDK-iOS")
]
```

## Usage

### 1. Configure

In `AppDelegate` or your app's entry point:

```swift
import DeepUrlsSDK

// In application(_:didFinishLaunchingWithOptions:)
DeepUrls.configure(appId: "your-app-id", deepKey: "your-deep-key")

// Optional: if you have referrer from a launch URL
DeepUrls.configure(appId: "your-app-id", deepKey: "your-deep-key", referrer: referrerString)
```

### 2. Create links

```swift
DeepUrls.createLink(route: "promo/offer", params: ["code": "SAVE20"], useShort: true) { success, url, longUrl in
    if success, let link = url {
        // Share or use the link
        print("Short link: \(link)")
    }
}
```

### 3. Handle incoming deeplinks

When a user clicks a deeplink and opens your app, call `handleOpenURL` from your app delegate or scene delegate:

**UIKit (AppDelegate):**
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return DeepUrls.handleOpenURL(url) { result in
        // Navigate to the appropriate screen
        // result.route = "promo/offer", result.params = ["code": "SAVE20"]
        navigateTo(route: result.route, params: result.params)
    }
}
```

**SwiftUI (onOpenURL):**
```swift
WindowGroup {
    ContentView()
        .onOpenURL { url in
            DeepUrls.handleOpenURL(url) { result in
                navigateTo(route: result.route, params: result.params)
            }
        }
}
```

The SDK will automatically report referrer (for attribution) if the URL contains `clickId`, and call your handler with the parsed route and params for in-app navigation.

### 4. Report referrer (optional)

If you obtain referrer data from a deep link or attribution provider (and don't use `handleOpenURL`):

```swift
DeepUrls.reportReferrer("utm_source=...&clickId=abc123")
```

## API

| Method | Description |
|--------|-------------|
| `configure(appId:deepKey:referrer:)` | Initialize the SDK with credentials |
| `createLink(route:params:useShort:callback:)` | Create a deep link (short or long) |
| `handleOpenURL(_:onHandled:)` | Handle incoming deeplink URLs; reports referrer and invokes handler for navigation |
| `reportReferrer(_:)` | Manually report referrer when available |

## Differences from Android SDK

- **Config**: iOS uses programmatic configuration instead of loading from `deepUrlsConfig.json`
- **Referrer**: iOS has no Install Referrer API. Use `reportReferrer` when you have referrer data from a deep link or attribution provider
