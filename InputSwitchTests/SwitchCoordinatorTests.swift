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
}

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

    func currentInputSource() -> InputSourceDescriptor? {
        current
    }

    func switchToInputSource(id: String) {
        switchCalls.append(id)
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

    init(
        currentInputSource: InputSourceDescriptor?,
        settings: AppSettings,
        memories: [String: String],
        memorySaveError: Error? = nil
    ) {
        inputSourceManager = FakeInputSourceManager(current: currentInputSource)
        memoryStore = RecordingMemoryStore(initialMemory: memories, saveError: memorySaveError)
        coordinator = SwitchCoordinator(
            ruleEngine: RuleEngine(),
            inputSourceManager: inputSourceManager,
            settingsStore: StubSettingsStore(settings: settings),
            memoryStore: memoryStore
        )
    }
}

private enum StubError: Error, Equatable {
    case memorySaveFailed
}
