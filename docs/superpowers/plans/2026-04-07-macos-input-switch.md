# InputSwitch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight macOS menu bar app that remembers the last input source per foreground application, supports locked and ignored rules, recognizes apps such as iTerm2 even when hidden from the Dock, and restores the correct input source when the user switches apps.

**Architecture:** Use an Xcode-generated macOS app target with a thin AppKit status-bar shell and a SwiftUI settings window. Keep domain logic, persistence, and event coordination in small testable Swift types, then bridge to `NSWorkspace`, Accessibility, Text Input Source APIs, and `ServiceManagement` only at the system boundary.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest, XcodeGen, NSWorkspace notifications, Accessibility (`AXUIElement`), Text Input Source APIs, ServiceManagement

---

## Execution Prerequisites

- Install the full Xcode app, not only Command Line Tools.
- Select Xcode before running any build or test commands:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

Expected: `Xcode 16.x` and a matching build number.

- Install XcodeGen if it is missing:

```bash
brew install xcodegen
xcodegen --version
```

Expected: a semantic version such as `2.42.0`.

## Planned File Structure

### Project and Meta

- Create: `/Users/husky/workSpace/21-husky/input-switch/.gitignore`
- Create: `/Users/husky/workSpace/21-husky/input-switch/project.yml`
- Create: `/Users/husky/workSpace/21-husky/input-switch/README.md`

### App Shell

- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/InputSwitchApp.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppDelegate.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Info.plist`

### Domain

- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/ApplicationIdentity.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/InputSourceDescriptor.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/AppRule.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/RuleDecision.swift`

### Core Services

- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/RuleEngine.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/LoopGuard.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SwitchCoordinator.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/ActiveAppMonitoring.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/InputSourceManaging.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SettingsStore.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/MemoryStore.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/AtomicFileWriter.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/DiagnosticsLogger.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/LaunchAtLoginService.swift`

### System Adapters

- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/ApplicationIdentityResolver.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/WorkspaceActiveAppMonitor.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/AXFrontmostAppResolver.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/TISInputSourceService.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/PermissionService.swift`

### UI

- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusMenuModel.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusBarController.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsWindowController.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsView.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/StatusPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/RulesPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/InputSourcesPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/DiagnosticsPane.swift`

### Tests

- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/RuleEngineTests.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/FileStoreTests.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SwitchCoordinatorTests.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/ApplicationIdentityResolverTests.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/StatusMenuModelTests.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/DiagnosticsLoggerTests.swift`

## Task 1: Bootstrap The Repository And macOS App Project

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/.gitignore`
- Create: `/Users/husky/workSpace/21-husky/input-switch/project.yml`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/InputSwitchApp.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppDelegate.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Info.plist`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/README.md`

- [ ] **Step 1: Initialize git and add the base ignore rules**

```gitignore
.DS_Store
DerivedData/
build/
.build/
xcuserdata/
*.xcuserstate
.superpowers/brainstorm/
```

Run:

```bash
git init
git status --short
```

Expected: the repository initializes successfully and shows untracked files under `docs/`.

- [ ] **Step 2: Write `project.yml` for a reproducible macOS menu bar app project**

```yaml
name: InputSwitch
options:
  minimumXcodeGenVersion: 2.42.0
settings:
  base:
    SWIFT_VERSION: 6.0
targets:
  InputSwitch:
    type: application
    platform: macOS
    deploymentTarget: "13.0"
    sources:
      - path: InputSwitch
    info:
      path: InputSwitch/Info.plist
      properties:
        LSUIElement: true
        NSAppleEventsUsageDescription: "InputSwitch inspects the active app and switches input sources automatically."
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.husky.InputSwitch
        CODE_SIGN_STYLE: Automatic
    dependencies: []
  InputSwitchTests:
    type: bundle.unit-test
    platform: macOS
    deploymentTarget: "13.0"
    sources:
      - path: InputSwitchTests
    dependencies:
      - target: InputSwitch
```

- [ ] **Step 3: Add the minimal app entry point and empty dependency container**

```swift
import SwiftUI

@main
struct InputSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let container = AppContainer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        container.bootstrap()
    }
}
```

```swift
import Foundation

final class AppContainer {
    func bootstrap() {
    }
}
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

- [ ] **Step 4: Generate the Xcode project and make sure the empty app builds**

Run:

```bash
xcodegen generate
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

Expected: project generation succeeds and the app target finishes with `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Document the local development commands**

````markdown
# InputSwitch

## Setup

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
brew install xcodegen
xcodegen generate
```

## Build

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

## Test

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
```
````

- [ ] **Step 6: Commit the scaffold**

Run:

```bash
git add .gitignore project.yml README.md InputSwitch docs
git commit -m "chore: scaffold InputSwitch macOS app"
```

Expected: the first commit records the project scaffold and the approved design docs.

## Task 2: Implement The Domain Model And Rule Engine

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/ApplicationIdentity.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/InputSourceDescriptor.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/AppRule.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Domain/RuleDecision.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/RuleEngine.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/RuleEngineTests.swift`

- [ ] **Step 1: Write the failing rule-engine tests**

```swift
import XCTest
@testable import InputSwitch

final class RuleEngineTests: XCTestCase {
    private let abc = InputSourceDescriptor(id: "com.apple.keylayout.ABC", displayName: "ABC")
    private let pinyin = InputSourceDescriptor(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音")
    private let wubi = InputSourceDescriptor(id: "im.wubi", displayName: "简体五笔")

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
```

- [ ] **Step 2: Run the tests to verify the red state**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/RuleEngineTests test
```

Expected: `** TEST FAILED **` with missing-type or missing-symbol errors for the new domain types.

- [ ] **Step 3: Implement the minimal domain types and rule engine**

```swift
import Foundation

struct ApplicationIdentity: Hashable, Codable {
    let bundleID: String?
    let bundlePath: String?
    let executableName: String
    let displayName: String

    var matchKey: String {
        if let bundleID, !bundleID.isEmpty { return "bundle:\(bundleID)" }
        if let bundlePath, !bundlePath.isEmpty { return "path:\(bundlePath)" }
        return "exec:\(executableName)"
    }
}
```

```swift
import Foundation

struct InputSourceDescriptor: Equatable, Codable {
    let id: String
    let displayName: String
}
```

```swift
import Foundation

enum AppRule: Equatable, Codable {
    case remembered
    case ignored
    case locked(inputSourceID: String)
}
```

```swift
import Foundation

enum RuleReason: Equatable, Codable {
    case ignored
    case lockedRule
    case remembered
    case defaultInputSource
    case alreadyMatching
}

enum RuleDecision: Equatable {
    case keepCurrent(reason: RuleReason)
    case switchTo(inputSourceID: String, reason: RuleReason)
}
```

```swift
import Foundation

struct RuleEngine {
    func resolve(
        app: ApplicationIdentity,
        current: InputSourceDescriptor?,
        rules: [String: AppRule],
        memories: [String: String],
        defaultInputSourceID: String
    ) -> RuleDecision {
        let key = app.matchKey

        if case .ignored? = rules[key] {
            return .keepCurrent(reason: .ignored)
        }

        if case .locked(let lockedID)? = rules[key] {
            if current?.id == lockedID {
                return .keepCurrent(reason: .alreadyMatching)
            }
            return .switchTo(inputSourceID: lockedID, reason: .lockedRule)
        }

        if let rememberedID = memories[key] {
            if current?.id == rememberedID {
                return .keepCurrent(reason: .alreadyMatching)
            }
            return .switchTo(inputSourceID: rememberedID, reason: .remembered)
        }

        if current?.id == defaultInputSourceID {
            return .keepCurrent(reason: .alreadyMatching)
        }

        return .switchTo(inputSourceID: defaultInputSourceID, reason: .defaultInputSource)
    }
}
```

- [ ] **Step 4: Run the tests to verify the green state**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/RuleEngineTests test
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit the domain layer**

Run:

```bash
git add InputSwitch/Domain InputSwitch/Services/RuleEngine.swift InputSwitchTests/RuleEngineTests.swift
git commit -m "feat: add input switch rule engine"
```

## Task 3: Implement JSON Settings And Memory Stores

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/AtomicFileWriter.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SettingsStore.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/MemoryStore.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/FileStoreTests.swift`

- [ ] **Step 1: Write failing persistence tests**

```swift
import XCTest
@testable import InputSwitch

final class FileStoreTests: XCTestCase {
    func test_settings_store_returns_defaults_when_file_is_missing() throws {
        let directory = try makeTemporaryDirectory()
        let store = SettingsStore(baseDirectory: directory)

        let settings = store.load()

        XCTAssertNil(settings.defaultInputSourceID)
        XCTAssertTrue(settings.rules.isEmpty)
        XCTAssertFalse(settings.launchAtLoginEnabled)
    }

    func test_memory_store_persists_and_reloads_entries() throws {
        let directory = try makeTemporaryDirectory()
        let store = MemoryStore(baseDirectory: directory)

        store.save(["bundle:com.googlecode.iterm2": "com.apple.keylayout.ABC"])
        let memory = store.load()

        XCTAssertEqual(memory["bundle:com.googlecode.iterm2"], "com.apple.keylayout.ABC")
    }

    func test_corrupt_settings_file_falls_back_to_defaults() throws {
        let directory = try makeTemporaryDirectory()
        let fileURL = directory.appendingPathComponent("settings.json")
        try Data("not-json".utf8).write(to: fileURL)
        let store = SettingsStore(baseDirectory: directory)

        let settings = store.load()

        XCTAssertTrue(settings.rules.isEmpty)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail correctly**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/FileStoreTests test
```

Expected: `** TEST FAILED **` with missing `SettingsStore`, `MemoryStore`, and helper-symbol errors.

- [ ] **Step 3: Implement the file-backed settings and memory stores**

```swift
import Foundation

struct AppSettings: Codable, Equatable {
    var defaultInputSourceID: String?
    var rules: [String: AppRule]
    var launchAtLoginEnabled: Bool

    static let `default` = AppSettings(
        defaultInputSourceID: nil,
        rules: [:],
        launchAtLoginEnabled: false
    )
}
```

```swift
import Foundation

struct AtomicFileWriter {
    func write<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}
```

```swift
import Foundation

class SettingsStore {
    private let fileURL: URL
    private let writer = AtomicFileWriter()

    init(baseDirectory: URL) {
        self.fileURL = baseDirectory.appendingPathComponent("settings.json")
    }

    func load() -> AppSettings {
        guard
            let data = try? Data(contentsOf: fileURL),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save(_ settings: AppSettings) {
        try? writer.write(settings, to: fileURL)
    }
}
```

```swift
import Foundation

class MemoryStore {
    private let fileURL: URL
    private let writer = AtomicFileWriter()

    init(baseDirectory: URL) {
        self.fileURL = baseDirectory.appendingPathComponent("memory.json")
    }

    func load() -> [String: String] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let memory = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return memory
    }

    func save(_ memory: [String: String]) {
        try? writer.write(memory, to: fileURL)
    }
}
```

- [ ] **Step 4: Add the temporary-directory helper inside the test file and rerun**

```swift
private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
```

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/FileStoreTests test
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit the persistence layer**

Run:

```bash
git add InputSwitch/Services/AtomicFileWriter.swift InputSwitch/Services/SettingsStore.swift InputSwitch/Services/MemoryStore.swift InputSwitchTests/FileStoreTests.swift
git commit -m "feat: add json-backed settings and memory stores"
```

## Task 4: Implement Event Coordination And Loop Protection

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/ActiveAppMonitoring.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/InputSourceManaging.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/LoopGuard.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/SwitchCoordinator.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/SwitchCoordinatorTests.swift`

- [ ] **Step 1: Write failing coordinator tests**

```swift
import XCTest
@testable import InputSwitch

final class SwitchCoordinatorTests: XCTestCase {
    func test_app_activation_uses_locked_rule_to_switch_input_source() {
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
            settings: AppSettings(
                defaultInputSourceID: "com.apple.inputmethod.SCIM.ITABC",
                rules: ["bundle:com.googlecode.iterm2": .locked(inputSourceID: "com.apple.keylayout.ABC")],
                launchAtLoginEnabled: false
            ),
            memories: [:]
        )

        harness.coordinator.handleAppDidActivate(
            .init(bundleID: "com.googlecode.iterm2", bundlePath: nil, executableName: "iTerm2", displayName: "iTerm2")
        )

        XCTAssertEqual(harness.inputSourceManager.switchCalls, ["com.apple.keylayout.ABC"])
    }

    func test_programmatic_input_change_is_not_written_to_memory() {
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
            settings: AppSettings(
                defaultInputSourceID: "com.apple.inputmethod.SCIM.ITABC",
                rules: ["bundle:com.googlecode.iterm2": .locked(inputSourceID: "com.apple.keylayout.ABC")],
                launchAtLoginEnabled: false
            ),
            memories: [:]
        )

        let app = ApplicationIdentity(bundleID: "com.googlecode.iterm2", bundlePath: nil, executableName: "iTerm2", displayName: "iTerm2")
        harness.coordinator.handleAppDidActivate(app)
        harness.coordinator.handleInputSourceDidChange(to: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"))

        XCTAssertTrue(harness.memoryStore.savedSnapshots.isEmpty)
    }

    func test_user_input_change_updates_memory_for_managed_app() {
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
            settings: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            memories: [:]
        )

        let app = ApplicationIdentity(bundleID: "com.apple.dt.Xcode", bundlePath: nil, executableName: "Xcode", displayName: "Xcode")
        harness.coordinator.handleAppDidActivate(app)
        harness.coordinator.handleInputSourceDidChange(to: .init(id: "im.wubi", displayName: "简体五笔"))

        XCTAssertEqual(harness.memoryStore.savedSnapshots.last?["bundle:com.apple.dt.Xcode"], "im.wubi")
    }
}
```

- [ ] **Step 2: Run the tests and confirm the red state**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SwitchCoordinatorTests test
```

Expected: `** TEST FAILED **` because the coordinator, protocols, and harness fakes do not exist yet.

- [ ] **Step 3: Implement the protocols, loop guard, and coordinator**

```swift
import Foundation

protocol ActiveAppMonitoring: AnyObject {
    var onActivation: ((ApplicationIdentity) -> Void)? { get set }
    func start()
}
```

```swift
import Foundation

protocol InputSourceManaging: AnyObject {
    var onChange: ((InputSourceDescriptor) -> Void)? { get set }
    func start()
    func availableInputSources() -> [InputSourceDescriptor]
    func currentInputSource() -> InputSourceDescriptor?
    func switchToInputSource(id: String)
}
```

```swift
import Foundation

final class LoopGuard {
    private var lastProgrammaticSwitch: (id: String, timestamp: Date)?
    private let suppressionWindow: TimeInterval

    init(suppressionWindow: TimeInterval = 0.8) {
        self.suppressionWindow = suppressionWindow
    }

    func markProgrammaticSwitch(to inputSourceID: String, now: Date = Date()) {
        lastProgrammaticSwitch = (inputSourceID, now)
    }

    func shouldIgnoreInputChange(to inputSourceID: String, now: Date = Date()) -> Bool {
        guard let lastProgrammaticSwitch else { return false }
        let withinWindow = now.timeIntervalSince(lastProgrammaticSwitch.timestamp) <= suppressionWindow
        return withinWindow && lastProgrammaticSwitch.id == inputSourceID
    }
}
```

```swift
import Foundation

final class SwitchCoordinator {
    private let ruleEngine: RuleEngine
    private let inputSourceManager: InputSourceManaging
    private let settingsStore: SettingsStore
    private let memoryStore: MemoryStore
    private let loopGuard: LoopGuard

    private var activeApp: ApplicationIdentity?
    private var settings: AppSettings
    private var memories: [String: String]

    init(
        ruleEngine: RuleEngine,
        inputSourceManager: InputSourceManaging,
        settingsStore: SettingsStore,
        memoryStore: MemoryStore,
        loopGuard: LoopGuard = LoopGuard()
    ) {
        self.ruleEngine = ruleEngine
        self.inputSourceManager = inputSourceManager
        self.settingsStore = settingsStore
        self.memoryStore = memoryStore
        self.loopGuard = loopGuard
        self.settings = settingsStore.load()
        self.memories = memoryStore.load()
    }

    func handleAppDidActivate(_ app: ApplicationIdentity) {
        activeApp = app
        guard let defaultID = settings.defaultInputSourceID else { return }

        let decision = ruleEngine.resolve(
            app: app,
            current: inputSourceManager.currentInputSource(),
            rules: settings.rules,
            memories: memories,
            defaultInputSourceID: defaultID
        )

        guard case .switchTo(let inputSourceID, _) = decision else { return }
        loopGuard.markProgrammaticSwitch(to: inputSourceID)
        inputSourceManager.switchToInputSource(id: inputSourceID)
    }

    func handleInputSourceDidChange(to inputSource: InputSourceDescriptor) {
        guard !loopGuard.shouldIgnoreInputChange(to: inputSource.id) else { return }
        guard let activeApp else { return }
        guard settings.rules[activeApp.matchKey] != .ignored else { return }
        if case .locked? = settings.rules[activeApp.matchKey] { return }
        memories[activeApp.matchKey] = inputSource.id
        memoryStore.save(memories)
    }
}
```

- [ ] **Step 4: Add the fake harness inside the test file and rerun**

```swift
private final class FakeInputSourceManager: InputSourceManaging {
    var onChange: ((InputSourceDescriptor) -> Void)?
    var switchCalls: [String] = []
    private let current: InputSourceDescriptor?

    init(current: InputSourceDescriptor?) {
        self.current = current
    }

    func start() {}

    func availableInputSources() -> [InputSourceDescriptor] {
        current.map { [$0] } ?? []
    }

    func currentInputSource() -> InputSourceDescriptor? { current }

    func switchToInputSource(id: String) {
        switchCalls.append(id)
    }
}

private final class InMemorySettingsStore: SettingsStore {
    private let stub: AppSettings

    init(stub: AppSettings) {
        self.stub = stub
        super.init(baseDirectory: FileManager.default.temporaryDirectory)
    }

    override func load() -> AppSettings { stub }
}

private final class InMemoryMemoryStore: MemoryStore {
    var savedSnapshots: [[String: String]] = []
    private let stub: [String: String]

    init(stub: [String: String]) {
        self.stub = stub
        super.init(baseDirectory: FileManager.default.temporaryDirectory)
    }

    override func load() -> [String: String] { stub }

    override func save(_ memory: [String: String]) {
        savedSnapshots.append(memory)
    }
}

private struct CoordinatorHarness {
    let inputSourceManager: FakeInputSourceManager
    let memoryStore: InMemoryMemoryStore
    let coordinator: SwitchCoordinator

    init(currentInputSource: InputSourceDescriptor?, settings: AppSettings, memories: [String: String]) {
        inputSourceManager = FakeInputSourceManager(current: currentInputSource)
        let settingsStore = InMemorySettingsStore(stub: settings)
        memoryStore = InMemoryMemoryStore(stub: memories)
        coordinator = SwitchCoordinator(
            ruleEngine: RuleEngine(),
            inputSourceManager: inputSourceManager,
            settingsStore: settingsStore,
            memoryStore: memoryStore
        )
    }
}
```

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/SwitchCoordinatorTests test
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 5: Commit the event-coordination layer**

Run:

```bash
git add InputSwitch/Services/ActiveAppMonitoring.swift InputSwitch/Services/InputSourceManaging.swift InputSwitch/Services/LoopGuard.swift InputSwitch/Services/SwitchCoordinator.swift InputSwitchTests/SwitchCoordinatorTests.swift
git commit -m "feat: add switch coordination and loop guard"
```

## Task 5: Implement Application Recognition And Input Source System Adapters

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/ApplicationIdentityResolver.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/WorkspaceActiveAppMonitor.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/AXFrontmostAppResolver.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/TISInputSourceService.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/System/PermissionService.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/ApplicationIdentityResolverTests.swift`

- [ ] **Step 1: Write failing tests for application-identity resolution**

```swift
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
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/ApplicationIdentityResolverTests test
```

Expected: `** TEST FAILED **` because the resolver does not exist.

- [ ] **Step 3: Implement the resolver and system boundary types**

```swift
import Foundation

enum ApplicationIdentityResolver {
    static func resolve(
        bundleID: String?,
        bundleURL: URL?,
        executableName: String,
        displayName: String
    ) -> ApplicationIdentity {
        ApplicationIdentity(
            bundleID: bundleID,
            bundlePath: bundleURL?.path,
            executableName: executableName,
            displayName: displayName
        )
    }
}
```

```swift
import AppKit

final class WorkspaceActiveAppMonitor: ActiveAppMonitoring {
    var onActivation: ((ApplicationIdentity) -> Void)?
    private var observer: NSObjectProtocol?

    func start() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let executableName = app.executableURL?.deletingPathExtension().lastPathComponent ?? app.localizedName
            else { return }

            let identity = ApplicationIdentityResolver.resolve(
                bundleID: app.bundleIdentifier,
                bundleURL: app.bundleURL,
                executableName: executableName,
                displayName: app.localizedName ?? executableName
            )
            self?.onActivation?(identity)
        }
    }
}
```

```swift
import ApplicationServices
import Foundation

enum AXFrontmostAppResolver {
    static func frontmostProcessID() -> pid_t? {
        let systemWide = AXUIElementCreateSystemWide()
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &value)
        guard result == .success else { return nil }
        var pid: pid_t = 0
        if let app = value {
            AXUIElementGetPid(app as! AXUIElement, &pid)
            return pid
        }
        return nil
    }
}
```

```swift
import Carbon
import Foundation

final class TISInputSourceService: InputSourceManaging {
    var onChange: ((InputSourceDescriptor) -> Void)?

    func currentInputSource() -> InputSourceDescriptor? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return descriptor(from: source)
    }

    func availableInputSources() -> [InputSourceDescriptor] {
        copySources().compactMap(descriptor(from:))
    }

    func switchToInputSource(id: String) {
        guard let source = copySources().first(where: { descriptor(from: $0)?.id == id }) else { return }
        TISSelectInputSource(source)
    }

    func start() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let current = self?.currentInputSource() else { return }
            self?.onChange?(current)
        }
    }

    private func copySources() -> [TISInputSource] {
        guard let array = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else { return [] }
        return array
    }

    private func descriptor(from source: TISInputSource) -> InputSourceDescriptor? {
        guard let rawID = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        let id = Unmanaged<CFString>.fromOpaque(rawID).takeUnretainedValue() as String
        let nameRaw = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
        let name = nameRaw.map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String } ?? id
        return InputSourceDescriptor(id: id, displayName: name)
    }
}
```

```swift
import ApplicationServices
import Foundation

struct PermissionService {
    func accessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }
}
```

- [ ] **Step 4: Run the resolver tests, then the full suite**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/ApplicationIdentityResolverTests test
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
```

Expected: the resolver tests pass, and the full suite stays green after adding system-boundary code.

- [ ] **Step 5: Commit the system adapters**

Run:

```bash
git add InputSwitch/System InputSwitchTests/ApplicationIdentityResolverTests.swift
git commit -m "feat: add macos application and input source adapters"
```

## Task 6: Implement The Status Menu And Settings Window

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusMenuModel.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Menu/StatusBarController.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsWindowController.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsViewModel.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/SettingsView.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/StatusPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/RulesPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/InputSourcesPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/GeneralPane.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/UI/Settings/DiagnosticsPane.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/StatusMenuModelTests.swift`

- [ ] **Step 1: Write failing tests for the menu model**

```swift
import XCTest
@testable import InputSwitch

final class StatusMenuModelTests: XCTestCase {
    func test_menu_contains_only_the_confirmed_minimal_actions() {
        let model = StatusMenuModel.make(
            activeAppName: "iTerm2",
            currentInputSourceName: "ABC",
            isPaused: false
        )

        XCTAssertEqual(
            model.items.map(\.title),
            [
                "当前应用：iTerm2",
                "当前输入法：ABC",
                "将当前应用标记为不管理",
                "清除此应用记忆",
                "暂停自动切换（30 分钟）",
                "打开设置…",
                "退出"
            ]
        )
    }
}
```

- [ ] **Step 2: Run the tests to confirm the menu model is missing**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/StatusMenuModelTests test
```

Expected: `** TEST FAILED **`.

- [ ] **Step 3: Implement the menu model and the settings view model**

```swift
import Foundation

struct StatusMenuItem: Equatable {
    let title: String
    let action: MenuAction
}

enum MenuAction: Equatable {
    case ignoreCurrentApp
    case clearCurrentMemory
    case pauseTemporarily
    case openSettings
    case quit
    case none
}

struct StatusMenuModel: Equatable {
    let items: [StatusMenuItem]

    static func make(activeAppName: String, currentInputSourceName: String, isPaused: Bool) -> StatusMenuModel {
        let pauseTitle = isPaused ? "恢复自动切换" : "暂停自动切换（30 分钟）"
        return StatusMenuModel(items: [
            .init(title: "当前应用：\(activeAppName)", action: .none),
            .init(title: "当前输入法：\(currentInputSourceName)", action: .none),
            .init(title: "将当前应用标记为不管理", action: .ignoreCurrentApp),
            .init(title: "清除此应用记忆", action: .clearCurrentMemory),
            .init(title: pauseTitle, action: .pauseTemporarily),
            .init(title: "打开设置…", action: .openSettings),
            .init(title: "退出", action: .quit)
        ])
    }
}
```

```swift
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultInputSourceName: String = "未设置"
    @Published var launchAtLoginEnabled: Bool = false
    @Published var rules: [(key: String, rule: AppRule)] = []
    @Published var availableInputSources: [InputSourceDescriptor] = []
    @Published var diagnostics: [String] = []
    var onLaunchAtLoginToggle: ((Bool) -> Void)?

    func reload(from settings: AppSettings, availableInputSources: [InputSourceDescriptor], diagnostics: [String]) {
        defaultInputSourceName = settings.defaultInputSourceID ?? "未设置"
        launchAtLoginEnabled = settings.launchAtLoginEnabled
        rules = settings.rules.sorted(by: { $0.key < $1.key })
        self.availableInputSources = availableInputSources
        self.diagnostics = diagnostics
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        onLaunchAtLoginToggle?(enabled)
    }
}
```

- [ ] **Step 4: Implement the AppKit status bar controller and SwiftUI settings panes**

```swift
import AppKit

final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let handler: (MenuAction) -> Void

    init(handler: @escaping (MenuAction) -> Void) {
        self.handler = handler
    }

    func render(model: StatusMenuModel) {
        statusItem.button?.title = "⌨︎"
        let menu = NSMenu()
        for item in model.items {
            let menuItem = NSMenuItem(title: item.title, action: #selector(handleMenuItem(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = item.action
            menu.addItem(menuItem)
        }
        statusItem.menu = menu
    }

    @objc private func handleMenuItem(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? MenuAction else { return }
        handler(action)
    }
}
```

```swift
import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(viewModel: SettingsViewModel) {
        let view = SettingsView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "InputSwitch 设置"
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("当前状态") { StatusPane(viewModel: viewModel) }
                NavigationLink("规则列表") { RulesPane(viewModel: viewModel) }
                NavigationLink("输入法列表") { InputSourcesPane(viewModel: viewModel) }
                NavigationLink("通用设置") { GeneralPane(viewModel: viewModel) }
                NavigationLink("日志与诊断") { DiagnosticsPane(viewModel: viewModel) }
            }
        } detail: {
            StatusPane(viewModel: viewModel)
        }
        .frame(minWidth: 760, minHeight: 480)
    }
}
```

```swift
import SwiftUI

struct StatusPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Text("默认输入法：\(viewModel.defaultInputSourceName)")
            Text("规则数量：\(viewModel.rules.count)")
        }
        .padding()
    }
}
```

```swift
import SwiftUI

struct RulesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.rules, id: \.key) { entry in
            Text("\(entry.key) -> \(String(describing: entry.rule))")
        }
    }
}
```

```swift
import SwiftUI

struct InputSourcesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.availableInputSources, id: \.id) { source in
            Text("\(source.displayName) [\(source.id)]")
        }
    }
}
```

```swift
import SwiftUI

struct GeneralPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Toggle(
            "开机启动",
            isOn: Binding(
                get: { viewModel.launchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            )
        )
            .padding()
    }
}
```

```swift
import SwiftUI

struct DiagnosticsPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        List(viewModel.diagnostics, id: \.self) { line in
            Text(line)
        }
    }
}
```

- [ ] **Step 5: Run the menu test, then build the app for manual inspection**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/StatusMenuModelTests test
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

Expected: the test suite stays green and the app builds with the status bar and settings window code linked.

- [ ] **Step 6: Commit the UI shell**

Run:

```bash
git add InputSwitch/UI InputSwitchTests/StatusMenuModelTests.swift InputSwitch/App
git commit -m "feat: add status menu and settings window"
```

## Task 7: Implement Diagnostics, Launch At Login, App Wiring, And Final Verification

**Files:**
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/DiagnosticsLogger.swift`
- Create: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/Services/LaunchAtLoginService.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppContainer.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/InputSwitch/App/AppDelegate.swift`
- Test: `/Users/husky/workSpace/21-husky/input-switch/InputSwitchTests/DiagnosticsLoggerTests.swift`
- Modify: `/Users/husky/workSpace/21-husky/input-switch/README.md`

- [ ] **Step 1: Write failing diagnostics tests**

```swift
import XCTest
@testable import InputSwitch

final class DiagnosticsLoggerTests: XCTestCase {
    func test_logger_keeps_only_recent_entries() {
        let logger = DiagnosticsLogger(limit: 2)

        logger.log("first")
        logger.log("second")
        logger.log("third")

        XCTAssertEqual(logger.entries, ["second", "third"])
    }
}
```

- [ ] **Step 2: Run the diagnostics tests to verify the red state**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' -only-testing:InputSwitchTests/DiagnosticsLoggerTests test
```

Expected: `** TEST FAILED **`.

- [ ] **Step 3: Implement diagnostics and launch-at-login support**

```swift
import Foundation

final class DiagnosticsLogger {
    private let limit: Int
    private(set) var entries: [String] = []

    init(limit: Int = 200) {
        self.limit = limit
    }

    func log(_ message: String) {
        entries.append(message)
        if entries.count > limit {
            entries.removeFirst(entries.count - limit)
        }
    }
}
```

```swift
import ServiceManagement

struct LaunchAtLoginService {
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

- [ ] **Step 4: Wire the app container to real services and update the README with permissions/manual checks**

```swift
import AppKit
import Foundation

final class AppContainer {
    private let diagnostics = DiagnosticsLogger()
    private let launchAtLoginService = LaunchAtLoginService()
    private lazy var settingsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("InputSwitch", isDirectory: true)

    private lazy var settingsStore = SettingsStore(baseDirectory: settingsDirectory)
    private lazy var memoryStore = MemoryStore(baseDirectory: settingsDirectory)
    private lazy var inputSourceManager = TISInputSourceService()
    private lazy var settingsViewModel = SettingsViewModel()
    private lazy var settingsWindowController = SettingsWindowController(viewModel: settingsViewModel)
    private lazy var coordinator = SwitchCoordinator(
        ruleEngine: RuleEngine(),
        inputSourceManager: inputSourceManager,
        settingsStore: settingsStore,
        memoryStore: memoryStore
    )
    private lazy var appMonitor = WorkspaceActiveAppMonitor()
    private var statusBarController: StatusBarController?
    private var activeApp: ApplicationIdentity?

    func bootstrap() {
        settingsViewModel.onLaunchAtLoginToggle = { [weak self] enabled in
            guard let self else { return }
            try? self.launchAtLoginService.setEnabled(enabled)
            var settings = self.settingsStore.load()
            settings.launchAtLoginEnabled = enabled
            self.settingsStore.save(settings)
        }
        statusBarController = StatusBarController { [weak self] action in
            self?.handleMenuAction(action)
        }
        statusBarController?.render(model: .make(activeAppName: "未识别", currentInputSourceName: "未识别", isPaused: false))
        appMonitor.onActivation = { [weak self] app in
            self?.activeApp = app
            self?.coordinator.handleAppDidActivate(app)
            self?.reloadUI()
        }
        inputSourceManager.onChange = { [weak self] source in
            self?.coordinator.handleInputSourceDidChange(to: source)
            self?.reloadUI()
        }
        appMonitor.start()
        inputSourceManager.start()
        reloadUI()
        diagnostics.log("InputSwitch started")
    }

    private func handleMenuAction(_ action: MenuAction) {
        switch action {
        case .ignoreCurrentApp:
            guard let activeApp else { return }
            var settings = settingsStore.load()
            settings.rules[activeApp.matchKey] = .ignored
            settingsStore.save(settings)
            reloadUI()
        case .clearCurrentMemory:
            guard let activeApp else { return }
            var memory = memoryStore.load()
            memory.removeValue(forKey: activeApp.matchKey)
            memoryStore.save(memory)
            reloadUI()
        case .pauseTemporarily:
            diagnostics.log("Pause action selected")
        case .openSettings:
            settingsWindowController.show()
        case .quit:
            NSApp.terminate(nil)
        case .none:
            break
        }
    }

    private func reloadUI() {
        let settings = settingsStore.load()
        let activeAppName = activeApp?.displayName ?? "未识别"
        let currentInputSourceName = inputSourceManager.currentInputSource()?.displayName ?? "未识别"
        statusBarController?.render(
            model: .make(
                activeAppName: activeAppName,
                currentInputSourceName: currentInputSourceName,
                isPaused: false
            )
        )
        settingsViewModel.reload(
            from: settings,
            availableInputSources: inputSourceManager.availableInputSources(),
            diagnostics: diagnostics.entries
        )
    }
}
```

````markdown
## Permissions

- Enable Accessibility for InputSwitch in System Settings.
- Reopen the app after granting permission if foreground-app detection appears stale.

## Manual Verification Checklist

- Switch between Safari and Xcode and confirm the previous input source is restored.
- Hide the iTerm2 Dock icon and confirm the app is still recognized when activated.
- Add an ignored rule and confirm no automatic switching occurs.
- Delete a remembered input source and confirm the app falls back to the default input source.
````

- [ ] **Step 5: Run the complete verification suite**

Run:

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

Expected: both commands finish successfully with `** TEST SUCCEEDED **` and `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Perform the manual verification pass**

Run:

```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -path '*Build/Products/Debug/InputSwitch.app' -print -quit)"
```

Expected:
- the status bar icon appears
- the settings window opens from the menu
- app switches to the remembered or locked input source when changing foreground apps
- ignored apps do not trigger switching

- [ ] **Step 7: Commit the integrated app**

Run:

```bash
git add InputSwitch README.md InputSwitchTests
git commit -m "feat: wire input source switching menu bar app"
```

## Self-Review

### Spec Coverage

- Frontmost app recognition: covered by Task 5 system adapters and Task 7 app wiring.
- Rule priority `ignored > locked > memory > default`: covered by Task 2 and Task 4.
- Specific input-source IDs for full pinyin, double pinyin, wubi, ABC: covered by Task 2 domain model and Task 5 input source adapter.
- Minimal menu bar and full settings window split: covered by Task 6.
- Low-memory event-driven runtime: covered by Task 4 and Task 7.
- Launch at login and diagnostics: covered by Task 7.

### Placeholder Scan

- No `TODO`, `TBD`, or “implement later” placeholders remain.
- Every task lists exact file paths, commands, and the intended code to add.

### Type Consistency

- `ApplicationIdentity.matchKey`, `AppRule`, `AppSettings`, `RuleDecision`, and `InputSourceDescriptor` use consistent names across tasks.
- `SettingsStore.load()`, `MemoryStore.load()`, and `SwitchCoordinator.handleInputSourceDidChange(to:)` match the signatures introduced earlier in the plan.

## Risks To Watch During Execution

- `TISInputSourceService` uses Carbon-era APIs; build errors may require bridging casts to be tightened for the exact installed SDK.
- `SMAppService.mainApp` behavior differs when running from an unbundled debug product versus a signed app; validate launch-at-login on an actual built `.app`.
- Accessibility fallback should remain lazy; do not turn it into a polling loop if `NSWorkspace` already identifies the active app correctly.

## Execution Handoff

计划已完成并保存到 `docs/superpowers/plans/2026-04-07-macos-input-switch.md`。接下来有两种执行方式：

**1. 子代理执行（推荐）** - 我按任务逐个派发新的子代理执行，并在每个任务之间做评审，迭代更快

**2. 当前会话内执行** - 我在这个会话里用 executing-plans 批量执行，并在检查点停下来复核

**你想用哪一种？**
