# InputSwitch Settings And Icon Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make default input source setting, rule CRUD, unmanaged rule visibility, and input-source management actually usable in the settings window, and update the menu bar icon to reflect the current input source with a fallback strategy.

**Architecture:** Keep the existing layering intact. Extend `SettingsViewModel` with explicit callbacks and draft state for setting/default/rule editing, wire those callbacks in `AppContainer`, and keep system-specific icon sourcing inside `TISInputSourceService`. Use the existing menu/status model boundary to switch from a fixed text icon to either a system icon URL or a text fallback.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest, XcodeGen, Carbon Text Input Source APIs

---

## Planned File Structure

### Domain / System

- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/InputSourceDescriptor.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/TISInputSourceService.swift`

### UI Models

- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusMenuModel.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusBarController.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift`

### UI Screens

- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/InputSourcesPane.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/RulesPane.swift`

### Wiring

- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift`

### Tests

- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SettingsViewModelTests.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/StatusMenuModelTests.swift`

## Task 1: Add Settings ViewModel Behavior For Default Input Source And Rule Editing

**Files:**
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SettingsViewModelTests.swift`

- [ ] **Step 1: Write the failing tests for default-input-source updates and rule callbacks**

```swift
@MainActor
final class SettingsViewModelTests: XCTestCase {
    func test_set_default_input_source_updates_name_and_invokes_callback() {
        let viewModel = SettingsViewModel()
        var receivedDefaultInputSourceID: String?

        viewModel.reload(
            from: AppSettings(defaultInputSourceID: nil, rules: [:], launchAtLoginEnabled: false),
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
            from: AppSettings(defaultInputSourceID: nil, rules: [:], launchAtLoginEnabled: false),
            launchAtLoginState: .disabled,
            availableInputSources: [.init(id: "com.apple.keylayout.ABC", displayName: "ABC")],
            diagnostics: []
        )
        viewModel.onUpsertRule = { key, rule in receivedRule = (key, rule) }
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
}
```

- [ ] **Step 2: Run the tests to verify the red state**

Run:

```bash
xcodegen generate
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SettingsViewModelTests test
```

Expected: `** TEST FAILED **` with missing `onDefaultInputSourceChange`, `setDefaultInputSourceID`, `onUpsertRule`, `saveRuleDraft`, or `deleteRule`.

- [ ] **Step 3: Implement the minimal draft/callback behavior in `SettingsViewModel`**

```swift
struct SettingsRuleRow: Identifiable, Equatable {
    let key: String
    let rule: AppRule
    var id: String { key }
}

enum SettingsRuleDraftKind: String, CaseIterable, Identifiable {
    case ignored = "不管理"
    case locked = "锁定输入法"
    var id: String { rawValue }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultInputSourceName = "未设置"
    @Published var defaultInputSourceID: String?
    @Published var launchAtLoginEnabled = false
    @Published var launchAtLoginState: LaunchAtLoginState = .disabled
    @Published var rules: [SettingsRuleRow] = []
    @Published var availableInputSources: [InputSourceDescriptor] = []
    @Published var diagnostics: [String] = []
    @Published var ruleDraftKey = ""
    @Published var ruleDraftKind: SettingsRuleDraftKind = .ignored
    @Published var ruleDraftInputSourceID: String?

    var onLaunchAtLoginToggle: ((Bool) -> Void)?
    var onDefaultInputSourceChange: ((String?) -> Void)?
    var onUpsertRule: ((String, AppRule) -> Void)?
    var onDeleteRule: ((String) -> Void)?

    var launchAtLoginStatusMessage: String { launchAtLoginState.statusMessage }
    var canSaveRuleDraft: Bool {
        !ruleDraftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (ruleDraftKind == .ignored || ruleDraftInputSourceID != nil)
    }

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
        rules = settings.rules.sorted { $0.key < $1.key }.map { .init(key: $0.key, rule: $0.value) }
        self.diagnostics = diagnostics
    }

    func setDefaultInputSourceID(_ inputSourceID: String?) {
        defaultInputSourceID = inputSourceID
        defaultInputSourceName = displayName(for: inputSourceID)
        onDefaultInputSourceChange?(inputSourceID)
    }

    func beginEditing(_ row: SettingsRuleRow) {
        ruleDraftKey = row.key
        switch row.rule {
        case .ignored, .remembered:
            ruleDraftKind = .ignored
            ruleDraftInputSourceID = nil
        case .locked(let inputSourceID):
            ruleDraftKind = .locked
            ruleDraftInputSourceID = inputSourceID
        }
    }

    func clearRuleDraft() {
        ruleDraftKey = ""
        ruleDraftKind = .ignored
        ruleDraftInputSourceID = nil
    }

    func saveRuleDraft() {
        let trimmedKey = ruleDraftKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }

        let rule: AppRule
        switch ruleDraftKind {
        case .ignored:
            rule = .ignored
        case .locked:
            guard let inputSourceID = ruleDraftInputSourceID else { return }
            rule = .locked(inputSourceID: inputSourceID)
        }

        onUpsertRule?(trimmedKey, rule)
        clearRuleDraft()
    }

    func deleteRule(_ row: SettingsRuleRow) {
        onDeleteRule?(row.key)
        if ruleDraftKey == row.key { clearRuleDraft() }
    }

    func displayName(for inputSourceID: String?) -> String {
        guard let inputSourceID else { return "未设置" }
        return availableInputSources.first(where: { $0.id == inputSourceID })?.displayName ?? inputSourceID
    }
}
```

- [ ] **Step 4: Run the tests to verify the green state**

Run:

```bash
xcodegen generate
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SettingsViewModelTests test
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit the ViewModel behavior**

Run:

```bash
git add InputSwitch/UI/Settings/SettingsViewModel.swift InputSwitchTests/SettingsViewModelTests.swift
git commit -m "feat: add settings rule editing view model behavior"
```

## Task 2: Wire Default Input Source Selection And Rule CRUD Into Settings Screens

**Files:**
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/InputSourcesPane.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/RulesPane.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift`

- [ ] **Step 1: Verify no existing screen offers default-input-source or rule CRUD actions**

Read:

```bash
sed -n '1,220p' InputSwitch/UI/Settings/GeneralPane.swift
sed -n '1,220p' InputSwitch/UI/Settings/InputSourcesPane.swift
sed -n '1,220p' InputSwitch/UI/Settings/RulesPane.swift
sed -n '1,260p' InputSwitch/App/AppContainer.swift
```

Expected: panes are display-only aside from launch-at-login, and `AppContainer` has no callbacks for default-input-source updates or rules CRUD.

- [ ] **Step 2: Add default-input-source selectors to the settings screens**

```swift
struct GeneralPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(
                "默认输入法",
                selection: Binding(
                    get: { viewModel.defaultInputSourceID ?? "" },
                    set: { viewModel.setDefaultInputSourceID($0.isEmpty ? nil : $0) }
                )
            ) {
                Text("未设置").tag("")
                ForEach(viewModel.availableInputSources, id: \.id) { source in
                    Text(source.displayName).tag(source.id)
                }
            }
            .pickerStyle(.menu)

            Toggle(
                "开机启动",
                isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLogin($0) }
                )
            )

            Text(viewModel.launchAtLoginStatusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

```swift
struct InputSourcesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.availableInputSources, id: \.id) { source in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.displayName)
                    Text(source.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.defaultInputSourceID == source.id {
                    Text("默认")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button("设为默认") {
                        viewModel.setDefaultInputSourceID(source.id)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Replace the rules page with summary rows plus an editor section**

```swift
struct RulesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            List(viewModel.rules) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.key)
                        Text(ruleDescription(for: entry))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("编辑") { viewModel.beginEditing(entry) }
                    Button("删除", role: .destructive) { viewModel.deleteRule(entry) }
                }
            }

            Form {
                TextField("应用键，例如 bundle:com.googlecode.iterm2", text: $viewModel.ruleDraftKey)
                Picker("规则类型", selection: $viewModel.ruleDraftKind) {
                    ForEach(SettingsRuleDraftKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }

                if viewModel.ruleDraftKind == .locked {
                    Picker(
                        "锁定输入法",
                        selection: Binding(
                            get: { viewModel.ruleDraftInputSourceID ?? "" },
                            set: { viewModel.ruleDraftInputSourceID = $0.isEmpty ? nil : $0 }
                        )
                    ) {
                        Text("请选择").tag("")
                        ForEach(viewModel.availableInputSources, id: \.id) { source in
                            Text(source.displayName).tag(source.id)
                        }
                    }
                }

                HStack {
                    Button("保存规则") { viewModel.saveRuleDraft() }
                        .disabled(!viewModel.canSaveRuleDraft)
                    Button("清空") { viewModel.clearRuleDraft() }
                }
            }
        }
    }

    private func ruleDescription(for row: SettingsRuleRow) -> String {
        switch row.rule {
        case .ignored:
            return "不管理"
        case .locked(let inputSourceID):
            return "锁定到 \(viewModel.displayName(for: inputSourceID))"
        case .remembered:
            return "自动记忆"
        }
    }
}
```

- [ ] **Step 4: Wire the new callbacks into `AppContainer`**

```swift
settingsViewModel.onDefaultInputSourceChange = { [weak self] inputSourceID in
    Task { @MainActor in
        self?.setDefaultInputSource(inputSourceID)
    }
}
settingsViewModel.onUpsertRule = { [weak self] key, rule in
    Task { @MainActor in
        self?.upsertRule(key: key, rule: rule)
    }
}
settingsViewModel.onDeleteRule = { [weak self] key in
    Task { @MainActor in
        self?.deleteRule(key: key)
    }
}
```

```swift
private func setDefaultInputSource(_ inputSourceID: String?) {
    var updatedSettings = currentSettings
    updatedSettings.defaultInputSourceID = inputSourceID

    do {
        try persistSettings(updatedSettings)
        rebuildCoordinator()
        if let inputSourceID {
            let displayName = inputSourceManager?.availableInputSources().first(where: { $0.id == inputSourceID })?.displayName ?? inputSourceID
            log("默认输入法已设置为：\(displayName)")
        } else {
            log("已清除默认输入法")
        }
    } catch {
        log("保存默认输入法失败：\(error.localizedDescription)")
        refreshUI()
    }
}

private func upsertRule(key: String, rule: AppRule) {
    var updatedSettings = currentSettings
    updatedSettings.rules[key] = rule

    do {
        try persistSettings(updatedSettings)
        rebuildCoordinator()
        log("已保存规则：\(key)")
    } catch {
        log("保存规则失败：\(error.localizedDescription)")
        refreshUI()
    }
}

private func deleteRule(key: String) {
    guard currentSettings.rules[key] != nil else {
        log("规则不存在：\(key)")
        return
    }

    var updatedSettings = currentSettings
    updatedSettings.rules.removeValue(forKey: key)

    do {
        try persistSettings(updatedSettings)
        rebuildCoordinator()
        log("已删除规则：\(key)")
    } catch {
        log("删除规则失败：\(error.localizedDescription)")
        refreshUI()
    }
}
```

- [ ] **Step 5: Commit the settings-management UI wiring**

Run:

```bash
git add InputSwitch/UI/Settings/GeneralPane.swift InputSwitch/UI/Settings/InputSourcesPane.swift InputSwitch/UI/Settings/RulesPane.swift InputSwitch/App/AppContainer.swift
git commit -m "feat: wire default input source and rule editing"
```

## Task 3: Add Dynamic Input-Source Menu Bar Icons

**Files:**
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/InputSourceDescriptor.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/TISInputSourceService.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusMenuModel.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusBarController.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/StatusMenuModelTests.swift`

- [ ] **Step 1: Write the failing menu-icon tests**

```swift
final class StatusMenuModelTests: XCTestCase {
    func test_menu_prefers_current_input_source_icon_when_available() {
        let iconURL = URL(fileURLWithPath: "/tmp/abc-icon.png")

        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            currentInputSourceIconURL: iconURL,
            isPaused: false
        )

        XCTAssertEqual(model.icon, .image(iconURL))
    }

    func test_menu_contains_only_the_confirmed_minimal_actions() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            currentInputSourceIconURL: nil,
            isPaused: false
        )

        XCTAssertEqual(model.items.map(\.title), [
            "当前应用：iTerm2",
            "当前输入法：ABC",
            "将当前应用标记为不管理",
            "清除此应用记忆",
            "暂停自动切换（30 分钟）",
            "打开设置…",
            "退出"
        ])
        XCTAssertEqual(model.icon, .text("⌨︎"))
    }
}
```

- [ ] **Step 2: Run the tests to verify the red state**

Run:

```bash
xcodegen generate
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/StatusMenuModelTests test
```

Expected: `** TEST FAILED **` with missing `currentInputSourceIconURL`, `icon`, or `StatusMenuIcon`.

- [ ] **Step 3: Extend the input-source and menu models**

```swift
struct InputSourceDescriptor: Equatable, Codable {
    let id: String
    let displayName: String
    let iconURL: URL?

    init(id: String, displayName: String, iconURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.iconURL = iconURL
    }
}
```

```swift
enum StatusMenuIcon: Equatable {
    case image(URL)
    case text(String)
}

struct StatusMenuModel: Equatable {
    let icon: StatusMenuIcon
    let items: [StatusMenuItem]

    static func make(
        activeAppName: String,
        currentInputSourceName: String,
        currentInputSourceIconURL: URL? = nil,
        isPaused: Bool
    ) -> StatusMenuModel {
        let pauseTitle = isPaused ? "恢复自动切换" : "暂停自动切换（30 分钟）"
        return StatusMenuModel(
            icon: currentInputSourceIconURL.map(StatusMenuIcon.image) ?? .text("⌨︎"),
            items: [
                .init(title: "当前应用：\(activeAppName)", action: .none),
                .init(title: "当前输入法：\(currentInputSourceName)", action: .none),
                .init(title: "将当前应用标记为不管理", action: .ignoreCurrentApp),
                .init(title: "清除此应用记忆", action: .clearCurrentMemory),
                .init(title: pauseTitle, action: .pauseTemporarily),
                .init(title: "打开设置…", action: .openSettings),
                .init(title: "退出", action: .quit)
            ]
        )
    }
}
```

- [ ] **Step 4: Source and render system icon URLs**

```swift
private func descriptor(from source: TISInputSource) -> InputSourceDescriptor? {
    guard
        let sourceIDPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
        let sourceID = Unmanaged<CFString>.fromOpaque(sourceIDPointer).takeUnretainedValue() as String?
    else {
        return nil
    }

    let localizedName = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
        .map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String }
        ?? sourceID

    return InputSourceDescriptor(
        id: sourceID,
        displayName: localizedName,
        iconURL: urlProperty(kTISPropertyIconImageURL, from: source)
    )
}

private func urlProperty(_ key: CFString, from source: TISInputSource) -> URL? {
    guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
    return Unmanaged<CFURL>.fromOpaque(pointer).takeUnretainedValue() as URL
}
```

```swift
func render(model: StatusMenuModel) {
    if let button = statusItem.button {
        switch model.icon {
        case .image(let url):
            if let image = NSImage(contentsOf: url) {
                image.size = NSSize(width: 18, height: 18)
                button.image = image
                button.imagePosition = .imageOnly
                button.title = ""
            } else {
                button.image = nil
                button.title = "⌨︎"
            }
        case .text(let text):
            button.image = nil
            button.title = text
        }
    }
    // existing menu rendering remains
}
```

- [ ] **Step 5: Pass the current input-source icon into the menu model**

```swift
statusBarController?.render(
    model: StatusMenuModel.make(
        activeAppName: currentActiveApp?.displayName ?? "未检测到",
        currentInputSourceName: currentInputSource?.displayName ?? "未检测到",
        currentInputSourceIconURL: currentInputSource?.iconURL,
        isPaused: isPaused
    )
)
```

- [ ] **Step 6: Run the focused tests, then the full suite and build**

Run:

```bash
xcodegen generate
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SettingsViewModelTests -only-testing:InputSwitchTests/StatusMenuModelTests test
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

Expected: all commands succeed; focused tests cover the new setting-management and icon-model behavior.

- [ ] **Step 7: Commit the settings-management and icon follow-up**

Run:

```bash
git add InputSwitch/Domain/InputSourceDescriptor.swift InputSwitch/System/TISInputSourceService.swift InputSwitch/UI/Menu/StatusMenuModel.swift InputSwitch/UI/Menu/StatusBarController.swift InputSwitch/UI/Settings/SettingsViewModel.swift InputSwitch/UI/Settings/GeneralPane.swift InputSwitch/UI/Settings/InputSourcesPane.swift InputSwitch/UI/Settings/RulesPane.swift InputSwitch/App/AppContainer.swift InputSwitchTests/SettingsViewModelTests.swift InputSwitchTests/StatusMenuModelTests.swift
git commit -m "feat: add settings editing and dynamic input source icons"
```

## Self-Review

### Spec Coverage

- 默认输入法设置：由 Task 1 和 Task 2 覆盖。
- 规则新增/编辑/删除：由 Task 1 和 Task 2 覆盖。
- “不管理”规则可见可撤销：由 Task 2 覆盖。
- 输入法列表设为默认：由 Task 2 覆盖。
- 菜单栏图标随当前输入法变化：由 Task 3 覆盖。
- ABC 无系统图标时回退文字：由 Task 3 的菜单模型测试覆盖。

### Placeholder Scan

- 无 `TODO` / `TBD` / “后续再做”占位。
- 每个任务都给了明确文件、代码和命令。

### Type Consistency

- `InputSourceDescriptor.iconURL`、`StatusMenuIcon`、`SettingsRuleDraftKind`、`SettingsRuleRow` 命名在任务内保持一致。
- `SettingsViewModel.reload(...)`、`setDefaultInputSourceID(...)`、`saveRuleDraft()`、`deleteRule(...)` 与屏幕和容器接线保持一致。

## Execution Handoff

计划已完成并保存到 `docs/superpowers/plans/2026-04-08-settings-and-icon-followup.md`。接下来有两种执行方式：

**1. 子代理执行（推荐）** - 我按任务逐个派发新的子代理执行，并在每个任务之间做评审，迭代更快

**2. 当前会话内执行** - 我在这个会话里用 executing-plans 批量执行，并在检查点停下来复核

**你想用哪一种？**
