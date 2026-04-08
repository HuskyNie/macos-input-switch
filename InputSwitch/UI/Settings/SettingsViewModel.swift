import SwiftUI

struct SettingsRuleRow: Identifiable, Equatable {
    let key: String
    let rule: AppRule

    var id: String { key }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var defaultInputSourceName = "未设置"
    @Published var launchAtLoginEnabled = false
    @Published var launchAtLoginState: LaunchAtLoginState = .disabled
    @Published var rules: [SettingsRuleRow] = []
    @Published var availableInputSources: [InputSourceDescriptor] = []
    @Published var diagnostics: [String] = []

    var onLaunchAtLoginToggle: ((Bool) -> Void)?
    var launchAtLoginStatusMessage: String { launchAtLoginState.statusMessage }

    func reload(
        from settings: AppSettings,
        launchAtLoginState: LaunchAtLoginState,
        availableInputSources: [InputSourceDescriptor],
        diagnostics: [String]
    ) {
        if let defaultInputSourceID = settings.defaultInputSourceID {
            defaultInputSourceName = availableInputSources
                .first(where: { $0.id == defaultInputSourceID })?
                .displayName ?? defaultInputSourceID
        } else {
            defaultInputSourceName = "未设置"
        }
        self.launchAtLoginState = launchAtLoginState
        launchAtLoginEnabled = launchAtLoginState.isActive
        rules = settings.rules
            .sorted { $0.key < $1.key }
            .map { SettingsRuleRow(key: $0.key, rule: $0.value) }
        self.availableInputSources = availableInputSources
        self.diagnostics = diagnostics
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        launchAtLoginState = enabled ? .requiresApproval : .disabled
        onLaunchAtLoginToggle?(enabled)
    }
}
