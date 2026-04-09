# InputSwitch Debug Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent debug toggle in settings and emit switch-path debug logs to both the in-app diagnostics list and stdout when the toggle is enabled.

**Architecture:** Extend `AppSettings` and `SettingsViewModel` so debug logging is a first-class persisted preference surfaced in the existing “通用设置” pane. Keep log storage simple by routing both normal logs and conditional debug logs through `AppContainer`, and teach `SwitchCoordinator` to emit debug events for the main decision and memory-update paths without changing rule behavior.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest, XcodeGen, xcodebuild

---

### Task 1: Add the persisted debug setting and settings UI wiring

**Files:**
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SettingsStore.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SettingsViewModelTests.swift`

- [ ] **Step 1: Write the failing view-model tests for debug toggle state and callback**

```swift
func test_reload_maps_debug_logging_enabled_state() {
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

func test_set_debug_logging_invokes_callback() {
    let viewModel = SettingsViewModel()
    var receivedEnabled: Bool?

    viewModel.onDebugLoggingToggle = { receivedEnabled = $0 }

    viewModel.setDebugLoggingEnabled(true)

    XCTAssertTrue(viewModel.debugLoggingEnabled)
    XCTAssertEqual(receivedEnabled, true)
}
```

- [ ] **Step 2: Run the targeted tests to verify they fail for the expected reason**

Run:

```bash
xcodegen generate
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SettingsViewModelTests test
```

Expected:

- `SettingsViewModelTests` fails because `AppSettings` does not accept `debugLoggingEnabled`
- `SettingsViewModel` has no `debugLoggingEnabled`, `onDebugLoggingToggle`, or `setDebugLoggingEnabled(_:)`

- [ ] **Step 3: Add the persisted field and view-model state with backward-compatible decoding**

```swift
struct AppSettings: Codable, Equatable {
    var defaultInputSourceID: String?
    var rules: [String: AppRule]
    var launchAtLoginEnabled: Bool
    var debugLoggingEnabled: Bool

    static let `default` = AppSettings(
        defaultInputSourceID: nil,
        rules: [:],
        launchAtLoginEnabled: false,
        debugLoggingEnabled: false
    )

    private enum CodingKeys: String, CodingKey {
        case defaultInputSourceID
        case rules
        case launchAtLoginEnabled
        case debugLoggingEnabled
    }

    init(
        defaultInputSourceID: String?,
        rules: [String: AppRule],
        launchAtLoginEnabled: Bool,
        debugLoggingEnabled: Bool
    ) {
        self.defaultInputSourceID = defaultInputSourceID
        self.rules = rules
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.debugLoggingEnabled = debugLoggingEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultInputSourceID = try container.decodeIfPresent(String.self, forKey: .defaultInputSourceID)
        rules = try container.decodeIfPresent([String: AppRule].self, forKey: .rules) ?? [:]
        launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled) ?? false
        debugLoggingEnabled = try container.decodeIfPresent(Bool.self, forKey: .debugLoggingEnabled) ?? false
    }
}
```

```swift
@Published var debugLoggingEnabled = false

var onDebugLoggingToggle: ((Bool) -> Void)?

func reload(
    from settings: AppSettings,
    launchAtLoginState: LaunchAtLoginState,
    availableInputSources: [InputSourceDescriptor],
    diagnostics: [String]
) {
    self.availableInputSources = availableInputSources
    defaultInputSourceID = settings.defaultInputSourceID
    defaultInputSourceName = displayName(for: settings.defaultInputSourceID)
    self.launchAtLoginState = launchAtLoginState
    launchAtLoginEnabled = launchAtLoginState.isActive
    debugLoggingEnabled = settings.debugLoggingEnabled
    rules = settings.rules
        .sorted { $0.key < $1.key }
        .map { SettingsRuleRow(key: $0.key, rule: $0.value) }
    self.diagnostics = diagnostics
}

func setDebugLoggingEnabled(_ enabled: Bool) {
    debugLoggingEnabled = enabled
    onDebugLoggingToggle?(enabled)
}
```

```swift
Toggle(
    "Debug 日志",
    isOn: Binding(
        get: { viewModel.debugLoggingEnabled },
        set: { viewModel.setDebugLoggingEnabled($0) }
    )
)
```

- [ ] **Step 4: Run the targeted tests again to verify they pass**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SettingsViewModelTests test
```

Expected:

- `SettingsViewModelTests` passes

- [ ] **Step 5: Commit the settings-model and UI wiring**

```bash
git add /Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SettingsStore.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SettingsViewModelTests.swift
git commit -m "feat: add debug logging setting"
```

### Task 2: Add switch-path debug diagnostics and route them through AppContainer

**Files:**
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SwitchCoordinator.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SwitchCoordinatorTests.swift`

- [ ] **Step 1: Write the failing coordinator tests for debug logging on decision and memory paths**

```swift
func test_app_activation_logs_debug_for_locked_rule_switch() {
    let harness = CoordinatorHarness(
        currentInputSource: .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
        availableInputSources: [
            .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
            .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
        ],
        settings: AppSettings(
            defaultInputSourceID: "com.apple.inputmethod.SCIM.ITABC",
            rules: ["bundle:com.googlecode.iterm2": .locked(inputSourceID: "com.apple.keylayout.ABC")],
            launchAtLoginEnabled: false,
            debugLoggingEnabled: true
        ),
        memories: [:]
    )

    harness.coordinator.handleAppDidActivate(
        .init(bundleID: "com.googlecode.iterm2", bundlePath: nil, executableName: "iTerm2", displayName: "iTerm2")
    )

    XCTAssertEqual(harness.inputSourceManager.switchCalls, ["com.apple.keylayout.ABC"])
    XCTAssertTrue(harness.debugDiagnostics.contains { $0.contains("命中规则") })
    XCTAssertTrue(harness.debugDiagnostics.contains { $0.contains("执行切换") })
}

func test_app_activation_logs_debug_for_ignored_rule_without_switching() {
    let harness = CoordinatorHarness(
        currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
        settings: AppSettings(
            defaultInputSourceID: "com.apple.keylayout.ABC",
            rules: ["bundle:com.tencent.xinWeChat": .ignored],
            launchAtLoginEnabled: false,
            debugLoggingEnabled: true
        ),
        memories: [:]
    )

    harness.coordinator.handleAppDidActivate(
        .init(bundleID: "com.tencent.xinWeChat", bundlePath: nil, executableName: "WeChat", displayName: "微信")
    )

    XCTAssertTrue(harness.inputSourceManager.switchCalls.isEmpty)
    XCTAssertTrue(harness.debugDiagnostics.contains { $0.contains("命中不管理") })
}

func test_input_source_change_logs_debug_when_memory_is_saved() throws {
    let harness = CoordinatorHarness(
        currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
        availableInputSources: [
            .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
            .init(id: "im.wubi", displayName: "简体五笔")
        ],
        settings: AppSettings(
            defaultInputSourceID: "com.apple.keylayout.ABC",
            rules: [:],
            launchAtLoginEnabled: false,
            debugLoggingEnabled: true
        ),
        memories: [:]
    )

    let app = ApplicationIdentity(
        bundleID: "com.apple.dt.Xcode",
        bundlePath: nil,
        executableName: "Xcode",
        displayName: "Xcode"
    )

    harness.coordinator.handleAppDidActivate(app)
    try harness.coordinator.handleInputSourceDidChange(to: .init(id: "im.wubi", displayName: "简体五笔"))

    XCTAssertTrue(harness.debugDiagnostics.contains { $0.contains("已写入记忆") })
}
```

- [ ] **Step 2: Run the targeted coordinator tests to verify they fail**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SwitchCoordinatorTests test
```

Expected:

- `SwitchCoordinatorTests` fails because the harness and coordinator do not yet expose `debugDiagnostics`
- Existing coordinator methods do not emit debug messages for normal decision paths

- [ ] **Step 3: Implement debug logging in the coordinator and route it through AppContainer**

```swift
final class SwitchCoordinator {
    private let ruleEngine: RuleEngine
    private let inputSourceManager: InputSourceManaging
    private let memoryStore: MemoryStoring
    private let loopGuard: LoopGuard
    private let diagnostics: (String) -> Void
    private let debugDiagnostics: (String) -> Void

    init(
        ruleEngine: RuleEngine,
        inputSourceManager: InputSourceManaging,
        settingsStore: SettingsProviding,
        memoryStore: MemoryStoring,
        diagnostics: @escaping (String) -> Void = { _ in },
        debugDiagnostics: @escaping (String) -> Void = { _ in },
        loopGuard: LoopGuard = LoopGuard()
    ) {
        self.ruleEngine = ruleEngine
        self.inputSourceManager = inputSourceManager
        self.memoryStore = memoryStore
        self.diagnostics = diagnostics
        self.debugDiagnostics = debugDiagnostics
        self.loopGuard = loopGuard
        self.settings = settingsStore.load()
        self.memories = memoryStore.load()
    }

    func handleAppDidActivate(_ app: ApplicationIdentity) {
        activeApp = app

        let currentInputSource = inputSourceManager.currentInputSource()
        debugDiagnostics("[DEBUG] 应用切换：\(app.displayName)，matchKey=\(app.matchKey)，当前输入法=\(currentInputSource?.id ?? "nil")")

        guard let fallbackDefaultID = settings.defaultInputSourceID ?? currentInputSource?.id else {
            debugDiagnostics("[DEBUG] 未找到默认或当前输入法，跳过自动切换")
            return
        }

        let decision = ruleEngine.resolve(
            app: app,
            current: currentInputSource,
            rules: settings.rules,
            memories: memories,
            defaultInputSourceID: fallbackDefaultID
        )

        switch decision {
        case .keepCurrent(let reason):
            debugDiagnostics(debugMessage(for: reason, app: app, inputSourceID: currentInputSource?.id))
            return
        case .switchTo(let inputSourceID, let reason):
            debugDiagnostics(debugMessage(for: reason, app: app, inputSourceID: inputSourceID))
            let availableInputSourceIDs = Set(inputSourceManager.availableInputSources().map(\\.id))
            if availableInputSourceIDs.contains(inputSourceID) {
                debugDiagnostics("[DEBUG] 执行切换：原因=\(reason.diagnosticsLabel)，目标输入法=\(inputSourceID)")
                switchInputSource(to: inputSourceID)
                return
            }
            diagnostics("目标输入法已不可用，应用：\(app.displayName)，原因：\(reason.diagnosticsLabel)，输入法 ID：\(inputSourceID)")
            debugDiagnostics("[DEBUG] 目标输入法不可用，准备尝试默认输入法：\(inputSourceID)")
            guard let defaultInputSourceID = settings.defaultInputSourceID else {
                diagnostics("未配置默认输入法，保持当前输入法不变，应用：\(app.displayName)")
                return
            }
            guard availableInputSourceIDs.contains(defaultInputSourceID) else {
                diagnostics("默认输入法也不可用，保持当前输入法不变，应用：\(app.displayName)，默认输入法 ID：\(defaultInputSourceID)")
                return
            }
            diagnostics("已回退到默认输入法，应用：\(app.displayName)，输入法 ID：\(defaultInputSourceID)")
            debugDiagnostics("[DEBUG] 执行切换：原因=defaultInputSource，目标输入法=\(defaultInputSourceID)")
            guard currentInputSource?.id != defaultInputSourceID else {
                return
            }
            switchInputSource(to: defaultInputSourceID)
        }
    }

    func handleInputSourceDidChange(to inputSource: InputSourceDescriptor) throws {
        guard !loopGuard.shouldIgnoreInputChange(to: inputSource.id) else {
            debugDiagnostics("[DEBUG] 忽略程序回流输入法事件：\(inputSource.id)")
            return
        }

        guard let activeApp else {
            debugDiagnostics("[DEBUG] 当前没有活动应用，忽略记忆更新：\(inputSource.id)")
            return
        }

        let rule = settings.rules[activeApp.matchKey]
        guard rule != .ignored else {
            debugDiagnostics("[DEBUG] 当前应用命中不管理，跳过记忆更新")
            return
        }

        if case .locked? = rule {
            debugDiagnostics("[DEBUG] 当前应用命中规则：锁定输入法，跳过记忆更新")
            return
        }

        var updatedMemories = memories
        updatedMemories[activeApp.matchKey] = inputSource.id
        try memoryStore.save(updatedMemories)
        memories = updatedMemories
        debugDiagnostics("[DEBUG] 已写入记忆：\(activeApp.matchKey) -> \(inputSource.id)")
    }
}
```

```swift
settingsViewModel.onDebugLoggingToggle = { [weak self] enabled in
    Task { @MainActor in
        self?.setDebugLoggingEnabled(enabled)
    }
}

switchCoordinator = SwitchCoordinator(
    ruleEngine: RuleEngine(),
    inputSourceManager: inputSourceManager,
    settingsStore: settingsStore,
    memoryStore: memoryStore,
    diagnostics: { [weak self] message in
        self?.log(message)
    },
    debugDiagnostics: { [weak self] message in
        self?.debugLog(message)
    }
)

private func setDebugLoggingEnabled(_ enabled: Bool) {
    var updatedSettings = currentSettings
    updatedSettings.debugLoggingEnabled = enabled

    do {
        try persistSettings(updatedSettings)
        rebuildCoordinator()
        log(enabled ? "已启用 Debug 日志" : "已关闭 Debug 日志")
    } catch {
        log("保存 Debug 日志设置失败：\(error.localizedDescription)")
        refreshUI()
    }
}

private func log(_ message: String) {
    diagnosticsLogger.log(message)
    print(message)
    refreshUI()
}

private func debugLog(_ message: String) {
    guard currentSettings.debugLoggingEnabled else {
        return
    }
    diagnosticsLogger.log(message)
    print(message)
    refreshUI()
}
```

- [ ] **Step 4: Run the targeted coordinator tests again to verify they pass**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SwitchCoordinatorTests test
```

Expected:

- `SwitchCoordinatorTests` passes
- Debug assertions cover locked rule, ignored rule, remembered/default paths, and memory write behavior

- [ ] **Step 5: Commit the coordinator debug logging**

```bash
git add /Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SwitchCoordinator.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SwitchCoordinatorTests.swift
git commit -m "feat: add switch debug diagnostics"
```

### Task 3: Verify the integrated behavior and regenerate the project if needed

**Files:**
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SettingsViewModelTests.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SwitchCoordinatorTests.swift`
- Generate: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch.xcodeproj`

- [ ] **Step 1: Regenerate the Xcode project so the current source of truth matches the test commands**

Run:

```bash
xcodegen generate
```

Expected:

- `InputSwitch.xcodeproj` is created or updated without errors

- [ ] **Step 2: Run the focused tests that cover the new setting and switch diagnostics behavior**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SettingsViewModelTests -only-testing:InputSwitchTests/SwitchCoordinatorTests test
```

Expected:

- Both targeted test classes pass

- [ ] **Step 3: Run the full test suite to check for regressions**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
```

Expected:

- Full `InputSwitchTests` suite passes

- [ ] **Step 4: Perform a manual smoke check of the debug toggle**

Run:

```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -path '*Build/Products/Debug/InputSwitch.app' -print -quit)"
```

Verify:

- “通用设置”里出现 `Debug 日志` 开关
- 打开后切换应用，`日志与诊断` 页出现 `[DEBUG]` 日志
- 打开后切换应用，可在 Console 或启动进程的输出中看到同样的 `[DEBUG]` 日志
- 关闭后新的 `[DEBUG]` 日志不再追加，普通日志仍继续记录

- [ ] **Step 5: Commit the verified end-to-end behavior**

```bash
git add /Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SettingsStore.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SwitchCoordinator.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SettingsViewModelTests.swift /Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SwitchCoordinatorTests.swift /Users/husky/workSpace/21-husky/input-switch/project.yml /Users/husky/workSpace/21-husky/input-switch/README.md
git commit -m "feat: add debug logging toggle"
```

## Self-Review

- Spec coverage: covered persisted setting, UI entry, conditional in-app/stdout output, switch-path debug logs, memory-path debug logs, compatibility for old settings, and verification.
- Placeholder scan: no `TODO`/`TBD` markers or undefined “later” steps remain.
- Type consistency: plan uses one field name (`debugLoggingEnabled`), one callback (`onDebugLoggingToggle`), and one view-model mutator (`setDebugLoggingEnabled(_:)`) throughout.
