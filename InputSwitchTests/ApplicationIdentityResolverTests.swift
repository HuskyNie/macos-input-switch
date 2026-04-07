import XCTest
@testable import InputSwitch

final class ApplicationIdentityResolverTests: XCTestCase {
    func test_prefers_bundle_id_when_available() {
        let identity = ApplicationIdentityResolver.resolve(
            bundleID: "com.googlecode.iterm2",
            bundleURL: URL(fileURLWithPath: "/Applications/iTerm.app"),
            executableName: "iTerm2",
            displayName: "iTerm2"
        )

        XCTAssertEqual(identity.matchKey, "bundle:com.googlecode.iterm2")
    }

    func test_falls_back_to_bundle_path_then_executable_name() {
        let pathIdentity = ApplicationIdentityResolver.resolve(
            bundleID: nil,
            bundleURL: URL(fileURLWithPath: "/Applications/Custom.app"),
            executableName: "Custom",
            displayName: "Custom"
        )
        let execIdentity = ApplicationIdentityResolver.resolve(
            bundleID: nil,
            bundleURL: nil,
            executableName: "HiddenAgent",
            displayName: "Hidden Agent"
        )

        XCTAssertEqual(pathIdentity.matchKey, "path:/Applications/Custom.app")
        XCTAssertEqual(execIdentity.matchKey, "exec:HiddenAgent")
    }
}
