import SwiftUI

struct GeneralPane: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        SettingsPaneContainer(
            title: "通用设置",
            subtitle: "配置默认输入法、开机启动和调试日志。"
        ) {
            SettingsCard(title: "默认输入法", subtitle: "未命中规则或记忆时使用的输入法。") {
                Picker(
                    "默认输入法",
                    selection: Binding(
                        get: { viewModel.defaultInputSourceID ?? "" },
                        set: { viewModel.setDefaultInputSourceID($0.isEmpty ? nil : $0) }
                    )
                ) {
                    Text("未设置").tag("")
                    ForEach(viewModel.availableInputSources, id: \.id) { source in
                        Text(source.displayName).tag(source.id)
                    }
                }
                .labelsHidden()
                .frame(width: 260, alignment: .leading)
            }

            SettingsCard(title: "启动项", subtitle: "控制 InputSwitch 是否随系统登录自动启动。") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(
                        "开机启动",
                        isOn: Binding(
                            get: { viewModel.launchAtLoginEnabled },
                            set: { viewModel.setLaunchAtLogin($0) }
                        )
                    )
                    Text(viewModel.launchAtLoginStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
