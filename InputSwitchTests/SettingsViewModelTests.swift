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
            diagnostics: [],
            currentActiveApp: nil
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
            diagnostics: [],
            currentActiveApp: nil
        )
        viewModel.onUpsertRule = { key, rule in
            receivedRule = (key, rule)
        }
        viewModel.beginEditing(
            .init(key: "bundle:com.googlecode.iterm2", rule: .locked(inputSourceID: "com.apple.keylayout.ABC"))
        )

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
            diagnostics: [],
            currentActiveApp: nil
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
            diagnostics: [],
            currentActiveApp: nil
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
            diagnostics: [],
            currentActiveApp: nil
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
            diagnostics: [],
            currentActiveApp: nil
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
            diagnostics: [],
            currentActiveApp: nil
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

    func test_begin_rule_draft_for_current_app_uses_current_active_app_identity() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [],
            diagnostics: [],
            currentActiveApp: .init(
                bundleID: "com.apple.dt.Xcode",
                bundlePath: nil,
                executableName: "Xcode",
                displayName: "Xcode"
            )
        )

        viewModel.beginRuleDraftForCurrentApp()

        XCTAssertEqual(viewModel.ruleDraftKey, "bundle:com.apple.dt.Xcode")
        XCTAssertEqual(viewModel.ruleDraftDisplayName, "Xcode")
        XCTAssertTrue(viewModel.canSaveRuleDraft)
    }

    func test_begin_rule_draft_for_current_app_does_nothing_when_no_current_active_app_exists() {
        let viewModel = SettingsViewModel()

        viewModel.reload(
            from: AppSettings(
                defaultInputSourceID: nil,
                rules: [:],
                launchAtLoginEnabled: false
            ),
            launchAtLoginState: .disabled,
            availableInputSources: [],
            diagnostics: [],
            currentActiveApp: nil
        )

        viewModel.beginRuleDraftForCurrentApp()

        XCTAssertEqual(viewModel.ruleDraftKey, "")
        XCTAssertEqual(viewModel.ruleDraftDisplayName, "未选择应用")
        XCTAssertFalse(viewModel.canSaveRuleDraft)
    }

    func test_reload_preserves_in_progress_rule_draft() {
        let viewModel = SettingsViewModel()

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
            diagnostics: [],
            currentActiveApp: .init(
                bundleID: "com.apple.dt.Xcode",
                bundlePath: nil,
                executableName: "Xcode",
                displayName: "Xcode"
            )
        )
        viewModel.beginRuleDraftForCurrentApp()
        viewModel.ruleDraftKind = .locked
        viewModel.ruleDraftInputSourceID = "com.apple.keylayout.ABC"

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
            diagnostics: ["输入法变化触发刷新"],
            currentActiveApp: .init(
                bundleID: "com.apple.finder",
                bundlePath: nil,
                executableName: "Finder",
                displayName: "访达"
            )
        )

        XCTAssertEqual(viewModel.ruleDraftKey, "bundle:com.apple.dt.Xcode")
        XCTAssertEqual(viewModel.ruleDraftDisplayName, "Xcode")
        XCTAssertEqual(viewModel.ruleDraftKind, .locked)
        XCTAssertEqual(viewModel.ruleDraftInputSourceID, "com.apple.keylayout.ABC")
        XCTAssertTrue(viewModel.canSaveRuleDraft)
        XCTAssertEqual(viewModel.currentActiveAppDisplayName, "访达")
    }

    func test_rule_row_display_name_uses_readable_bundle_tail() {
        let row = SettingsRuleRow(key: "bundle:com.googlecode.iterm2", rule: .ignored)

        XCTAssertEqual(row.displayName, "iTerm2")
        XCTAssertEqual(row.detailText, "bundle:com.googlecode.iterm2")
    }

    func test_rule_row_display_name_falls_back_to_key_when_not_bundle() {
        let row = SettingsRuleRow(key: "executable:Code Helper", rule: .ignored)

        XCTAssertEqual(row.displayName, "Code Helper")
        XCTAssertEqual(row.detailText, "executable:Code Helper")
    }
}
