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
    private let debugDiagnostics: (String) -> Void

    private var activeApp: ApplicationIdentity?
    private var settings: AppSettings
    private var memories: [String: String]

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
        debugDiagnostics("[DEBUG] 应用切换开始：\(app.displayName)")

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
            if case .keepCurrent(let reason) = decision {
                logKeepCurrentDebug(reason: reason, app: app, currentInputSource: currentInputSource)
            }
            return
        }
        logSwitchDecisionDebug(reason: reason, app: app, inputSourceID: inputSourceID)

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
            debugDiagnostics("[DEBUG] 程序回流输入法事件被忽略：\(inputSource.id)")
            return
        }

        guard let activeApp else {
            return
        }

        let rule = settings.rules[activeApp.matchKey]
        guard rule != .ignored else {
            debugDiagnostics("[DEBUG] 因锁定规则或不管理而跳过记忆更新：\(activeApp.displayName)")
            return
        }

        if case .locked? = rule {
            debugDiagnostics("[DEBUG] 因锁定规则或不管理而跳过记忆更新：\(activeApp.displayName)")
            return
        }

        var updatedMemories = memories
        updatedMemories[activeApp.matchKey] = inputSource.id
        try memoryStore.save(updatedMemories)
        memories = updatedMemories
        debugDiagnostics("[DEBUG] 用户主动切换后写入记忆：\(activeApp.displayName) -> \(inputSource.id)")
    }

    private func switchInputSource(to inputSourceID: String) {
        debugDiagnostics("[DEBUG] 实际执行切换：\(inputSourceID)")
        loopGuard.markProgrammaticSwitch(to: inputSourceID)
        inputSourceManager.switchToInputSource(id: inputSourceID)
    }

    private func logKeepCurrentDebug(reason: RuleReason, app: ApplicationIdentity, currentInputSource: InputSourceDescriptor?) {
        switch reason {
        case .ignored:
            debugDiagnostics("[DEBUG] 命中不管理：\(app.displayName)")
        case .alreadyMatching:
            let key = app.matchKey
            if case .locked(let lockedID)? = settings.rules[key], currentInputSource?.id == lockedID {
                debugDiagnostics("[DEBUG] 命中规则，当前已匹配无需切换：\(app.displayName)")
                return
            }
            if let rememberedID = memories[key], currentInputSource?.id == rememberedID {
                debugDiagnostics("[DEBUG] 命中记忆，当前已匹配无需切换：\(app.displayName)")
                return
            }
            if
                let defaultInputSourceID = settings.defaultInputSourceID,
                currentInputSource?.id == defaultInputSourceID
            {
                debugDiagnostics("[DEBUG] 使用默认输入法，当前已匹配无需切换：\(app.displayName)")
                return
            }
            debugDiagnostics("[DEBUG] 当前已匹配无需切换：\(app.displayName)")
        case .lockedRule, .remembered, .defaultInputSource:
            break
        }
    }

    private func logSwitchDecisionDebug(reason: RuleReason, app: ApplicationIdentity, inputSourceID: String) {
        switch reason {
        case .lockedRule:
            debugDiagnostics("[DEBUG] 命中规则（锁定）：\(app.displayName) -> \(inputSourceID)")
        case .remembered:
            debugDiagnostics("[DEBUG] 命中记忆：\(app.displayName) -> \(inputSourceID)")
        case .defaultInputSource:
            debugDiagnostics("[DEBUG] 使用默认输入法：\(app.displayName) -> \(inputSourceID)")
        case .ignored, .alreadyMatching:
            break
        }
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
