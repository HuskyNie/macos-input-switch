import Foundation

protocol SettingsProviding {
    func load() -> AppSettings
}

protocol MemoryStoring {
    func load() -> [String: String]
    func save(_ memory: [String: String]) throws
}

extension SettingsStore: SettingsProviding {}
extension MemoryStore: MemoryStoring {}

final class SwitchCoordinator {
    private let ruleEngine: RuleEngine
    private let inputSourceManager: InputSourceManaging
    private let memoryStore: MemoryStoring
    private let loopGuard: LoopGuard
    private let diagnostics: (String) -> Void

    private var activeApp: ApplicationIdentity?
    private var settings: AppSettings
    private var memories: [String: String]

    init(
        ruleEngine: RuleEngine,
        inputSourceManager: InputSourceManaging,
        settingsStore: SettingsProviding,
        memoryStore: MemoryStoring,
        diagnostics: @escaping (String) -> Void = { _ in },
        loopGuard: LoopGuard = LoopGuard()
    ) {
        self.ruleEngine = ruleEngine
        self.inputSourceManager = inputSourceManager
        self.memoryStore = memoryStore
        self.diagnostics = diagnostics
        self.loopGuard = loopGuard
        self.settings = settingsStore.load()
        self.memories = memoryStore.load()
    }

    func handleAppDidActivate(_ app: ApplicationIdentity) {
        activeApp = app

        let currentInputSource = inputSourceManager.currentInputSource()

        guard let fallbackDefaultID = settings.defaultInputSourceID ?? currentInputSource?.id else {
            return
        }

        let decision = ruleEngine.resolve(
            app: app,
            current: currentInputSource,
            rules: settings.rules,
            memories: memories,
            defaultInputSourceID: fallbackDefaultID
        )

        guard case .switchTo(let inputSourceID, let reason) = decision else {
            return
        }

        let availableInputSourceIDs = Set(inputSourceManager.availableInputSources().map(\.id))
        if availableInputSourceIDs.contains(inputSourceID) {
            switchInputSource(to: inputSourceID)
            return
        }

        diagnostics("目标输入法已不可用，应用：\(app.displayName)，原因：\(reason.diagnosticsLabel)，输入法 ID：\(inputSourceID)")

        guard let defaultInputSourceID = settings.defaultInputSourceID else {
            diagnostics("未配置默认输入法，保持当前输入法不变，应用：\(app.displayName)")
            return
        }

        guard availableInputSourceIDs.contains(defaultInputSourceID) else {
            diagnostics("默认输入法也不可用，保持当前输入法不变，应用：\(app.displayName)，默认输入法 ID：\(defaultInputSourceID)")
            return
        }

        diagnostics("已回退到默认输入法，应用：\(app.displayName)，输入法 ID：\(defaultInputSourceID)")

        guard currentInputSource?.id != defaultInputSourceID else {
            return
        }

        switchInputSource(to: defaultInputSourceID)
    }

    func handleInputSourceDidChange(to inputSource: InputSourceDescriptor) throws {
        guard !loopGuard.shouldIgnoreInputChange(to: inputSource.id) else {
            return
        }

        guard let activeApp else {
            return
        }

        let rule = settings.rules[activeApp.matchKey]
        guard rule != .ignored else {
            return
        }

        if case .locked? = rule {
            return
        }

        var updatedMemories = memories
        updatedMemories[activeApp.matchKey] = inputSource.id
        try memoryStore.save(updatedMemories)
        memories = updatedMemories
    }

    private func switchInputSource(to inputSourceID: String) {
        loopGuard.markProgrammaticSwitch(to: inputSourceID)
        inputSourceManager.switchToInputSource(id: inputSourceID)
    }
}

private extension RuleReason {
    var diagnosticsLabel: String {
        switch self {
        case .ignored:
            return "ignored"
        case .lockedRule:
            return "lockedRule"
        case .remembered:
            return "remembered"
        case .defaultInputSource:
            return "defaultInputSource"
        case .alreadyMatching:
            return "alreadyMatching"
        }
    }
}
