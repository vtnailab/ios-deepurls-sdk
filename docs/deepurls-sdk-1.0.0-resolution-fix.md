# DeepUrlsSDK 1.0.0 — SwiftPM Dependency Resolution Fix

## Summary

Swift Package Manager consumers could not resolve `ios-deepurls-sdk` with the
version requirement `from: "1.0.0"` (`1.0.0..<2.0.0`). The issue has been
resolved by publishing release version `1.0.0` of the SDK as a Git tag.

## Root Cause

The repository had no remote Git version tags. SwiftPM selects package versions
exclusively from semantic-version tags, so with no tags available it could not
find any release compatible with `1.0.0..<2.0.0` and failed during version
selection:

```text
no versions of 'ios-deepurls-sdk' match the requirement 1.0.0..<2.0.0
```

The package manifest and sources were not at fault.

## Fix

- Published annotated Git tag `1.0.0`.
- Release commit: `2e9d2d6` (`Merge pull request #4 from vtnailab/feature/ios-clipboard-conversion`).
- No source-code or manifest (`Package.swift`) changes were necessary for this fix.

Remote tag state:

```text
refs/tags/1.0.0      -> annotated tag object a14918e
refs/tags/1.0.0^{}   -> 2e9d2d61f87ca25793f55a5268a9ee202eae1303
```

## Verification Results

| Check | Result |
|---|---|
| Manifest validation (`swift package dump-package`) | ✅ Passed |
| macOS build (`swift build`) | ✅ Passed |
| XCTest suite (`swift test`, macOS) | ✅ All 18 tests passed |
| Clean consumer dependency resolution (`from: "1.0.0"`) | ✅ Resolved `ios-deepurls-sdk` at `1.0.0` |
| Clean consumer build | ✅ Passed |
| Remote tag publication (`git ls-remote --tags`) | ✅ `1.0.0` present, dereferences to `2e9d2d6` |

## Known Follow-ups

- **iOS-target build not yet confirmed.** Verification so far was performed on a
  macOS host only. An iOS-destination build (for example
  `xcodebuild build -scheme DeepUrlsSDK -destination 'generic/platform=iOS'`)
  is still outstanding.
- **Network-dependent test.** The existing test `testRealWorldLinkCreation`
  received an HTTP 404 response from the server but still passed. This needs
  separate investigation, since the test does not currently fail on that
  response.

## Conclusion

The original SwiftPM version-resolution failure is resolved: version `1.0.0` is
published and resolves and builds in a clean external consumer. Verification of
the iOS-target build and of the consuming iOS app's integration remains as
follow-up checks. The consuming iOS app integration has **not** yet been
verified.
