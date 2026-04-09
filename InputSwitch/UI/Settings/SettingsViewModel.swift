import SwiftUI

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
    @Published var debugLoggingEnabled = false

    var onLaunchAtLoginToggle: ((Bool) -> Void)?
    var onDefaultInputSourceChange: ((String?) -> Void)?
    var onDebugLoggingToggle: ((Bool) -> Void)?
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
        debugLoggingEnabled = settings.debugLoggingEnabled
        rules = settings.rules
            .sorted { $0.key < $1.key }
            .map { SettingsRuleRow(key: $0.key, rule: $0.value) }
        self.diagnostics = diagnostics
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

    func clearRuleDraft() {
        ruleDraftKey = ""
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
