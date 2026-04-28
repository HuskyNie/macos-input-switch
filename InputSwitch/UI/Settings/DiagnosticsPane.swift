import SwiftUI

struct DiagnosticsPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsPaneContainer(
            title: "日志与诊断",
            subtitle: "查看最近的运行事件，便于定位输入法切换问题。"
        ) {
            SettingsCard(title: "Debug 日志", subtitle: "记录规则命中、输入法切换和回流事件；排查问题时开启即可。") {
                Toggle(
                    viewModel.debugLoggingEnabled ? "已启用" : "未启用",
                    isOn: Binding(
                        get: { viewModel.debugLoggingEnabled },
                        set: { viewModel.setDebugLoggingEnabled($0) }
                    )
                )
                .toggleStyle(.switch)
            }

            SettingsCard(title: "日志说明", subtitle: "这些记录只保存在本机运行内存中，用于判断每次切换为什么发生。") {
                VStack(alignment: .leading, spacing: 8) {
                    DiagnosticHint(text: "应用切换开始：检测到前台 App 变化，开始计算规则。")
                    DiagnosticHint(text: "命中规则/记忆：找到了应切换到的输入法。")
                    DiagnosticHint(text: "实际执行切换：已请求 macOS 切到目标输入法。")
                    DiagnosticHint(text: "程序回流输入法事件被忽略：这是本 App 自己触发切换后的系统回调，跳过是正常的。")
                }
            }

            if viewModel.diagnostics.isEmpty {
                SettingsEmptyState(
                    title: "暂无诊断日志",
                    message: "应用运行、规则变更或输入法切换后会在这里显示记录。",
                    systemImage: "doc.text.magnifyingglass"
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.diagnostics, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(line.hasPrefix("[DEBUG]") ? .secondary : .primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }
                .padding(14)
                .settingsCardStyle()
            }
        }
    }
}

private struct DiagnosticHint: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
