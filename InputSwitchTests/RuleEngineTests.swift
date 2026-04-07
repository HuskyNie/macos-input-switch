import XCTest
@testable import InputSwitch

final class RuleEngineTests: XCTestCase {
    private let abc = InputSourceDescriptor(id: "com.apple.keylayout.ABC", displayName: "ABC")
    private let pinyin = InputSourceDescriptor(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音")
    private let wubi = InputSourceDescriptor(id: "im.wubi", displayName: "简体五笔")

    func test_application_match_key_prefers_bundle_over_path_and_exec() {
        let app = ApplicationIdentity(
            bundleID: "com.apple.Safari",
            bundlePath: "/Applications/Safari.app",
            executableName: "Safari",
            displayName: "Safari"
        )

        XCTAssertEqual(app.matchKey, "bundle:com.apple.Safari")
    }

    func test_application_match_key_uses_path_when_bundle_id_missing() {
        let app = ApplicationIdentity(
            bundleID: nil,
            bundlePath: "/Applications/Utilities/Terminal.app",
            executableName: "Terminal",
            displayName: "Terminal"
        )

        XCTAssertEqual(app.matchKey, "path:/Applications/Utilities/Terminal.app")
    }

    func test_application_match_key_falls_back_to_executable_name() {
        let app = ApplicationIdentity(
            bundleID: nil,
            bundlePath: nil,
            executableName: "CustomTool",
            displayName: "Custom Tool"
        )

        XCTAssertEqual(app.matchKey, "exec:CustomTool")
    }

    func test_ignored_rule_wins_over_memory_and_default() {
        let app = ApplicationIdentity(bundleID: "com.googlecode.iterm2", bundlePath: nil, executableName: "iTerm2", displayName: "iTerm2")
        let engine = RuleEngine()

        let decision = engine.resolve(
            app: app,
            current: abc,
            rules: [app.matchKey: .ignored],
            memories: [app.matchKey: wubi.id],
            defaultInputSourceID: pinyin.id
        )

        XCTAssertEqual(decision, .keepCurrent(reason: .ignored))
    }

    func test_locked_rule_wins_over_memory() {
        let app = ApplicationIdentity(bundleID: "com.apple.dt.Xcode", bundlePath: nil, executableName: "Xcode", displayName: "Xcode")
        let engine = RuleEngine()

        let decision = engine.resolve(
            app: app,
            current: pinyin,
            rules: [app.matchKey: .locked(inputSourceID: abc.id)],
            memories: [app.matchKey: wubi.id],
            defaultInputSourceID: pinyin.id
        )

        XCTAssertEqual(decision, .switchTo(inputSourceID: abc.id, reason: .lockedRule))
    }

    func test_memory_is_used_when_no_explicit_rule_exists() {
        let app = ApplicationIdentity(bundleID: "com.tencent.xinWeChat", bundlePath: nil, executableName: "WeChat", displayName: "微信")
        let engine = RuleEngine()

        let decision = engine.resolve(
            app: app,
            current: abc,
            rules: [:],
            memories: [app.matchKey: pinyin.id],
            defaultInputSourceID: abc.id
        )

        XCTAssertEqual(decision, .switchTo(inputSourceID: pinyin.id, reason: .remembered))
    }

    func test_default_is_used_when_rule_and_memory_are_missing() {
        let app = ApplicationIdentity(bundleID: "com.apple.Safari", bundlePath: nil, executableName: "Safari", displayName: "Safari")
        let engine = RuleEngine()

        let decision = engine.resolve(
            app: app,
            current: abc,
            rules: [:],
            memories: [:],
            defaultInputSourceID: pinyin.id
        )

        XCTAssertEqual(decision, .switchTo(inputSourceID: pinyin.id, reason: .defaultInputSource))
    }
}
