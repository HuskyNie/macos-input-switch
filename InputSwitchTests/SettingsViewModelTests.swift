import XCTest
@testable import InputSwitch

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func test_set_default_input_source_updates_name_and_invokes_callback() {
        let viewModel = SettingsViewModel()
        var receivedDefaultInputSourceID: String?

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
                .init(id: "im.wubi", displayName: "简体五笔")
            ],
            diagnostics: []
        )
        viewModel.onDefaultInputSourceChange = { receivedDefaultInputSourceID = $0 }

        viewModel.setDefaultInputSourceID("im.wubi")

        XCTAssertEqual(viewModel.defaultInputSourceName, "简体五笔")
        XCTAssertEqual(receivedDefaultInputSourceID, "im.wubi")
    }

    func test_save_rule_draft_invokes_locked_rule_callback() {
        let viewModel = SettingsViewModel()
        var receivedRule: (String, AppRule)?

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
            ],
            diagnostics: []
        )
        viewModel.onUpsertRule = { key, rule in
            receivedRule = (key, rule)
        }
        viewModel.ruleDraftKey = "bundle:com.googlecode.iterm2"
        viewModel.ruleDraftKind = .locked
        viewModel.ruleDraftInputSourceID = "com.apple.keylayout.ABC"

        viewModel.saveRuleDraft()

        XCTAssertEqual(receivedRule?.0, "bundle:com.googlecode.iterm2")
        XCTAssertEqual(receivedRule?.1, .locked(inputSourceID: "com.apple.keylayout.ABC"))
    }

    func test_delete_rule_invokes_callback_with_rule_key() {
        let viewModel = SettingsViewModel()
        var deletedRuleKey: String?

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: ["bundle:com.googlecode.iterm2": .ignored],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [],
            diagnostics: []
        )
        viewModel.onDeleteRule = { deletedRuleKey = $0 }

        viewModel.deleteRule(viewModel.rules[0])

        XCTAssertEqual(deletedRuleKey, "bundle:com.googlecode.iterm2")
    }

    func test_reload_maps_default_input_source_id_to_display_name() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
                .init(id: "im.wubi", displayName: "简体五笔")
            ],
            diagnostics: []
        )

        XCTAssertEqual(viewModel.defaultInputSourceName, "ABC")
    }

    func test_reload_falls_back_to_input_source_id_when_display_name_is_unavailable() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: "missing.input.source",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
            ],
            diagnostics: []
        )

        XCTAssertEqual(viewModel.defaultInputSourceName, "missing.input.source")
    }

    func test_reload_keeps_launch_at_login_enabled_when_status_requires_approval() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .requiresApproval,
            availableInputSources: [],
            diagnostics: []
        )

        XCTAssertTrue(viewModel.launchAtLoginEnabled)
        XCTAssertEqual(viewModel.launchAtLoginStatusMessage, "等待系统批准")
    }

    func test_reload_updates_debug_logging_enabled() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: [:],
                launchAtLoginEnabled: false,
                debugLoggingEnabled: true
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [],
            diagnostics: []
        )

        XCTAssertTrue(viewModel.debugLoggingEnabled)
    }

    func test_set_debug_logging_enabled_triggers_callback() {
        let viewModel = SettingsViewModel()
        var receivedValue: Bool?

        viewModel.onDebugLoggingToggle = { receivedValue = $0 }

        viewModel.setDebugLoggingEnabled(true)

        XCTAssertTrue(viewModel.debugLoggingEnabled)
        XCTAssertEqual(receivedValue, true)
    }
}
