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
    @Published var rules: [SettingsRuleRow] = []
    @Published var availableInputSources: [InputSourceDescriptor] = []
    @Published var diagnostics: [String] = []

    var onLaunchAtLoginToggle: ((Bool) -> Void)?

    func reload(
        from settings: AppSettings,
        availableInputSources: [InputSourceDescriptor],
        diagnostics: [String]
    ) {
        defaultInputSourceName = settings.defaultInputSourceID ?? "未设置"
        launchAtLoginEnabled = settings.launchAtLoginEnabled
        rules = settings.rules
            .sorted { $0.key < $1.key }
            .map { SettingsRuleRow(key: $0.key, rule: $0.value) }
        self.availableInputSources = availableInputSources
        self.diagnostics = diagnostics
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
        onLaunchAtLoginToggle?(enabled)
    }
}
