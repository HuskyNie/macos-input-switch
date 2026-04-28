import SwiftUI

struct SettingsRuleRow: Identifiable, Equatable {
    let key: String
    let rule: AppRule

    var id: String { key }
    var detailText: String { key }
    var displayName: String {
        let value: String
        if let separatorIndex = key.firstIndex(of: ":") {
            value = String(key[key.index(after: separatorIndex)...])
        } else {
            value = key
        }

        let lastComponent = value.split(separator: ".").last.map(String.init) ?? value
        switch lastComponent.lowercased() {
        case "iterm2":
            return "iTerm2"
        default:
            return lastComponent.isEmpty ? key : lastComponent
        }
    }
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
    @Published var ruleDraftDisplayName = "未选择应用"
    @Published var ruleDraftKind: SettingsRuleDraftKind = .ignored
    @Published var ruleDraftInputSourceID: String?
    @Published var debugLoggingEnabled = false
    @Published var currentActiveAppDisplayName = "未检测到"

    private var currentActiveAppKey: String?

    var onLaunchAtLoginToggle: ((Bool) -> Void)?
    var onDefaultInputSourceChange: ((String?) -> Void)?
    var onDebugLoggingToggle: ((Bool) -> Void)?
    var onUpsertRule: ((String, AppRule) -> Void)?
    var onDeleteRule: ((String) -> Void)?
    var launchAtLoginStatusMessage: String { launchAtLoginState.statusMessage }
    var canCreateRuleForCurrentApp: Bool { currentActiveAppKey != nil }
    var canSaveRuleDraft: Bool {
        !ruleDraftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (ruleDraftKind == .ignored || ruleDraftInputSourceID != nil)
    }

    func reload(
        from settings: AppSettings,
        launchAtLoginState: LaunchAtLoginState,
        availableInputSources: [InputSourceDescriptor],
        diagnostics: [String],
        currentActiveApp: ApplicationIdentity?
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
        currentActiveAppKey = currentActiveApp?.matchKey
        currentActiveAppDisplayName = currentActiveApp?.displayName ?? "未检测到"
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        launchAtLoginState = enabled ? .requiresApproval : .disabled
        onLaunchAtLoginToggle?(enabled)
    }

    func setDefaultInputSourceID(_ inputSourceID: String?) {
        defaultInputSourceID = inputSourceID
        defaultInputSourceName = displayName(for: inputSourceID)
        onDefaultInputSourceChange?(inputSourceID)
    }

    func beginEditing(_ row: SettingsRuleRow) {
        ruleDraftKey = row.key
        ruleDraftDisplayName = row.key
        switch row.rule {
        case .ignored:
            ruleDraftKind = .ignored
            ruleDraftInputSourceID = nil
        case .locked(let inputSourceID):
            ruleDraftKind = .locked
            ruleDraftInputSourceID = inputSourceID
        case .remembered:
            ruleDraftKind = .ignored
            ruleDraftInputSourceID = nil
        }
    }

    func beginRuleDraftForCurrentApp() {
        guard let currentActiveAppKey else {
            return
        }

        ruleDraftKey = currentActiveAppKey
        ruleDraftDisplayName = currentActiveAppDisplayName
    }

    func clearRuleDraft() {
        ruleDraftKey = ""
        ruleDraftDisplayName = "未选择应用"
        ruleDraftKind = .ignored
        ruleDraftInputSourceID = nil
    }

    func setDebugLoggingEnabled(_ enabled: Bool) {
        debugLoggingEnabled = enabled
        onDebugLoggingToggle?(enabled)
    }

    func saveRuleDraft() {
        let trimmedKey = ruleDraftKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return
        }

        let rule: AppRule
        switch ruleDraftKind {
        case .ignored:
            rule = .ignored
        case .locked:
            guard let ruleDraftInputSourceID else {
                return
            }
            rule = .locked(inputSourceID: ruleDraftInputSourceID)
        }

        onUpsertRule?(trimmedKey, rule)
        clearRuleDraft()
    }

    func deleteRule(_ row: SettingsRuleRow) {
        onDeleteRule?(row.key)
        if ruleDraftKey == row.key {
            clearRuleDraft()
        }
    }

    func displayName(for inputSourceID: String?) -> String {
        guard let inputSourceID else {
            return "未设置"
        }
        return availableInputSources.first(where: { $0.id == inputSourceID })?.displayName ?? inputSourceID
    }
}
