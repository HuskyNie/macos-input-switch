import XCTest
@testable import InputSwitch

final class SwitchCoordinatorTests: XCTestCase {
    func test_app_activation_uses_locked_rule_to_switch_input_source() {
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
            availableInputSources: [
                .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
            ],
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
            availableInputSources: [
                .init(id: "com.apple.inputmethod.SCIM.ITABC", displayName: "简体拼音"),
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
            ],
            settings: AppSettings(
                defaultInputSourceID: "com.apple.inputmethod.SCIM.ITABC",
                rules: ["bundle:com.googlecode.iterm2": .locked(inputSourceID: "com.apple.keylayout.ABC")],
                launchAtLoginEnabled: false
            ),
            memories: [:]
        )

        let app = ApplicationIdentity(
            bundleID: "com.googlecode.iterm2",
            bundlePath: nil,
            executableName: "iTerm2",
            displayName: "iTerm2"
        )

        harness.coordinator.handleAppDidActivate(app)
        XCTAssertNoThrow(
            try harness.coordinator.handleInputSourceDidChange(to: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"))
        )

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

        let app = ApplicationIdentity(
            bundleID: "com.apple.dt.Xcode",
            bundlePath: nil,
            executableName: "Xcode",
            displayName: "Xcode"
        )

        harness.coordinator.handleAppDidActivate(app)
        XCTAssertNoThrow(
            try harness.coordinator.handleInputSourceDidChange(to: .init(id: "im.wubi", displayName: "简体五笔"))
        )

        XCTAssertEqual(harness.memoryStore.savedSnapshots.last?["bundle:com.apple.dt.Xcode"], "im.wubi")
    }

    func test_user_input_change_propagates_memory_save_failure() {
        let expectedError = StubError.memorySaveFailed
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
            settings: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            memories: [:],
            memorySaveError: expectedError
        )

        let app = ApplicationIdentity(
            bundleID: "com.apple.dt.Xcode",
            bundlePath: nil,
            executableName: "Xcode",
            displayName: "Xcode"
        )

        harness.coordinator.handleAppDidActivate(app)

        XCTAssertThrowsError(
            try harness.coordinator.handleInputSourceDidChange(to: .init(id: "im.wubi", displayName: "简体五笔"))
        ) { error in
            XCTAssertEqual(error as? StubError, expectedError)
        }
    }

    func test_app_activation_falls_back_to_default_and_logs_when_remembered_input_source_is_unavailable() {
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.keylayout.US", displayName: "U.S."),
            availableInputSources: [
                .init(id: "com.apple.keylayout.US", displayName: "U.S."),
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC")
            ],
            settings: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            memories: ["bundle:com.apple.dt.Xcode": "im.wubi"]
        )

        harness.coordinator.handleAppDidActivate(
            .init(bundleID: "com.apple.dt.Xcode", bundlePath: nil, executableName: "Xcode", displayName: "Xcode")
        )

        XCTAssertEqual(harness.inputSourceManager.switchCalls, ["com.apple.keylayout.ABC"])
        XCTAssertEqual(
            harness.diagnostics,
            [
                "目标输入法已不可用，应用：Xcode，原因：remembered，输入法 ID：im.wubi",
                "已回退到默认输入法，应用：Xcode，输入法 ID：com.apple.keylayout.ABC"
            ]
        )
    }

    func test_app_activation_keeps_current_and_logs_when_target_and_default_input_sources_are_unavailable() {
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.keylayout.US", displayName: "U.S."),
            availableInputSources: [.init(id: "com.apple.keylayout.US", displayName: "U.S.")],
            settings: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            memories: ["bundle:com.apple.dt.Xcode": "im.wubi"]
        )

        harness.coordinator.handleAppDidActivate(
            .init(bundleID: "com.apple.dt.Xcode", bundlePath: nil, executableName: "Xcode", displayName: "Xcode")
        )

        XCTAssertTrue(harness.inputSourceManager.switchCalls.isEmpty)
        XCTAssertEqual(
            harness.diagnostics,
            [
                "目标输入法已不可用，应用：Xcode，原因：remembered，输入法 ID：im.wubi",
                "默认输入法也不可用，保持当前输入法不变，应用：Xcode，默认输入法 ID：com.apple.keylayout.ABC"
            ]
        )
    }

    func test_failed_memory_save_does_not_update_runtime_memory_state() {
        let expectedError = StubError.memorySaveFailed
        let harness = CoordinatorHarness(
            currentInputSource: .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
            availableInputSources: [
                .init(id: "com.apple.keylayout.ABC", displayName: "ABC"),
                .init(id: "im.wubi", displayName: "简体五笔")
            ],
            settings: AppSettings(
                defaultInputSourceID: "com.apple.keylayout.ABC",
                rules: [:],
                launchAtLoginEnabled: false
            ),
            memories: [:],
            memorySaveError: expectedError
        )

        let app = ApplicationIdentity(
            bundleID: "com.apple.dt.Xcode",
            bundlePath: nil,
            executableName: "Xcode",
            displayName: "Xcode"
        )

        harness.coordinator.handleAppDidActivate(app)

        XCTAssertThrowsError(
            try harness.coordinator.handleInputSourceDidChange(to: .init(id: "im.wubi", displayName: "简体五笔"))
        ) { error in
            XCTAssertEqual(error as? StubError, expectedError)
        }

        harness.inputSourceManager.resetSwitchCalls()
        harness.coordinator.handleAppDidActivate(app)

        XCTAssertTrue(harness.inputSourceManager.switchCalls.isEmpty)
    }
}

private final class FakeInputSourceManager: InputSourceManaging {
    var onChange: ((InputSourceDescriptor) -> Void)?
    var switchCalls: [String] = []

    private let availableSources: [InputSourceDescriptor]
    private var current: InputSourceDescriptor?

    init(current: InputSourceDescriptor?, availableSources: [InputSourceDescriptor]) {
        self.current = current
        self.availableSources = availableSources
    }

    func start() {}

    func availableInputSources() -> [InputSourceDescriptor] {
        availableSources
    }

    func currentInputSource() -> InputSourceDescriptor? {
        current
    }

    func switchToInputSource(id: String) {
        switchCalls.append(id)
        current = availableSources.first(where: { $0.id == id }) ?? current
    }

    func resetSwitchCalls() {
        switchCalls.removeAll()
    }
}

private struct StubSettingsStore: SettingsProviding {
    let settings: AppSettings

    func load() -> AppSettings {
        settings
    }
}

private final class RecordingMemoryStore: MemoryStoring {
    private let initialMemory: [String: String]
    private let saveError: Error?

    private(set) var savedSnapshots: [[String: String]] = []

    init(initialMemory: [String: String], saveError: Error? = nil) {
        self.initialMemory = initialMemory
        self.saveError = saveError
    }

    func load() -> [String: String] {
        initialMemory
    }

    func save(_ memory: [String: String]) throws {
        if let saveError {
            throw saveError
        }
        savedSnapshots.append(memory)
    }
}

private struct CoordinatorHarness {
    let inputSourceManager: FakeInputSourceManager
    let memoryStore: RecordingMemoryStore
    let coordinator: SwitchCoordinator
    let diagnosticsRecorder: DiagnosticsRecorder

    var diagnostics: [String] {
        diagnosticsRecorder.entries
    }

    init(
        currentInputSource: InputSourceDescriptor?,
        availableInputSources: [InputSourceDescriptor]? = nil,
        settings: AppSettings,
        memories: [String: String],
        memorySaveError: Error? = nil
    ) {
        diagnosticsRecorder = DiagnosticsRecorder()
        let availableInputSources = availableInputSources ?? currentInputSource.map { [$0] } ?? []
        inputSourceManager = FakeInputSourceManager(current: currentInputSource, availableSources: availableInputSources)
        memoryStore = RecordingMemoryStore(initialMemory: memories, saveError: memorySaveError)
        coordinator = SwitchCoordinator(
            ruleEngine: RuleEngine(),
            inputSourceManager: inputSourceManager,
            settingsStore: StubSettingsStore(settings: settings),
            memoryStore: memoryStore,
            diagnostics: diagnosticsRecorder.log(_:)
        )
    }
}

private final class DiagnosticsRecorder {
    private(set) var entries: [String] = []

    func log(_ entry: String) {
        entries.append(entry)
    }
}

private enum StubError: Error, Equatable {
    case memorySaveFailed
}
