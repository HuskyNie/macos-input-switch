import SwiftUI

struct RulesPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                rulesSection
                editorSection
            }
            .padding(24)
            .frame(maxWidth: 920, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("规则列表")
                .font(.title2.weight(.semibold))
            Text("为不同 App 固定输入法，或将某些 App 标记为不管理。")
                .foregroundStyle(.secondary)
        }
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("已配置规则")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.rules.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.rules.isEmpty {
                emptyRulesView
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.rules) { entry in
                        RuleRowView(
                            row: entry,
                            description: ruleDescription(for: entry),
                            onEdit: { viewModel.beginEditing(entry) },
                            onDelete: { viewModel.deleteRule(entry) }
                        )
                    }
                }
            }
        }
    }

    private var emptyRulesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("暂无规则")
                .font(.headline)
            Text("切换到目标 App 后，可在下方一键为当前前台应用创建规则。")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.ruleDraftKey.isEmpty ? "新建规则" : "编辑规则")
                        .font(.headline)
                    Text("当前前台应用：\(viewModel.currentActiveAppDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("为当前应用新建") {
                    viewModel.beginRuleDraftForCurrentApp()
                }
                .disabled(!viewModel.canCreateRuleForCurrentApp)
                Button("清空") {
                    viewModel.clearRuleDraft()
                }
            }

            Divider()

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("规则目标")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.ruleDraftDisplayName)
                        if !viewModel.ruleDraftKey.isEmpty, viewModel.ruleDraftDisplayName != viewModel.ruleDraftKey {
                            Text(viewModel.ruleDraftKey)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                GridRow {
                    Text("规则类型")
                        .foregroundStyle(.secondary)
                    Picker("规则类型", selection: $viewModel.ruleDraftKind) {
                        ForEach(SettingsRuleDraftKind.allCases) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180, alignment: .leading)
                }

                if viewModel.ruleDraftKind == .locked {
                    GridRow {
                        Text("锁定输入法")
                            .foregroundStyle(.secondary)
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
                        .labelsHidden()
                        .frame(width: 280, alignment: .leading)
                    }
                }
            }

            HStack {
                Spacer()
                Button("保存规则") {
                    viewModel.saveRuleDraft()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.canSaveRuleDraft)
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
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

private struct RuleRowView: View {
    let row: SettingsRuleRow
    let description: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(row.displayName)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.tertiary, in: Capsule())
                }
                Text(row.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("编辑", action: onEdit)
            Button("删除", role: .destructive, action: onDelete)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator.opacity(0.5), lineWidth: 1)
        }
    }

    private var iconName: String {
        switch row.rule {
        case .ignored:
            return "nosign"
        case .locked:
            return "lock.fill"
        case .remembered:
            return "clock.arrow.circlepath"
        }
    }
}
