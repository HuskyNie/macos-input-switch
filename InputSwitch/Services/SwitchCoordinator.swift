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

    private var activeApp: ApplicationIdentity?
    private var settings: AppSettings
    private var memories: [String: String]

    init(
        ruleEngine: RuleEngine,
        inputSourceManager: InputSourceManaging,
        settingsStore: SettingsProviding,
        memoryStore: MemoryStoring,
        loopGuard: LoopGuard = LoopGuard()
    ) {
        self.ruleEngine = ruleEngine
        self.inputSourceManager = inputSourceManager
        self.memoryStore = memoryStore
        self.loopGuard = loopGuard
        self.settings = settingsStore.load()
        self.memories = memoryStore.load()
    }

    func handleAppDidActivate(_ app: ApplicationIdentity) {
        activeApp = app

        guard let fallbackDefaultID = settings.defaultInputSourceID ?? inputSourceManager.currentInputSource()?.id else {
            return
        }

        let decision = ruleEngine.resolve(
            app: app,
            current: inputSourceManager.currentInputSource(),
            rules: settings.rules,
            memories: memories,
            defaultInputSourceID: fallbackDefaultID
        )

        guard case .switchTo(let inputSourceID, _) = decision else {
            return
        }

        loopGuard.markProgrammaticSwitch(to: inputSourceID)
        inputSourceManager.switchToInputSource(id: inputSourceID)
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

        memories[activeApp.matchKey] = inputSource.id
        try memoryStore.save(memories)
    }
}
