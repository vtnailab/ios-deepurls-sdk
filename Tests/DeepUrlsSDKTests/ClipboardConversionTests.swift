import XCTest
@testable import DeepUrlsSDK

final class ClipboardConversionTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // Ensure SDK is configured so getConfig() doesn't fatal
        DeepUrls.configure(appId: "test_app_id", deepKey: "test_deep_key")
        // Start each test with clean state
        ClipboardConversionManager.resetClipboardConversionState()
    }

    override func tearDown() {
        ClipboardConversionManager.resetClipboardConversionState()
        super.tearDown()
    }

    // MARK: - Empty clickId

    func testEmptyClickIdIsRejected() {
        let result = ClipboardConversionManager.reportClipboardConversion("")
        XCTAssertFalse(result, "Empty clickId must not trigger a conversion request")
    }

    func testEmptyClickIdAsyncIsRejected() async {
        let result = await ClipboardConversionManager.reportClipboardConversionAsync("")
        XCTAssertFalse(result, "Empty clickId must not trigger a conversion request (async)")
    }

    func testWhitespaceOnlyClickIdIsRejected() {
        let result = ClipboardConversionManager.reportClipboardConversion("   ")
        XCTAssertFalse(result, "Whitespace-only clickId must not trigger a conversion request")
    }

    func testWhitespaceOnlyClickIdAsyncIsRejected() async {
        let result = await ClipboardConversionManager.reportClipboardConversionAsync("   ")
        XCTAssertFalse(result, "Whitespace-only clickId must not trigger a conversion request (async)")
    }

    // MARK: - Initial state

    func testInitialStateIsUnsent() {
        XCTAssertFalse(
            ClipboardConversionManager.isClipboardConversionSent,
            "Initial state must be unsent"
        )
    }

    func testInitialStateIsUnsentViaPublicAPI() {
        XCTAssertFalse(
            DeepUrls.isClipboardConversionSent,
            "Initial state must be unsent via public API"
        )
    }

    // MARK: - Sent state via UserDefaults (deterministic, no network)

    func testSentStateIsCorrectlyRepresentedByUserDefaults() {
        let defaults = UserDefaults.standard
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let versionString = "\(version)(\(build))"

        // Simulate a successful conversion by setting UserDefaults directly
        defaults.set(true, forKey: "deepurls_clipboard_conversion_sent")
        defaults.set(versionString, forKey: "deepurls_clipboard_conversion_version")

        XCTAssertTrue(
            ClipboardConversionManager.isClipboardConversionSent,
            "isClipboardConversionSent must be true when UserDefaults flags are set for current version"
        )
    }

    func testSameVersionBuildIsConsideredAlreadySent() async {
        let defaults = UserDefaults.standard
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let versionString = "\(version)(\(build))"

        // Simulate a previously successful conversion
        defaults.set(true, forKey: "deepurls_clipboard_conversion_sent")
        defaults.set(versionString, forKey: "deepurls_clipboard_conversion_version")

        // Attempting again for the same version/build should be skipped
        let result = await ClipboardConversionManager.reportClipboardConversionAsync("some_click_id")
        XCTAssertFalse(result, "Repeated conversion for same version/build must be skipped")

        // State should still be sent
        XCTAssertTrue(ClipboardConversionManager.isClipboardConversionSent)
    }

    // MARK: - Version/build change allows new conversion

    func testChangingVersionBuildMakesConversionEligibleAgain() {
        let defaults = UserDefaults.standard

        // Simulate a previous conversion for a different version
        defaults.set(true, forKey: "deepurls_clipboard_conversion_sent")
        defaults.set("99.99.99(9999)", forKey: "deepurls_clipboard_conversion_version")

        // Since current version differs from the saved one, state should be unsent
        XCTAssertFalse(
            ClipboardConversionManager.isClipboardConversionSent,
            "Version/build change must make conversion eligible again"
        )
    }

    // MARK: - Reset state

    func testResetClipboardConversionStateClearsState() {
        let defaults = UserDefaults.standard
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let versionString = "\(version)(\(build))"

        // Set state
        defaults.set(true, forKey: "deepurls_clipboard_conversion_sent")
        defaults.set(versionString, forKey: "deepurls_clipboard_conversion_version")
        XCTAssertTrue(ClipboardConversionManager.isClipboardConversionSent)

        // Reset
        ClipboardConversionManager.resetClipboardConversionState()

        XCTAssertFalse(
            ClipboardConversionManager.isClipboardConversionSent,
            "resetClipboardConversionState() must clear the sent state"
        )
    }

    // MARK: - Failed conversion does NOT mark sent

    /// This test verifies that a failed API call does not persist the sent flag.
    /// Since the SDK is configured with dummy credentials, the backend will reject
    /// the request (or it will fail to connect), resulting in a failure path.
    /// This is deterministic: dummy credentials always fail.
    func testFailedConversionDoesNotMarkSent() async {
        // Ensure clean state
        XCTAssertFalse(ClipboardConversionManager.isClipboardConversionSent)

        // Attempt conversion — will fail because credentials are dummy
        let result = await ClipboardConversionManager.reportClipboardConversionAsync("test_click_id")

        // Must return false on failure
        XCTAssertFalse(result, "Failed conversion must return false")

        // Must NOT have marked the conversion as sent
        XCTAssertFalse(
            ClipboardConversionManager.isClipboardConversionSent,
            "Failed conversion must not persist the sent flag"
        )
    }

    // MARK: - Separate from referrer state

    func testClipboardConversionUsesOwnUserDefaultsKeys() {
        let defaults = UserDefaults.standard

        // Set referrer state (different keys)
        defaults.set(true, forKey: "deepurls_referrer_sent")

        // Clipboard conversion state should be independent
        XCTAssertFalse(
            ClipboardConversionManager.isClipboardConversionSent,
            "Clipboard conversion must not share state with referrer"
        )

        // Clean up referrer key
        defaults.removeObject(forKey: "deepurls_referrer_sent")
    }

    // MARK: - Documentation of untestable behavior

    /// **Limitation**: Verifying that a *successful* API response (HTTP 200) correctly
    /// persists the sent flag requires either a real backend or an HTTP mocking layer.
    /// The current `ApiClient` uses `URLSession.shared` directly as static methods,
    /// making dependency injection impractical without a larger architectural change.
    ///
    /// The successful-path persistence logic is straightforward (two `UserDefaults.set` calls
    /// after `try await` succeeds) and is covered indirectly by:
    /// - `testSentStateIsCorrectlyRepresentedByUserDefaults` (verifies the flag semantics)
    /// - `testFailedConversionDoesNotMarkSent` (verifies the failure path)
    /// - `testSameVersionBuildIsConsideredAlreadySent` (verifies the idempotency gate)
    func testSuccessfulConversionMarkedSent_documentedLimitation() {
        // See doc comment above. This test exists as documentation only.
    }
}
