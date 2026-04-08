import SwiftUI

struct RulesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            List(viewModel.rules) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.key)
                        Text(ruleDescription(for: entry))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("编辑") {
                        viewModel.beginEditing(entry)
                    }
                    Button("删除", role: .destructive) {
                        viewModel.deleteRule(entry)
                    }
                }
            }

            Form {
                TextField("应用键，例如 bundle:com.googlecode.iterm2", text: $viewModel.ruleDraftKey)
                Picker("规则类型", selection: $viewModel.ruleDraftKind) {
                    ForEach(SettingsRuleDraftKind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }

                if viewModel.ruleDraftKind == .locked {
                    Picker(
                        "锁定输入法",
                        selection: Binding(
                            get: { viewModel.ruleDraftInputSourceID ?? "" },
                            set: { viewModel.ruleDraftInputSourceID = $0.isEmpty ? nil : $0 }
                        )
                    ) {
                        Text("请选择").tag("")
                        ForEach(viewModel.availableInputSources, id: \.id) { source in
                            Text(source.displayName).tag(source.id)
                        }
                    }
                }

                HStack {
                    Button("保存规则") {
                        viewModel.saveRuleDraft()
                    }
                    .disabled(!viewModel.canSaveRuleDraft)

                    Button("清空") {
                        viewModel.clearRuleDraft()
                    }
                }
            }
        }
    }

    private func ruleDescription(for row: SettingsRuleRow) -> String {
        switch row.rule {
        case .ignored:
            return "不管理"
        case .locked(let inputSourceID):
            return "锁定到 \(viewModel.displayName(for: inputSourceID))"
        case .remembered:
            return "自动记忆"
        }
    }
}
